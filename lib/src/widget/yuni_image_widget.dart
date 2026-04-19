import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:octo_image/octo_image.dart';

import '../cache/yuni_widgets_binding.dart';
import '../provider/yuni_local_image_provider.dart';
import '../provider/yuni_persistent_remote_image_provider.dart';
import '../provider/yuni_remote_image_provider.dart';
import '../scheduler/yuni_image_load_scheduler.dart';
import 'yuni_image_error.dart';
import 'yuni_image_placeholder.dart';

/// 支持远程、持久化远程和本地文件三种来源的图片展示组件。
///
/// 通过工厂构造函数创建实例：
/// - [YuniImageWidget.remote] — 通过注入的 [BaseCacheManager] 从 URL 加载图片。
/// - [YuniImageWidget.persistentRemote] — 与 remote 相同，但使用持久化缓存策略
///   （适用于相册封面、用户头像等重要图片）。
/// - [YuniImageWidget.local] — 从本地文件路径加载图片。
///
/// ## 示例
/// ```dart
/// YuniImageWidget.remote(
///   url: 'https://example.com/photo.jpg',
///   cacheManager: myCacheManager,
///   width: 200,
///   height: 200,
///   cornerRadius: 8,
/// )
/// ```
class YuniImageWidget extends StatefulWidget {
  const YuniImageWidget._({
    super.key,
    required this.imageProvider,
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cornerRadius,
    this.isCircle = false,
    this.backgroundColor,
    this.borderWidth,
    this.borderColor,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.fadeOutDuration = const Duration(milliseconds: 200),
  });

  /// 由工厂构造函数解析出的底层 [ImageProvider]。
  final ImageProvider imageProvider;

  /// 远程 Provider 使用的 URL；本地 Provider 为 `null`。
  /// 用于检测空 URL 并提前返回错误图。
  final String? url;

  /// 图片组件的固定宽度（可选）。
  final double? width;

  /// 图片组件的固定高度（可选）。
  final double? height;

  /// 图片在分配空间内的填充方式。
  final BoxFit fit;

  /// 图片圆角半径。[isCircle] 为 `true` 时忽略此参数。
  final double? cornerRadius;

  /// 为 `true` 时使用 [ClipOval] 将图片裁切为圆形。
  final bool isCircle;

  /// 图片背景色（例如加载中时显示）。
  final Color? backgroundColor;

  /// 边框宽度。
  final double? borderWidth;

  /// 边框颜色。
  final Color? borderColor;

  /// 自定义占位图，加载中时显示。默认使用 [YuniImagePlaceholder]。
  final Widget? placeholder;

  /// 自定义错误图，加载失败时显示。默认使用 [YuniImageError]。
  final Widget Function(BuildContext, Object, StackTrace?)? errorWidget;

  /// 淡入动画时长，默认 200ms。
  final Duration fadeInDuration;

  /// 淡出动画时长，默认 200ms。
  final Duration fadeOutDuration;

  // ---------------------------------------------------------------------------
  // 工厂构造函数
  // ---------------------------------------------------------------------------

  /// 创建通过 [cacheManager] 从 [url] 加载图片的 [YuniImageWidget]。
  ///
  /// [url] 和 [cacheManager] 为必填参数。当 [url] 为空字符串时，
  /// 组件直接显示错误状态，不发起任何网络请求。
  factory YuniImageWidget.remote({
    Key? key,
    required String url,
    required BaseCacheManager cacheManager,
    Map<String, String> headers = const {},
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double? cornerRadius,
    bool isCircle = false,
    Color? backgroundColor,
    double? borderWidth,
    Color? borderColor,
    Widget? placeholder,
    Widget Function(BuildContext, Object, StackTrace?)? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 200),
    Duration fadeOutDuration = const Duration(milliseconds: 200),
  }) {
    return YuniImageWidget._(
      key: key,
      imageProvider: YuniRemoteImageProvider(
        url: url,
        cacheManager: cacheManager,
        headers: headers,
      ),
      url: url,
      width: width,
      height: height,
      fit: fit,
      cornerRadius: cornerRadius,
      isCircle: isCircle,
      backgroundColor: backgroundColor,
      borderWidth: borderWidth,
      borderColor: borderColor,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
    );
  }

  /// 创建使用持久化缓存策略、通过 [cacheManager] 从 [url] 加载图片的 [YuniImageWidget]。
  ///
  /// 持久化图片（如相册封面、用户头像）会常驻内存，不被全局 LRU 驱逐。
  /// 适用于返回页面时不能出现闪烁的重要图片。
  factory YuniImageWidget.persistentRemote({
    Key? key,
    required String url,
    required BaseCacheManager cacheManager,
    Map<String, String> headers = const {},
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double? cornerRadius,
    bool isCircle = false,
    Color? backgroundColor,
    double? borderWidth,
    Color? borderColor,
    Widget? placeholder,
    Widget Function(BuildContext, Object, StackTrace?)? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 200),
    Duration fadeOutDuration = const Duration(milliseconds: 200),
  }) {
    return YuniImageWidget._(
      key: key,
      imageProvider: YuniPersistentRemoteImageProvider(
        url: url,
        cacheManager: cacheManager,
        headers: headers,
      ),
      url: url,
      width: width,
      height: height,
      fit: fit,
      cornerRadius: cornerRadius,
      isCircle: isCircle,
      backgroundColor: backgroundColor,
      borderWidth: borderWidth,
      borderColor: borderColor,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
    );
  }

  /// 创建从本地文件 [path] 加载图片的 [YuniImageWidget]。
  ///
  /// 不需要 [BaseCacheManager]，图片通过 [YuniLocalImageProvider] 直接从文件系统读取。
  factory YuniImageWidget.local({
    Key? key,
    required String path,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double? cornerRadius,
    bool isCircle = false,
    Color? backgroundColor,
    double? borderWidth,
    Color? borderColor,
    Widget? placeholder,
    Widget Function(BuildContext, Object, StackTrace?)? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 200),
    Duration fadeOutDuration = const Duration(milliseconds: 200),
  }) {
    return YuniImageWidget._(
      key: key,
      imageProvider: YuniLocalImageProvider(path: path),
      width: width,
      height: height,
      fit: fit,
      cornerRadius: cornerRadius,
      isCircle: isCircle,
      backgroundColor: backgroundColor,
      borderWidth: borderWidth,
      borderColor: borderColor,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
    );
  }

  // ---------------------------------------------------------------------------
  // 静态缓存清除方法
  // ---------------------------------------------------------------------------

  /// 清除 [url] 对应的内存缓存条目。
  ///
  /// 找到并成功清除返回 `true`，否则返回 `false`。
  ///
  /// [headers] 和 [includePersistent] 会透传给 [YuniImageCache]。
  /// [cacheManager] 必须与加载图片时使用的实例相同。
  static bool evictByUrl(
    String url, {
    Map<String, String>? headers,
    bool includePersistent = true,
    required BaseCacheManager cacheManager,
  }) {
    return YuniWidgetsBinding.customImageCache?.evictByUrl(
          url,
          headers: headers,
          includePersistent: includePersistent,
          cacheManager: cacheManager,
        ) ??
        false;
  }

  /// 批量清除 [urls] 中每个 URL 对应的内存缓存条目。
  ///
  /// 返回成功清除了至少一个条目的 URL 数量。
  ///
  /// [headers] 和 [includePersistent] 会透传给 [YuniImageCache]。
  /// [cacheManager] 必须与加载图片时使用的实例相同。
  static int evictByUrls(
    List<String> urls, {
    Map<String, String>? headers,
    bool includePersistent = true,
    required BaseCacheManager cacheManager,
  }) {
    return YuniWidgetsBinding.customImageCache?.evictByUrls(
          urls,
          headers: headers,
          includePersistent: includePersistent,
          cacheManager: cacheManager,
        ) ??
        0;
  }

  @override
  State<YuniImageWidget> createState() => _YuniImageWidgetState();
}

