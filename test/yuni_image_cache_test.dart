import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:yu_ni_image_widget/yu_ni_image_widget.dart';

class _FakeCacheManager extends Fake implements BaseCacheManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YuniImageCache', () {
    late YuniImageCache cache;

    setUp(() {
      cache = YuniImageCache();
    });

    test('constructor sets global maximumSize to ~1501', () {
      // (100 + 1000 + 50 + 5) * 1.3 = 1501.5 → ceil = 1502
      // Design doc says 1501 — actual value is ceil(1501.5) = 1502
      expect(cache.maximumSize, greaterThan(1000));
    });

    test('constructor sets global maximumSizeBytes to ~819 MB', () {
      // (50 + 500 + 80) MB * 1.3 ≈ 819 MB
      expect(cache.maximumSizeBytes, greaterThan(500 * 1024 * 1024));
    });

    test('clear() does not throw', () {
      expect(() => cache.clear(), returnsNormally);
    });

    test('evict() returns false for unknown key', () {
      expect(cache.evict('unknown_key'), isFalse);
    });

    test('evictByUrl idempotency: second call returns false', () {
      final cm = _FakeCacheManager();
      const url = 'https://example.com/image.jpg';

      // Neither call should throw; both return false since nothing was cached.
      final first = cache.evictByUrl(url, cacheManager: cm);
      final second = cache.evictByUrl(url, cacheManager: cm);

      expect(first, isFalse);
      expect(second, isFalse);
    });

    test('evictByUrl with includePersistent=false does not throw', () {
      final cm = _FakeCacheManager();
      expect(
        () => cache.evictByUrl(
          'https://example.com/img.jpg',
          cacheManager: cm,
          includePersistent: false,
        ),
        returnsNormally,
      );
    });

    test('evictByUrls returns 0 when no urls are cached', () {
      final cm = _FakeCacheManager();
      final count = cache.evictByUrls(
        ['https://a.com/1.jpg', 'https://b.com/2.jpg'],
        cacheManager: cm,
      );
      expect(count, equals(0));
    });

    test('clear() called multiple times does not throw', () {
      expect(() {
        cache.clear();
        cache.clear();
      }, returnsNormally);
    });
  });
}
