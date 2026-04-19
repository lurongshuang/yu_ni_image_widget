/// yu_ni_image_widget
///
/// 基于注入 [BaseCacheManager] 的 Flutter 图片展示组件库。
///
/// ## 快速开始
///
/// 1. 在 `main()` 中调用 [YuniWidgetsBinding.ensureInitialized]：
///    ```dart
///    void main() {
///      YuniWidgetsBinding.ensureInitialized();
///      runApp(const MyApp());
///    }
///    ```
///
/// 2. 使用工厂构造函数展示图片：
///    ```dart
///    YuniImageWidget.remote(
///      url: 'https://example.com/photo.jpg',
///      cacheManager: myCacheManager,
///    )
///    ```
library yu_ni_image_widget;

export 'src/cache/yuni_image_cache.dart';
export 'src/cache/yuni_widgets_binding.dart';
export 'src/scheduler/yuni_image_load_scheduler.dart';
export 'src/widget/yuni_image_widget.dart';
