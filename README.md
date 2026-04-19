# yu_ni_image_widget

> Flutter 图片展示组件库 | 展示与缓存分离 | 分类内存管理 | 视口优先级调度

## 简介

`yu_ni_image_widget` 是从主项目 `ynphotos_image` 提炼的独立 Flutter 图片展示组件库。

**核心设计原则：展示与缓存分离。** 组件库只负责图片的展示逻辑、运行时内存分类管理和加载优先级调度；缓存的获取与存储策略完全由外部通过注入 `BaseCacheManager` 对象来控制。不同项目可以使用各自的缓存策略，共享同一套展示逻辑。

## 功能特性

- **三种图片来源**：远程 URL、持久化远程 URL、本地文件路径
- **展示与缓存分离**：不内置任何缓存实现，完全由外部 `BaseCacheManager` 控制
- **分类内存缓存**：五个分类（icon / thumbnail / local / full / persistent）独立 FIFO 淘汰
- **持久化保活**：重要图片持有永久 listener，不被 LRU 驱逐，返回页面无闪烁
- **视口优先级调度**：快速滑动时视口内图片优先加载，视口外任务自动降级或取消
- **主题集成**：默认占位图和错误图使用 `YuniWidgetConfig` 颜色令牌，无硬编码
- **请求头支持**：`headers` 参数透传给 `BaseCacheManager`，支持鉴权等场景

## 依赖

```yaml
dependencies:
  yu_ni_image_widget:
    git:
      url: https://github.com/lurongshuang/yu_ni_image_widget.git
      ref: master
  flutter_cache_manager: ^3.4.1  # 提供 BaseCacheManager 接口
```

## 快速开始

### 第一步：初始化

在 `main()` 中用 `YuniWidgetsBinding.ensureInitialized()` 替代 `WidgetsFlutterBinding.ensureInitialized()`：

```dart
void main() {
  // 替代 WidgetsFlutterBinding.ensureInitialized()
  YuniWidgetsBinding.ensureInitialized();
  runApp(const MyApp());
}
```

> 必须在 `runApp` 之前调用，否则自定义 ImageCache 不会生效。

### 第二步：准备 BaseCacheManager

```dart
// 使用 flutter_cache_manager 提供的默认实现
final cacheManager = DefaultCacheManager();

// 或自定义实现（推荐：单例复用）
class MyCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'myCache';
  MyCacheManager() : super(Config(key, stalePeriod: const Duration(days: 7)));
}
final cacheManager = MyCacheManager();
```

### 第三步：展示图片

```dart
// 远程图片
YuniImageWidget.remote(
  url: 'https://example.com/photo.jpg',
  cacheManager: cacheManager,
  width: 200,
  height: 200,
)

// 持久化远程图片（相册封面、用户头像）
YuniImageWidget.persistentRemote(
  url: 'https://example.com/avatar.jpg',
  cacheManager: cacheManager,
  width: 60,
  height: 60,
  isCircle: true,
)

// 本地文件图片
YuniImageWidget.local(
  path: '/path/to/image.jpg',
  width: 200,
  height: 200,
)
```

---

## API 参考

### YuniImageWidget

图片展示主组件，通过三个工厂构造函数创建实例。

---

#### `YuniImageWidget.remote`

从远程 URL 加载图片，适用于普通缩略图、列表图片等场景。

```dart
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
})
```

**参数说明：**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `url` | `String` | ✅ | — | 图片远程 URL。为空字符串时直接显示错误图，不发起网络请求 |
| `cacheManager` | `BaseCacheManager` | ✅ | — | 缓存管理器实例，负责网络请求和磁盘缓存，由调用方注入 |
| `headers` | `Map<String, String>` | ❌ | `{}` | HTTP 请求头，透传给 `cacheManager.getSingleFile()`，适用于鉴权场景 |
| `width` | `double?` | ❌ | `null` | 组件宽度，为 null 时由父组件约束决定 |
| `height` | `double?` | ❌ | `null` | 组件高度，为 null 时由父组件约束决定 |
| `fit` | `BoxFit` | ❌ | `BoxFit.cover` | 图片填充方式，可选 cover / contain / fill / fitWidth / fitHeight / none / scaleDown |
| `cornerRadius` | `double?` | ❌ | `null` | 圆角半径（px）。`isCircle` 为 true 时忽略此参数 |
| `isCircle` | `bool` | ❌ | `false` | 为 true 时使用 ClipOval 裁切为圆形，优先级高于 cornerRadius |
| `backgroundColor` | `Color?` | ❌ | `null` | 图片背景色，在图片加载中或透明区域显示 |
| `borderWidth` | `double?` | ❌ | `null` | 边框宽度（px），需与 borderColor 同时设置才生效 |
| `borderColor` | `Color?` | ❌ | `null` | 边框颜色，需与 borderWidth 同时设置才生效 |
| `placeholder` | `Widget?` | ❌ | `YuniImagePlaceholder` | 加载中显示的占位图，不传则使用主题色默认占位图 |
| `errorWidget` | `Widget Function(BuildContext, Object, StackTrace?)?` | ❌ | `YuniImageError` | 加载失败时的错误图，不传则使用主题色默认错误图 |
| `fadeInDuration` | `Duration` | ❌ | `200ms` | 图片加载完成后的淡入动画时长 |
| `fadeOutDuration` | `Duration` | ❌ | `200ms` | 占位图消失的淡出动画时长 |

