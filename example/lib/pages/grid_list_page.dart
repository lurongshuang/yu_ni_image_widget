import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:yu_ni_image_widget/yu_ni_image_widget.dart';

/// 相册缩略图网格演示页
///
/// 进入页面时开启优先级调度，离开时关闭。
/// 快速滑动时，已滑出视口的图片加载任务会在 500ms 后被取消，
/// 当前可见的图片优先占用高优先级并发槽（最多 6 个）。
class GridListPage extends StatefulWidget {
  const GridListPage({super.key});

  @override
  State<GridListPage> createState() => _GridListPageState();
}

class _GridListPageState extends State<GridListPage> {
  static final _cacheManager = DefaultCacheManager();

  // 生成 200 张不同的图片 URL
  static final _urls = List.generate(
    200,
    (i) => 'https://picsum.photos/id/${(i % 100) + 10}/300/300',
  );

  @override
  void initState() {
    super.initState();
    // 进入图片列表页面时开启优先级调度
    YuniImageLoadScheduler.instance.enabled = true;
  }

  @override
  void dispose() {
    // 离开页面时关闭调度，避免影响其他页面
    YuniImageLoadScheduler.instance.enabled = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('相册网格（优先级调度演示）'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: _urls.length,
        itemBuilder: (context, index) {
          return YuniImageWidget.remote(
            url: _urls[index],
            cacheManager: _cacheManager,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('调度策略说明'),
        content: const Text(
          '• 视口内图片：高优先级，最多 6 个并发\n'
          '• 视口外图片：低优先级，最多 2 个并发\n'
          '• 滑出视口 500ms 后取消未完成的加载任务\n'
          '• 重新滑入视口时自动升级为高优先级\n\n'
          '进入此页面时调度器自动开启，\n'
          '离开页面时自动关闭，不影响其他页面。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
