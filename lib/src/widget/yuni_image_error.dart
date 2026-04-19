import 'package:flutter/material.dart';
import 'package:yuni_widget/yuni_widget.dart';

/// 图片加载失败时显示的默认错误图。
///
/// 使用 [YuniWidgetConfig] 颜色令牌，不硬编码任何样式。
class YuniImageError extends StatelessWidget {
  const YuniImageError({super.key, this.width, this.height});

  /// 错误图宽度。
  final double? width;

  /// 错误图高度。
  final double? height;

  @override
  Widget build(BuildContext context) {
    final config = YuniWidgetConfig.instance;
    return Container(
      width: width,
      height: height,
      color: config.colors.surfaceVariant,
      child: Icon(
        Icons.broken_image_outlined,
        color: config.colors.onSurfaceVariant,
        size: 24,
      ),
    );
  }
}
