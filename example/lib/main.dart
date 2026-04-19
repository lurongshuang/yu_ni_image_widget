import 'package:flutter/material.dart';
import 'package:yu_ni_image_widget/yu_ni_image_widget.dart';
import 'pages/remote_image_page.dart';
import 'pages/persistent_image_page.dart';
import 'pages/local_image_page.dart';
import 'pages/evict_cache_page.dart';
import 'pages/style_demo_page.dart';
import 'pages/grid_list_page.dart';

void main() {
  YuniWidgetsBinding.ensureInitialized();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YuniImageWidget 示例',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YuniImageWidget 示例')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('远程图片加载'),
            subtitle: const Text('默认占位图、自定义占位图、错误图'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RemoteImagePage())),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('持久化远程图片'),
            subtitle: const Text('导航离开再返回，验证不闪烁'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PersistentImagePage())),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('本地文件图片'),
            subtitle: const Text('从本地路径加载图片'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LocalImagePage())),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('清除缓存'),
            subtitle: const Text('evictByUrl 清除后强制重新加载'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EvictCachePage())),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('样式参数演示'),
            subtitle: const Text('圆角、圆形、背景色、边框、BoxFit、淡入时长'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const StyleDemoPage())),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('相册网格（优先级调度）'),
            subtitle: const Text('快速滑动时视口内图片优先加载'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GridListPage())),
          ),
        ],
      ),
    );
  }
}
