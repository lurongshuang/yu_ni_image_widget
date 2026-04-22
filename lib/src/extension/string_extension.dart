import 'dart:convert'; // 用于 UTF-8 编码
import 'package:crypto/crypto.dart';

/// 为 String 添加 md5 扩展方法
extension StringMD5 on String {
  /// 计算当前字符串的 MD5 哈希值（32位小写）
  String get MD5 {
    // 1. 将字符串转为 UTF-8 字节数组
    List<int> bytes = utf8.encode(this);

    // 2. 计算 MD5 哈希
    Digest digest = md5.convert(bytes);

    // 3. 返回 16 进制字符串
    return digest.toString();
  }
}

extension StringExtension on String? {
  bool get isNullOrEmpty {
    return this?.isEmpty ?? true;
  }

  bool get isNotNullOrEmpty {
    return !isNullOrEmpty;
  }
}
