import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yu_ni_image_widget/yu_ni_image_widget.dart';

class LocalImagePage extends StatefulWidget {
  const LocalImagePage({super.key});

  @override
  State<LocalImagePage> createState() => _LocalImagePageState();
}

class _LocalImagePageState extends State<LocalImagePage> {
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _prepareLocalImage();
  }

  Future<void> _prepareLocalImage() async {
    // 演示用途：使用临时目录路径
    // 实际项目中应传入相册或文件选择器返回的真实路径
    final dir = await getTemporaryDirectory();
    setState(() {
      _localPath = '${dir.path}/demo_image.jpg';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本地文件图片')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('本地文件图片（文件不存在时显示错误图）：'),
            const SizedBox(height: 8),
            if (_localPath != null)
              YuniImageWidget.local(
                path: _localPath!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                cornerRadius: 8,
              )
            else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
