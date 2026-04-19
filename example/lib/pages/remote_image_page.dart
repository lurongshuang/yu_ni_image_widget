import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:yu_ni_image_widget/yu_ni_image_widget.dart';

class RemoteImagePage extends StatelessWidget {
  const RemoteImagePage({super.key});

  static final _cacheManager = DefaultCacheManager();

  // 模拟需要鉴权的请求头（实际项目中替换为真实 token）
  static const _authHeaders = {
    'Authorization': 'Bearer demo-token-123',
    'X-App-Version': '1.0.0',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('远程图片加载')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 默认占位图和错误图 ─────────────────────────────────────────────
          _sectionTitle('默认占位图和错误图'),
          const SizedBox(height: 8),
          YuniImageWidget.remote(
            url: 'https://picsum.photos/300/200',
            cacheManager: _cacheManager,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            cornerRadius: 8,
          ),

          const SizedBox(height: 24),

          // ── 自定义占位图 ───────────────────────────────────────────────────
          _sectionTitle('自定义占位图'),
          const SizedBox(height: 8),
          YuniImageWidget.remote(
            url: 'https://picsum.photos/300/201',
            cacheManager: _cacheManager,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            placeholder: Container(
              color: Colors.blue.shade100,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),

          const SizedBox(height: 24),

          // ── 自定义错误图 ───────────────────────────────────────────────────
          _sectionTitle('自定义错误图（无效 URL）'),
          const SizedBox(height: 8),
          YuniImageWidget.remote(
            url: 'https://invalid.example.com/notfound.jpg',
            cacheManager: _cacheManager,
            width: double.infinity,
            height: 200,
            errorWidget: (context, error, stackTrace) => Container(
              color: Colors.red.shade100,
              child: const Center(child: Text('图片加载失败')),
            ),
          ),

          const SizedBox(height: 24),

          // ── 带请求头的图片 ─────────────────────────────────────────────────
          _sectionTitle('带请求头 headers（模拟鉴权）'),
          const SizedBox(height: 4),
          // 展示当前使用的 headers
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'headers:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                ..._authHeaders.entries.map(
                  (e) => Text(
                    '  ${e.key}: ${e.value}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 注意：picsum 不校验 headers，这里仅演示参数传递方式
          // 实际项目中 headers 会被 cacheManager.getSingleFile 透传到 HTTP 请求
          YuniImageWidget.remote(
            url: 'https://picsum.photos/seed/auth/600/200',
            cacheManager: _cacheManager,
            headers: _authHeaders,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            cornerRadius: 8,
          ),
          const SizedBox(height: 4),
          const Text(
            '* headers 会透传给 BaseCacheManager.getSingleFile()，\n'
            '  适用于需要 Authorization、Cookie 等鉴权头的私有图片资源。',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),

          const SizedBox(height: 24),

          // ── 持久化图片带请求头 ─────────────────────────────────────────────
          _sectionTitle('持久化图片 + headers（相册封面鉴权场景）'),
          const SizedBox(height: 8),
          YuniImageWidget.persistentRemote(
            url: 'https://picsum.photos/seed/persistent-auth/600/200',
            cacheManager: _cacheManager,
            headers: _authHeaders,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            cornerRadius: 8,
          ),
          const SizedBox(height: 4),
          const Text(
            '* persistentRemote 同样支持 headers，\n'
            '  适用于需要鉴权的相册封面、用户头像等重要图片。',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }
}
