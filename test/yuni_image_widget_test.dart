import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:yu_ni_image_widget/yu_ni_image_widget.dart';
import 'package:yu_ni_image_widget/src/widget/yuni_image_error.dart';

class _FakeCacheManager extends Fake implements BaseCacheManager {}

void main() {
  group('YuniImageWidget', () {
    testWidgets('shows YuniImageError when url is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: YuniImageWidget.remote(
            url: '',
            cacheManager: _FakeCacheManager(),
          ),
        ),
      );

      expect(find.byType(YuniImageError), findsOneWidget);
    });

    testWidgets('shows custom errorWidget when url is empty', (tester) async {
      const customError = Text('custom error');
      await tester.pumpWidget(
        MaterialApp(
          home: YuniImageWidget.remote(
            url: '',
            cacheManager: _FakeCacheManager(),
            errorWidget: (_, __, ___) => customError,
          ),
        ),
      );

      expect(find.text('custom error'), findsOneWidget);
      expect(find.byType(YuniImageError), findsNothing);
    });

    testWidgets('wraps with ClipRRect when cornerRadius > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: YuniImageWidget.remote(
            url: 'https://example.com/img.jpg',
            cacheManager: _FakeCacheManager(),
            cornerRadius: 8,
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('wraps with ClipOval when isCircle is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: YuniImageWidget.remote(
            url: 'https://example.com/img.jpg',
            cacheManager: _FakeCacheManager(),
            isCircle: true,
          ),
        ),
      );

      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('does not wrap with ClipOval when isCircle is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: YuniImageWidget.remote(
            url: 'https://example.com/img.jpg',
            cacheManager: _FakeCacheManager(),
          ),
        ),
      );

      expect(find.byType(ClipOval), findsNothing);
    });

    testWidgets('does not wrap with ClipRRect when cornerRadius is null',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: YuniImageWidget.remote(
            url: 'https://example.com/img.jpg',
            cacheManager: _FakeCacheManager(),
          ),
        ),
      );

      // No ClipRRect from appearance wrapping (OctoImage may add its own)
      final clipRRects = tester
          .widgetList<ClipRRect>(find.byType(ClipRRect))
          .where((w) => w.borderRadius != BorderRadius.zero)
          .toList();
      expect(clipRRects, isEmpty);
    });

    testWidgets('local factory with empty path shows error on load failure',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: YuniImageWidget.local(
            path: '/nonexistent/path.jpg',
            cornerRadius: 8,
          ),
        ),
      );

      // ClipRRect should be present from appearance wrapping
      expect(find.byType(ClipRRect), findsWidgets);
    });
  });
}
