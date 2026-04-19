import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:yu_ni_image_widget/yu_ni_image_widget.dart';

/// 样式参数演示页
/// 覆盖：cornerRadius、isCircle、backgroundColor、border、fit、fadeInDuration
class StyleDemoPage extends StatelessWidget {
  const StyleDemoPage({super.key});

  static final _cacheManager = DefaultCacheManager();

  // 用不同 seed 保证每张图片不同
  static const _base = 'https://picsum.photos/seed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('样式参数演示')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 圆角 ──────────────────────────────────────────────────────────
          _sectionTitle('圆角 cornerRadius'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _labeledWidget(
                '无圆角',
                YuniImageWidget.remote(
                  url: '$_base/r0/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              _labeledWidget(
                'radius=8',
                YuniImageWidget.remote(
                  url: '$_base/r8/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 8,
                ),
              ),
              _labeledWidget(
                'radius=24',
                YuniImageWidget.remote(
                  url: '$_base/r24/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── 圆形 ──────────────────────────────────────────────────────────
          _sectionTitle('圆形裁切 isCircle'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _labeledWidget(
                'isCircle=false',
                YuniImageWidget.remote(
                  url: '$_base/circle1/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              _labeledWidget(
                'isCircle=true',
                YuniImageWidget.remote(
                  url: '$_base/circle2/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  isCircle: true,
                ),
              ),
              _labeledWidget(
                '圆形+边框',
                YuniImageWidget.remote(
                  url: '$_base/circle3/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  isCircle: true,
                  borderWidth: 3,
                  borderColor: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── 背景色 ────────────────────────────────────────────────────────
          _sectionTitle('背景色 backgroundColor'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _labeledWidget(
                '无背景色',
                YuniImageWidget.remote(
                  url: '$_base/bg1/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 8,
                ),
              ),
              _labeledWidget(
                '蓝色背景',
                YuniImageWidget.remote(
                  url: '$_base/bg2/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 8,
                  backgroundColor: Colors.blue.shade100,
                ),
              ),
              _labeledWidget(
                '橙色背景',
                YuniImageWidget.remote(
                  url: '$_base/bg3/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 8,
                  backgroundColor: Colors.orange.shade100,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── 边框 ──────────────────────────────────────────────────────────
          _sectionTitle('边框 borderWidth / borderColor'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _labeledWidget(
                '无边框',
                YuniImageWidget.remote(
                  url: '$_base/bd1/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 8,
                ),
              ),
              _labeledWidget(
                '蓝色边框 2px',
                YuniImageWidget.remote(
                  url: '$_base/bd2/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 8,
                  borderWidth: 2,
                  borderColor: Colors.blue,
                ),
              ),
              _labeledWidget(
                '红色边框 4px',
                YuniImageWidget.remote(
                  url: '$_base/bd3/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 8,
                  borderWidth: 4,
                  borderColor: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── BoxFit ────────────────────────────────────────────────────────
          _sectionTitle('填充方式 BoxFit'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _labeledWidget(
                'cover',
                YuniImageWidget.remote(
                  url: '$_base/fit1/200/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 8,
                ),
              ),
              _labeledWidget(
                'contain',
                YuniImageWidget.remote(
                  url: '$_base/fit2/200/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  cornerRadius: 8,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              _labeledWidget(
                'fill',
                YuniImageWidget.remote(
                  url: '$_base/fit3/200/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.fill,
                  cornerRadius: 8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── 淡入时长 ──────────────────────────────────────────────────────
          _sectionTitle('淡入时长 fadeInDuration'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _labeledWidget(
                '0ms（无动画）',
                YuniImageWidget.remote(
                  url: '$_base/fade1/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 8,
                  fadeInDuration: Duration.zero,
                ),
              ),
              _labeledWidget(
                '200ms（默认）',
                YuniImageWidget.remote(
                  url: '$_base/fade2/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 8,
                ),
              ),
              _labeledWidget(
                '800ms（慢）',
                YuniImageWidget.remote(
                  url: '$_base/fade3/120/120',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  cornerRadius: 8,
                  fadeInDuration: const Duration(milliseconds: 800),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── 空 URL（错误图） ───────────────────────────────────────────────
          _sectionTitle('空 URL → 直接显示错误图'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _labeledWidget(
                '默认错误图',
                YuniImageWidget.remote(
                  url: '',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                ),
              ),
              _labeledWidget(
                '自定义错误图',
                YuniImageWidget.remote(
                  url: '',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  errorWidget: (_, __, ___) => Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.warning_amber, color: Colors.red),
                    ),
                  ),
                ),
              ),
              _labeledWidget(
                '加载失败错误图',
                YuniImageWidget.remote(
                  url: 'https://invalid.example.com/x.jpg',
                  cacheManager: _cacheManager,
                  width: 100,
                  height: 100,
                  cornerRadius: 8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 分组标题
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  /// 带标签的组件
  Widget _labeledWidget(String label, Widget child) {
    return Column(
      children: [
        child,
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
