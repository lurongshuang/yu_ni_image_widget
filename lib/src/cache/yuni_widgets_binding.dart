import 'package:flutter/widgets.dart';

import 'yuni_image_cache.dart';

/// 自定义 [WidgetsFlutterBinding]，将 Flutter 默认的 [ImageCache]
/// 替换为 [YuniImageCache]。
///
/// 在 `main()` 中用 [YuniWidgetsBinding.ensureInitialized] 替代
/// [WidgetsFlutterBinding.ensureInitialized]：
///
/// ```dart
/// void main() {
///   YuniWidgetsBinding.ensureInitialized();
///   runApp(const MyApp());
/// }
/// ```
final class YuniWidgetsBinding extends WidgetsFlutterBinding {
  /// 若 Binding 尚未初始化则进行初始化，否则直接返回已有实例（幂等）。
  ///
  /// 多次调用是安全的，不会重复创建实例。
  ///
  /// 返回当前的 [WidgetsBinding] 实例。
  static WidgetsBinding ensureInitialized() {
    // 直接构造——WidgetsFlutterBinding 的构造函数内部会调用 initInstances()，
    // 若已有实例则不会重复注册，因此是幂等的。
    // 不能在构造前读取 WidgetsBinding.instance，因为首次调用时 binding 尚未初始化。
    YuniWidgetsBinding();
    return WidgetsBinding.instance;
  }

  /// 返回当前的 [YuniImageCache] 实例。
  /// 若 [YuniWidgetsBinding] 尚未初始化则返回 `null`。
  static YuniImageCache? get customImageCache {
    try {
      final binding = WidgetsBinding.instance;
      if (binding is YuniWidgetsBinding) {
        return binding.imageCache as YuniImageCache?;
      }
      return null;
    } catch (_) {
      // binding 尚未初始化时返回 null
      return null;
    }
  }

  /// 创建并返回 [YuniImageCache] 实例，替换 Flutter 默认的 [ImageCache]。
  @override
  ImageCache createImageCache() => YuniImageCache();
}