---

#### `YuniImageWidget.persistentRemote`

从远程 URL 加载图片，并将其归入持久化缓存分类，不会被 LRU 驱逐。
适用于相册封面、用户头像等返回页面时不能闪烁的重要图片。

```dart
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
})
```

参数与 `YuniImageWidget.remote` 完全相同，区别在于底层使用 `YuniPersistentRemoteImageProvider`，
`YuniImageCache` 会将其归类为 `persistent` 分类并持有永久 listener 保活。

> **注意**：持久化图片不受 `YuniImageCache.clear()` 影响，只能通过 `evictByUrl` 显式清除。

---

#### `YuniImageWidget.local`

从本地文件路径加载图片，不需要 `BaseCacheManager`。

```dart
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
})
```

**参数说明（与 remote 不同的部分）：**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `path` | `String` | ✅ | — | 本地文件的绝对路径或相对路径。文件不存在或字节为空时显示错误图 |

其余外观参数（width / height / fit / cornerRadius / isCircle / backgroundColor / borderWidth / borderColor / placeholder / errorWidget / fadeInDuration / fadeOutDuration）与 `remote` 完全相同。

---

#### `YuniImageWidget.evictByUrl`（静态方法）

清除指定 URL 的内存缓存条目。

```dart
static bool evictByUrl(
  String url, {
  Map<String, String>? headers,
  bool includePersistent = true,
  required BaseCacheManager cacheManager,
})
```

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `url` | `String` | ✅ | — | 要清除的图片 URL |
| `headers` | `Map<String, String>?` | ❌ | `null` | 加载时使用的请求头（用于构造匹配的 Provider key） |
| `includePersistent` | `bool` | ❌ | `true` | 是否同时清除持久化缓存分类的条目 |
| `cacheManager` | `BaseCacheManager` | ✅ | — | 加载时使用的缓存管理器实例 |

**返回值**：`bool` — 成功清除至少一个条目返回 `true`，否则返回 `false`。

> **注意**：此方法只清除内存缓存。如需同时清除磁盘缓存，需额外调用：
> ```dart
> await cacheManager.removeFile(url);
> ```

---

#### `YuniImageWidget.evictByUrls`（静态方法）

批量清除多个 URL 的内存缓存条目。

```dart
static int evictByUrls(
  List<String> urls, {
  Map<String, String>? headers,
  bool includePersistent = true,
  required BaseCacheManager cacheManager,
})
```

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `urls` | `List<String>` | ✅ | — | 要清除的图片 URL 列表 |
| `headers` | `Map<String, String>?` | ❌ | `null` | 加载时使用的请求头 |
| `includePersistent` | `bool` | ❌ | `true` | 是否同时清除持久化缓存分类的条目 |
| `cacheManager` | `BaseCacheManager` | ✅ | — | 加载时使用的缓存管理器实例 |

**返回值**：`int` — 成功清除了至少一个条目的 URL 数量。

---

### YuniWidgetsBinding

自定义 `WidgetsFlutterBinding`，将 Flutter 默认的 `ImageCache` 替换为 `YuniImageCache`。

#### `YuniWidgetsBinding.ensureInitialized()`（静态方法）

```dart
static WidgetsBinding ensureInitialized()
```

初始化自定义 Binding。幂等，多次调用安全。**必须在 `runApp()` 之前调用。**

**返回值**：当前 `WidgetsBinding` 实例。

#### `YuniWidgetsBinding.customImageCache`（静态属性）

```dart
static YuniImageCache? get customImageCache
```

返回当前的 `YuniImageCache` 实例。若 `YuniWidgetsBinding` 尚未初始化则返回 `null`。

---

### YuniImageCache

