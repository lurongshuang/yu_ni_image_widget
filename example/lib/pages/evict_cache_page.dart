import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:yu_ni_image_widget/yu_ni_image_widget.dart';

class EvictCachePage extends StatefulWidget {
  const EvictCachePage({super.key});

  @override
  State<EvictCachePage> createState() => _EvictCachePageState();
}

class _EvictCachePageState extends State<EvictCachePage> {
  static final _cacheManager = DefaultCacheManager();
  static const _imageUrl =
      'https://fastly.picsum.photos/id/533/4000/3000.jpg?hmac=p2WjFxtJrj3HlV9XpiBoEWT4hphDzwhSa1OcpjifTnI';

  int _reloadKey = 0;
  String _status = '图片已从缓存加载（如有缓存）';
  bool _clearing = false;

  Future<void> _evictAndReload() async {
    setState(() => _clearing = true);
    // 2. 清除磁盘缓存，否则下次加载仍从磁盘读取，看起来像没清
    await _cacheManager.removeFile(_imageUrl);

    // 1. 清除内存缓存
    YuniImageWidget.evictByUrl(_imageUrl, cacheManager: _cacheManager);

    setState(() {
      _reloadKey++;
      _status = '内存 + 磁盘缓存已清除，正在从网络重新加载...';
      _clearing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('清除缓存')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_status),
            const SizedBox(height: 16),
            YuniImageWidget.remote(
              key: ValueKey(_reloadKey),
              url: _imageUrl,
              cacheManager: _cacheManager,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              cornerRadius: 8,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _clearing ? null : _evictAndReload,
              icon: _clearing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_clearing ? '清除中...' : '清除缓存并重新加载'),
            ),
          ],
        ),
      ),
    );
  }
}
