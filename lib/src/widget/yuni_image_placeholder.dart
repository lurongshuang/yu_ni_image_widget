import 'package:flutter/widgets.dart';
import 'package:yuni_widget/yuni_widget.dart';

/// 图片加载中时显示的默认占位图。
///
/// 使用 [YuniWidgetConfig] 颜色令牌，不硬编码任何颜色值。
class YuniImagePlaceholder extends StatelessWidget {
  const YuniImagePlaceholder({super.key, this.width, this.height});

  /// 占位图宽度。
  final double? width;

  /// 占位图高度。
  final double? height;

  @override
  Widget build(BuildContext context) {
    final color = YuniWidgetConfig.instance.colors.surfaceVariant;
    return Container(
      width: width,
      height: height,
      color: color,
    );
  }
}