自定义 `ImageCache`，将图片分为五个分类独立管理。

#### 分类上限

| 分类 | 触发条件 | 数量上限 | 字节上限 | 淘汰策略 |
|------|---------|---------|---------|----------|
| `icon` | `AssetBundleImageKey` | 100 张 | 50 MB | FIFO + 永久 listener 保活 |
| `persistent` | `YuniPersistentRemoteImageProvider` | 无限制 | 无限制 | 永久 listener 保活，不驱逐 |
| `thumbnail` | `YuniRemoteImageProvider` 及其他 | 1000 张 | 500 MB | FIFO |
| `local` | `YuniLocalImageProvider` | 50 张 | 80 MB | FIFO |
| `full` | 其他未分类 | 5 张 | 无限制 | FIFO |

全局 `maximumSize` = (100 + 1000 + 50 + 5) × 1.3 ≈ **1502 张**  
全局 `maximumSizeBytes` = (50 + 500 + 80) MB × 1.3 ≈ **819 MB**

#### `YuniImageCache.evictByUrl`

```dart
bool evictByUrl(
  String url, {
  Map<String, String>? headers,
  bool includePersistent = true,
  required BaseCacheManager cacheManager,
})
```

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `url` | `String` | ✅ | — | 要清除的图片 URL |
| `headers` | `Map<String, String>?` | ❌ | `null` | 加载时使用的请求头 |
| `includePersistent` | `bool` | ❌ | `true` | 是否同时清除 persistent 分类 |
| `cacheManager` | `BaseCacheManager` | ✅ | — | 加载时使用的缓存管理器实例 |

**返回值**：`bool` — 至少清除一个条目返回 `true`。

#### `YuniImageCache.evictByUrls`

```dart
int evictByUrls(
  List<String> urls, {
  Map<String, String>? headers,
  bool includePersistent = true,
  required BaseCacheManager cacheManager,
})
```

**返回值**：`int` — 成功清除了至少一个条目的 URL 数量。

#### `YuniImageCache.clear()`

```dart
@override
void clear()
```

只清除 `thumbnail`、`local`、`full` 分类，**保留** `persistent` 和 `icon` 分类。

#### `YuniImageCache.evict()`

```dart
@override
bool evict(Object key, {bool includeLive = true})
```

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `key` | `Object` | — | ImageProvider 实例（作为缓存 key） |
| `includeLive` | `bool` | `true` | 是否强制清除有活跃 listener 的图片（默认 true，确保彻底清除） |

---

### YuniImageLoadScheduler

视口感知的图片加载优先级调度器（单例）。**默认关闭**，需要显式开启。

#### `YuniImageLoadScheduler.instance`

全局单例，通过 `YuniImageLoadScheduler.instance` 访问。

#### `enabled`（属性）

```dart
bool enabled = false;
```

| 值 | 行为 |
|----|------|
| `false`（默认） | 所有请求直接透传给 `BaseCacheManager`，零开销，行为与不接入调度器相同 |
| `true` | 请求进入优先级队列，高优先级（视口内）最多 6 个并发，低优先级（视口外）最多 2 个并发 |

**推荐用法**：在图片列表页面的 `initState` 开启，`dispose` 关闭：

```dart
@override
void initState() {
  super.initState();
  YuniImageLoadScheduler.instance.enabled = true;
}

@override
void dispose() {
  YuniImageLoadScheduler.instance.enabled = false;
  super.dispose();
}
```

#### 调度策略

| 队列 | 并发上限 | 触发条件 |
|------|---------|----------|
| 高优先级队列 | 6 | 组件在视口内（`YuniImageWidget` 创建时） |
| 低优先级队列 | 2 | 组件滑出视口后降级 |

- 相同 URL 已有任务时直接复用，不重复发起请求
- 低优先级任务重新进入视口时自动升级到高优先级队列头部
- 组件 `dispose` 后 **500ms** 内若任务未完成则取消，释放并发槽位
- 取消的任务不触发 `errorWidget`，静默终止

#### `YuniImageLoadPriority`（枚举）

```dart
enum YuniImageLoadPriority {
  high,  // 高优先级：视口内可见的图片
  low,   // 低优先级：已滑出视口、预加载或后台任务
}
```

---

## 使用示例

### 带鉴权请求头的远程图片

```dart
YuniImageWidget.remote(
  url: 'https://api.example.com/private/photo.jpg',
  cacheManager: myCacheManager,
  headers: {
    'Authorization': 'Bearer your-token',
    'X-App-Version': '1.0.0',
  },
  width: 300,
  height: 200,
  fit: BoxFit.cover,
  cornerRadius: 8,
)
```

