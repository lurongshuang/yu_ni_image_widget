import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:yu_ni_image_widget/src/provider/yuni_remote_image_provider.dart';
import 'package:yu_ni_image_widget/src/provider/yuni_persistent_remote_image_provider.dart';
import 'package:yu_ni_image_widget/src/provider/yuni_local_image_provider.dart';

class _FakeCacheManager extends Fake implements BaseCacheManager {}

void main() {
  group('YuniRemoteImageProvider', () {
    test('equality is based only on url', () {
      final cm1 = _FakeCacheManager();
      final cm2 = _FakeCacheManager();
      final p1 = YuniRemoteImageProvider(
        url: 'https://a.com/img.jpg',
        cacheManager: cm1,
      );
      final p2 = YuniRemoteImageProvider(
        url: 'https://a.com/img.jpg',
        cacheManager: cm2,
      );
      final p3 = YuniRemoteImageProvider(
        url: 'https://b.com/img.jpg',
        cacheManager: cm1,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });

    test('different headers with same url are equal', () {
      final cm = _FakeCacheManager();
      final p1 = YuniRemoteImageProvider(
        url: 'https://a.com/img.jpg',
        cacheManager: cm,
        headers: {'Authorization': 'Bearer token1'},
      );
      final p2 = YuniRemoteImageProvider(
        url: 'https://a.com/img.jpg',
        cacheManager: cm,
        headers: {'Authorization': 'Bearer token2'},
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });

  group('YuniPersistentRemoteImageProvider', () {
    test('equality is based only on url', () {
      final cm1 = _FakeCacheManager();
      final cm2 = _FakeCacheManager();
      final p1 = YuniPersistentRemoteImageProvider(
        url: 'https://a.com/img.jpg',
        cacheManager: cm1,
      );
      final p2 = YuniPersistentRemoteImageProvider(
        url: 'https://a.com/img.jpg',
        cacheManager: cm2,
      );
      final p3 = YuniPersistentRemoteImageProvider(
        url: 'https://b.com/img.jpg',
        cacheManager: cm1,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });

    test('is not equal to YuniRemoteImageProvider with same url', () {
      final cm = _FakeCacheManager();
      final remote = YuniRemoteImageProvider(
        url: 'https://a.com/img.jpg',
        cacheManager: cm,
      );
      final persistent = YuniPersistentRemoteImageProvider(
        url: 'https://a.com/img.jpg',
        cacheManager: cm,
      );

      expect(remote, isNot(equals(persistent)));
    });
  });

  group('YuniLocalImageProvider', () {
    test('equality is based only on path', () {
      final p1 = YuniLocalImageProvider(path: '/tmp/img.jpg');
      final p2 = YuniLocalImageProvider(path: '/tmp/img.jpg');
      final p3 = YuniLocalImageProvider(path: '/tmp/other.jpg');

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });

    test('is not equal to a provider with different path', () {
      final p1 = YuniLocalImageProvider(path: '/a/b/c.png');
      final p2 = YuniLocalImageProvider(path: '/a/b/d.png');

      expect(p1, isNot(equals(p2)));
      expect(p1.hashCode, isNot(equals(p2.hashCode)));
    });
  });
}
