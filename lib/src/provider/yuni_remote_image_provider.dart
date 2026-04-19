import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../scheduler/yuni_image_load_scheduler.dart';

/// 通过注入的 [BaseCacheManager] 从远程 URL 加载图片的 [ImageProvider]。
///
/// 加载请求会经过 [YuniImageLoadScheduler] 调度，高优先级（视口内）任务
/// 优先占用并发槽位，低优先级（视口外）任务在后台等待。
///
/// 相等性和哈希值仅基于 [url]，因此相同的 URL 始终映射到同一个缓存槽。
///
/// 在 [YuniImageCache] 中被归类为 `thumbnail` 分类。
class YuniRemoteImageProvider extends ImageProvider<YuniRemoteImageProvider> {
  /// 创建远程图片 Provider。
  ///
  /// [url] 必填，不能为空。
  /// [cacheManager] 必填，负责磁盘缓存和网络请求。
  /// [headers] 会透传给 [BaseCacheManager.getSingleFile]。
  /// [priority] 控制加载优先级，默认高优先级（视口内）。
  const YuniRemoteImageProvider({
    required this.url,
    required this.cacheManager,
    this.headers = const {},
    this.priority = YuniImageLoadPriority.high,
  });

  /// 图片的远程 URL。
  final String url;

  /// 透传给缓存管理器的 HTTP 请求头。
  final Map<String, String> headers;

  /// 负责获取和存储图片文件的缓存管理器。
  final BaseCacheManager cacheManager;

  /// 加载优先级。
  final YuniImageLoadPriority priority;

  @override
  Future<YuniRemoteImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<YuniRemoteImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    YuniRemoteImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: url,
      informationCollector: () => [
        DiagnosticsProperty<ImageProvider>('图片 Provider', this),
        DiagnosticsProperty<YuniRemoteImageProvider>('图片 key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    YuniRemoteImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    // 通过调度器获取文件路径，支持优先级控制和取消
    final String filePath;
    try {
      filePath = await YuniImageLoadScheduler.instance.submit(
        url: url,
        headers: headers,
        cacheManager: cacheManager,
        priority: priority,
      );
    } on YuniImageCancelledError {
      // 任务被取消（图片已滑出视口），静默终止，不触发 errorBuilder
      throw StateError('YuniRemoteImageProvider：url "$url" 的加载任务已取消。');
    }

    final bytes = await File(filePath).readAsBytes();

    if (bytes.isEmpty) {
      throw StateError(
        'YuniRemoteImageProvider：url "$url" 返回了空字节数据。',
      );
    }

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YuniRemoteImageProvider &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'YuniRemoteImageProvider')}("$url")';
}
