import 'dart:collection';

import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../provider/yuni_local_image_provider.dart';
import '../provider/yuni_persistent_remote_image_provider.dart';
import '../provider/yuni_remote_image_provider.dart';

// ---------------------------------------------------------------------------
// 图片分类枚举
// ---------------------------------------------------------------------------

enum _ImageCategory { icon, persistent, thumbnail, local, full }

// ---------------------------------------------------------------------------
// 各分类上限配置（null 表示无限制）
// ---------------------------------------------------------------------------

class _CategoryLimit {
  const _CategoryLimit({this.maxItems, this.maxBytes});
  final int? maxItems;
  final int? maxBytes;
}

const _categoryLimits = <_ImageCategory, _CategoryLimit>{
  _ImageCategory.icon: _CategoryLimit(maxItems: 100, maxBytes: 50 * 1024 * 1024),
  _ImageCategory.persistent: _CategoryLimit(), // 无限制
  _ImageCategory.thumbnail: _CategoryLimit(maxItems: 1000, maxBytes: 500 * 1024 * 1024),
  _ImageCategory.local: _CategoryLimit(maxItems: 50, maxBytes: 80 * 1024 * 1024),
  _ImageCategory.full: _CategoryLimit(maxItems: 5), // 字节无限制
};

// ---------------------------------------------------------------------------
// YuniImageCache
// ---------------------------------------------------------------------------

/// 自定义 [ImageCache]，将图片分为五个分类（icon / persistent / thumbnail / local / full）
/// 并对每个分类独立应用 FIFO 淘汰策略。
///
/// - **persistent** 和 **icon** 分类的图片通过持有永久 [ImageStreamListener] 保活，
///   防止被全局 LRU 驱逐。
/// - [clear] 只清除 thumbnail / local / full 分类，保留 persistent 和 icon。
/// - [evictByUrl] / [evictByUrls] 允许调用方通过 URL 直接清除内存缓存，
///   无需持有 Provider 引用。
class YuniImageCache extends ImageCache {
  YuniImageCache() {
    // 全局上限 = 各分类数量上限之和 × 1.3（为 thumbhash 等未追踪分类预留缓冲）
    // 数量：(100 + 1000 + 50 + 5) × 1.3 ≈ 1501
    // 字节：(50 + 500 + 80) MB × 1.3 ≈ 819 MB
    maximumSize = ((100 + 1000 + 50 + 5) * 1.3).ceil();
    maximumSizeBytes = ((50 + 500 + 80) * 1024 * 1024 * 1.3).ceil();
  }

  // -------------------------------------------------------------------------
  // 各分类 FIFO 队列（按插入顺序追踪）
  // -------------------------------------------------------------------------

  final Map<_ImageCategory, Queue<Object>> _categoryKeys = {
    for (final cat in _ImageCategory.values) cat: Queue<Object>(),
  };

  // -------------------------------------------------------------------------
  // persistent / icon 分类的永久保活 listener
  // -------------------------------------------------------------------------

  /// persistent 分类图片持有的永久 listener。
  final Map<Object, ImageStreamListener> _persistentListeners = {};

  /// icon 分类图片持有的永久 listener。
  final Map<Object, ImageStreamListener> _iconListeners = {};

  // -------------------------------------------------------------------------
  // 分类判断
  // -------------------------------------------------------------------------

  _ImageCategory _categoryOf(Object key) => switch (key) {
    AssetBundleImageKey() => _ImageCategory.icon,
    YuniPersistentRemoteImageProvider() => _ImageCategory.persistent,
    YuniRemoteImageProvider() => _ImageCategory.thumbnail,
    YuniLocalImageProvider() => _ImageCategory.local,
    _ => _ImageCategory.thumbnail,
  };

  // -------------------------------------------------------------------------
  // FIFO 淘汰辅助方法
  // -------------------------------------------------------------------------

  void _evictCategoryIfNeeded(_ImageCategory category) {
    final limit = _categoryLimits[category];
    if (limit == null || limit.maxItems == null) return;
    final queue = _categoryKeys[category]!;
    while (queue.length >= limit.maxItems!) {
      final oldest = queue.removeFirst();
      // 驱逐前先释放永久 listener
      final completer = _completers.remove(oldest);
      final persistentListener = _persistentListeners.remove(oldest);
      final iconListener = _iconListeners.remove(oldest);
      if (completer != null) {
        if (persistentListener != null) completer.removeListener(persistentListener);
        if (iconListener != null) completer.removeListener(iconListener);
      }
      super.evict(oldest);
    }
  }

  void _addToCategoryTracking(_ImageCategory category, Object key) {
    final queue = _categoryKeys[category]!;
    // 避免重复插入（例如同一个 key 多次调用 putIfAbsent）
    if (!queue.contains(key)) {
      queue.addLast(key);
    }
  }

