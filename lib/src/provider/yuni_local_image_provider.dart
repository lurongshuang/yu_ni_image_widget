import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 从本地文件路径加载图片的 [ImageProvider]。
///
/// 相等性和哈希值仅基于 [path]，因此相同的文件路径始终映射到同一个缓存槽。
///
/// 在 [YuniImageCache] 中被归类为 `local` 分类。
class YuniLocalImageProvider extends ImageProvider<YuniLocalImageProvider> {
  /// 创建本地图片 Provider。
  ///
  /// [path] 必须是指向已存在图片文件的有效路径（绝对路径或相对路径）。
  /// 若文件不存在或字节为空，加载时会抛出 [StateError]。
  const YuniLocalImageProvider({required this.path});

  /// 图片的文件系统路径。
  final String path;

  @override
  Future<YuniLocalImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<YuniLocalImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    YuniLocalImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: path,
      informationCollector: () => [
        DiagnosticsProperty<ImageProvider>('图片 Provider', this),
        DiagnosticsProperty<YuniLocalImageProvider>('图片 key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    YuniLocalImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    final file = File(path);

    if (!file.existsSync()) {
      throw StateError(
        'YuniLocalImageProvider：路径 "$path" 对应的文件不存在。',
      );
    }

    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      throw StateError(
        'YuniLocalImageProvider：路径 "$path" 对应的文件字节为空。',
      );
    }

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YuniLocalImageProvider &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'YuniLocalImageProvider')}("$path")';
}