### 圆形头像（持久化）

```dart
YuniImageWidget.persistentRemote(
  url: user.avatarUrl,
  cacheManager: myCacheManager,
  headers: {'Authorization': 'Bearer \${token}'},
  width: 48,
  height: 48,
  isCircle: true,
  borderWidth: 2,
  borderColor: Colors.white,
)
```

### 清除缓存并强制重新加载

```dart
Future<void> refreshImage(String url) async {
  // 1. 清除内存缓存
  YuniImageWidget.evictByUrl(url, cacheManager: myCacheManager);
  // 2. 清除磁盘缓存
  await myCacheManager.removeFile(url);
  // 3. 触发 UI 重建（例如更新 key）
  setState(() => _imageKey = UniqueKey());
}
```

### 图片列表开启优先级调度

```dart
class PhotoGridPage extends StatefulWidget { ... }

class _PhotoGridPageState extends State<PhotoGridPage> {
  @override
  void initState() {
    super.initState();
    YuniImageLoadScheduler.instance.enabled = true;
  }

  @override
  void dispose() {
    YuniImageLoadScheduler.instance.enabled = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemBuilder: (context, index) => YuniImageWidget.remote(
        url: photos[index].url,
        cacheManager: myCacheManager,
        fit: BoxFit.cover,
      ),
    );
  }
}
```

---

## 从 ynphotos_image 迁移

| 主项目 | yu_ni_image_widget |
|--------|-------------------|
| `YNPhotosWidgetsBinding.ensureInitialized()` | `YuniWidgetsBinding.ensureInitialized()` |
| `YNPhotosImage.remote(url:, cacheManager:)` | `YuniImageWidget.remote(url:, cacheManager:)` |
| `YNPhotosImage.persistentRemote(url:, cacheManager:)` | `YuniImageWidget.persistentRemote(url:, cacheManager:)` |
| `YNPhotosImage.local(path:)` | `YuniImageWidget.local(path:)` |
| `YNPhotosImage.evictByUrl(url, cacheManager:)` | `YuniImageWidget.evictByUrl(url, cacheManager:)` |
| `YNPhotosImage.evictByUrls(urls, cacheManager:)` | `YuniImageWidget.evictByUrls(urls, cacheManager:)` |
| `CustomImageCache` | `YuniImageCache` |
| `YNPhotosWidgetsBinding.customImageCache` | `YuniWidgetsBinding.customImageCache` |

**新增能力（主项目没有的）：**
- `headers` 参数支持（鉴权请求头）
- `YuniImageLoadScheduler` 视口优先级调度
- `evict(includeLive: true)` 强制清除有活跃 listener 的缓存

---

## 架构概览

```
调用方
  │
  ├─ YuniImageWidget.remote / persistentRemote / local
  │       │
  │       ├─ 外观层：ClipOval / ClipRRect / Container（border/background）
  │       │
  │       └─ OctoImage（淡入淡出、占位图、错误图）
  │               │
  │               └─ YuniRemoteImageProvider / YuniPersistentRemoteImageProvider / YuniLocalImageProvider
  │                       │
  │                       └─ YuniImageLoadScheduler（优先级调度，默认关闭）
  │                               │
  │                               └─ BaseCacheManager.getSingleFile()（由调用方注入）
  │
  ├─ YuniWidgetsBinding.ensureInitialized()
  │       │
  │       └─ 替换 Flutter 全局 ImageCache → YuniImageCache
  │               │
  │               ├─ icon 分类（Asset）：100 张 / 50MB，永久保活
  │               ├─ persistent 分类：无限制，永久保活
  │               ├─ thumbnail 分类（远程）：1000 张 / 500MB，FIFO
  │               ├─ local 分类：50 张 / 80MB，FIFO
  │               └─ full 分类：5 张，FIFO
  │
  └─ YuniImageLoadScheduler.instance.enabled = true（图片列表页面）
          │
          ├─ 高优先级队列（视口内）：并发 6
          └─ 低优先级队列（视口外）：并发 2，500ms 后取消
```

---

## 环境要求

| 依赖 | 版本 |
|------|------|
| Dart SDK | `>=3.0.0 <4.0.0` |
| Flutter | `>=3.10.0` |
| flutter_cache_manager | `^3.4.1` |
| octo_image | `^2.1.0` |
| yuni_widget | `^0.1.8` |

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## 仓库

[https://github.com/lurongshuang/yu_ni_image_widget](https://github.com/lurongshuang/yu_ni_image_widget)
