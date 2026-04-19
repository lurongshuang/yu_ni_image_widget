import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:yu_ni_image_widget/yu_ni_image_widget.dart';

class PersistentImagePage extends StatelessWidget {
  const PersistentImagePage({super.key});

  static final _cacheManager = DefaultCacheManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('持久化远程图片')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '点击"跳转其他页面"后返回，持久化图片不会重新加载（无闪烁）。',
              style: TextStyle(fontSize: 14),
            ),
          ),
          YuniImageWidget.persistentRemote(
            url: 'https://picsum.photos/seed/persistent/400/300',
            cacheManager: _cacheManager,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('其他页面')),
                  body: const Center(child: Text('返回上一页，验证图片不闪烁')),
                ),
              ),
            ),
            child: const Text('跳转其他页面'),
          ),
        ],
      ),
    );
  }
}