class _YuniImageWidgetState extends State<YuniImageWidget> {
  /// 当前使用的 [ImageProvider]。
  ImageProvider get imageProvider => widget.imageProvider;

  /// 当组件通过远程工厂构造且 URL 为空字符串时为 `true`，此时跳过加载直接显示错误图。
  bool get _isEmptyUrl => widget.url != null && widget.url!.isEmpty;

  @override
  void dispose() {
    // 组件销毁时，通知调度器延迟取消该 URL 的加载任务
    // 仅对远程图片有效，本地图片和持久化图片不参与调度取消
    final url = widget.url;
    if (url != null &&
        url.isNotEmpty &&
        widget.imageProvider is YuniRemoteImageProvider) {
      YuniImageLoadScheduler.instance.cancelDelayed(url);
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 构建
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isEmptyUrl) {
      return _buildErrorWidget(context, '图片 URL 为空', null);
    }

    final image = OctoImage(
      image: imageProvider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeInDuration: widget.fadeInDuration,
      fadeOutDuration: widget.fadeOutDuration,
      placeholderBuilder: (context) =>
          widget.placeholder ??
          YuniImagePlaceholder(width: widget.width, height: widget.height),
      errorBuilder: (context, error, stackTrace) {
        // 加载失败时清除损坏的缓存
        imageProvider.evict();
        return widget.errorWidget?.call(context, error, stackTrace) ??
            YuniImageError(width: widget.width, height: widget.height);
      },
    );

    return _applyAppearance(image);
  }

  // ---------------------------------------------------------------------------
  // 外观包装
  // ---------------------------------------------------------------------------

  /// 根据外观参数对 [child] 应用裁切和装饰层。
  ///
  /// 包装顺序（从外到内）：
  /// ```
  /// Container（backgroundColor / border）
  ///   └─ ClipOval 或 ClipRRect
  ///        └─ OctoImage
  /// ```
  Widget _applyAppearance(Widget child) {
    // 1. 应用圆形或圆角裁切
    Widget clipped = child;
    if (widget.isCircle) {
      clipped = ClipOval(child: child);
    } else if (widget.cornerRadius != null && widget.cornerRadius! > 0) {
      clipped = ClipRRect(
        borderRadius: BorderRadius.circular(widget.cornerRadius!),
        child: child,
      );
    }

    // 2. 需要背景色或边框时包裹 Container
    final needsContainer = widget.backgroundColor != null ||
        (widget.borderWidth != null && widget.borderColor != null);

    if (!needsContainer) return clipped;

    final decoration = BoxDecoration(
      color: widget.backgroundColor,
      border: (widget.borderWidth != null && widget.borderColor != null)
          ? Border.all(
              color: widget.borderColor!,
              width: widget.borderWidth!,
            )
          : null,
      // 让 Container 的形状与裁切形状保持一致，使边框跟随曲线
      shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: (!widget.isCircle &&
              widget.cornerRadius != null &&
              widget.cornerRadius! > 0)
          ? BorderRadius.circular(widget.cornerRadius!)
          : null,
    );

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: decoration,
      child: clipped,
    );
  }

  // ---------------------------------------------------------------------------
  // 辅助方法
  // ---------------------------------------------------------------------------

  Widget _buildErrorWidget(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return widget.errorWidget?.call(context, error, stackTrace) ??
        YuniImageError(width: widget.width, height: widget.height);
  }
}