  void _removeFromCategoryTracking(Object key) {
    for (final queue in _categoryKeys.values) {
      queue.remove(key);
    }
  }

  // -------------------------------------------------------------------------
  // 重写 putIfAbsent
  // -------------------------------------------------------------------------

  // 存储 completer 引用，以便驱逐时能移除 listener
  final Map<Object, ImageStreamCompleter> _completers = {};

  @override
  ImageStreamCompleter? putIfAbsent(
    Object key,
    ImageStreamCompleter Function() loader, {
    ImageErrorListener? onError,
  }) {
    final completer = super.putIfAbsent(key, loader, onError: onError);

    if (completer == null) return null;

    final category = _categoryOf(key);

    // 按插入顺序追踪，用于 FIFO 淘汰
    _evictCategoryIfNeeded(category);
    _addToCategoryTracking(category, key);

    // persistent 和 icon 分类：添加永久空操作 listener，
    // 使图片始终保留在 _liveImages 中，防止被 LRU 驱逐
    if (category == _ImageCategory.persistent &&
        !_persistentListeners.containsKey(key)) {
      final listener = ImageStreamListener(
        (ImageInfo _, bool __) {}, // 空操作，仅用于持有引用
      );
      completer.addListener(listener);
      _persistentListeners[key] = listener;
      _completers[key] = completer;
    } else if (category == _ImageCategory.icon &&
        !_iconListeners.containsKey(key)) {
      final listener = ImageStreamListener(
        (ImageInfo _, bool __) {}, // 空操作，仅用于持有引用
      );
      completer.addListener(listener);
      _iconListeners[key] = listener;
      _completers[key] = completer;
    }

    return completer;
  }

  // -------------------------------------------------------------------------
  // 重写 evict
  // -------------------------------------------------------------------------

  @override
  bool evict(Object key, {bool includeLive = true}) {
    // 先移除永久 listener，使 completer 可以被释放
    final completer = _completers.remove(key);
    final persistentListener = _persistentListeners.remove(key);
    final iconListener = _iconListeners.remove(key);

    if (completer != null) {
      if (persistentListener != null) {
        completer.removeListener(persistentListener);
      }
      if (iconListener != null) {
        completer.removeListener(iconListener);
      }
    }

    _removeFromCategoryTracking(key);
    // includeLive: true 确保有活跃 listener 的图片也能被强制清除
    return super.evict(key, includeLive: includeLive);
  }

  // -------------------------------------------------------------------------
  // 重写 clear
  // -------------------------------------------------------------------------

  /// 只清除 thumbnail、local、full 分类的缓存，保留 persistent 和 icon 分类。
  @override
  void clear() {
    final keysToEvict = [
      ..._categoryKeys[_ImageCategory.thumbnail]!,
      ..._categoryKeys[_ImageCategory.local]!,
      ..._categoryKeys[_ImageCategory.full]!,
    ];
    for (final key in keysToEvict) {
      evict(key);
    }
  }

  // -------------------------------------------------------------------------
  // 公开方法：evictByUrl / evictByUrls
  // -------------------------------------------------------------------------

  /// 清除 [url] 对应的内存缓存条目。
  ///
  /// 始终清除 thumbnail 分类（[YuniRemoteImageProvider]）的条目。
  /// 当 [includePersistent] 为 `true`（默认值）时，同时清除 persistent 分类
  /// （[YuniPersistentRemoteImageProvider]）的条目。
  ///
  /// 返回 `true` 表示至少清除了一个条目。
  bool evictByUrl(
    String url, {
    Map<String, String>? headers,
    bool includePersistent = true,
    required BaseCacheManager cacheManager,
  }) {
    bool evicted = false;
    // includeLive: true 确保即使图片当前有活跃 listener 也强制清除
    evicted |= evict(
      YuniRemoteImageProvider(
        url: url,
        cacheManager: cacheManager,
        headers: headers ?? {},
      ),
      includeLive: true,
    );
    if (includePersistent) {
      evicted |= evict(
        YuniPersistentRemoteImageProvider(
          url: url,
          cacheManager: cacheManager,
          headers: headers ?? {},
        ),
        includeLive: true,
      );
    }
    return evicted;
  }

  /// 批量清除 [urls] 中每个 URL 对应的内存缓存条目。
  ///
  /// 返回成功清除了至少一个条目的 URL 数量。
  int evictByUrls(
    List<String> urls, {
    Map<String, String>? headers,
    bool includePersistent = true,
    required BaseCacheManager cacheManager,
  }) {
    return urls
        .where(
          (url) => evictByUrl(
            url,
            headers: headers,
            includePersistent: includePersistent,
            cacheManager: cacheManager,
          ),
        )
        .length;
  }
}
