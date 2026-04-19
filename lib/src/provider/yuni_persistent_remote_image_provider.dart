import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../scheduler/yuni_image_load_scheduler.dart';

/// 通过注入的 [BaseCacheManager] 从远程 URL 加载图片的持久化 [ImageProvider]。
///
/// 加载逻辑与 [YuniRemoteImageProvider] 完全相同，但类型不同，
/// 以便 [YuniImageCache] 将其归类为 `persistent` 分类并应用永久保活策略。
///
/// 适用于不能被 LRU 驱逐的重要图片，例如相册封面、用户头像。
/// 持久化图片始终使用高优先级加载。
class YuniPersistentRemoteImageProvider
    extends ImageProvider<YuniPersistentRemoteImageProvider> {
  /// 创建持久化远程图片 Provider。
  ///
  /// [url] 必填，不能为空。
  /// [cacheManager] 必填，负责磁盘缓存和网络请求。
  /// [headers] 会透传给 [BaseCacheManager.getSingleFile]。
  const YuniPersistentRemoteImageProvider({
    required this.url,
    required this.cacheManager,
    this.headers = const {},
  });

  /// 图片的远程 URL。
  final String url;

  /// 透传给缓存管理器的 HTTP 请求头。
  final Map<String, String> headers;

  /// 负责获取和存储图片文件的缓存管理器。
  final BaseCacheManager cacheManager;

  @override
  Future<YuniPersistentRemoteImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<YuniPersistentRemoteImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    YuniPersistentRemoteImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: url,
      informationCollector: () => [
        DiagnosticsProperty<ImageProvider>('图片 Provider', this),
        DiagnosticsProperty<YuniPersistentRemoteImageProvider>(
          '图片 key',
          key,
        ),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    YuniPersistentRemoteImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    // 持久化图片始终使用高优先级，且不会被取消
    final String filePath;
    try {
      filePath = await YuniImageLoadScheduler.instance.submit(
        url: url,
        headers: headers,
        cacheManager: cacheManager,
        priority: YuniImageLoadPriority.high,
      );
    } on YuniImageCancelledError {
      throw StateError('YuniPersistentRemoteImageProvider：url "$url" 的加载任务已取消。');
    }

    final bytes = await File(filePath).readAsBytes();

    if (bytes.isEmpty) {
      throw StateError(
        'YuniPersistentRemoteImageProvider：url "$url" 返回了空字节数据。',
      );
    }

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YuniPersistentRemoteImageProvider &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'YuniPersistentRemoteImageProvider')}("$url")';
}
