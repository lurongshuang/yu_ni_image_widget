import 'dart:async';
import 'dart:collection';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:yu_ni_image_widget/src/extension/string_extension.dart';

/// 图片加载任务的优先级。
enum YuniImageLoadPriority {
  /// 高优先级：当前在视口内可见的图片。
  high,

  /// 低优先级：已滑出视口、预加载或后台任务。
  low,
}

/// 单个加载任务。
class _LoadTask {
  _LoadTask({
    required this.url,
    required this.headers,
    required this.cacheManager,
    required this.priority,
    required this.completer,
  });

  final String url;
  final Map<String, String> headers;
  final BaseCacheManager cacheManager;
  YuniImageLoadPriority priority;

  /// 任务完成后通过此 completer 返回文件路径。
  final Completer<String> completer;

  /// 是否已被取消。
  bool cancelled = false;

  /// 取消任务（completer 会以异常结束）。
  void cancel() {
    if (!cancelled && !completer.isCompleted) {
      cancelled = true;
      completer.completeError(
        const _CancelledError(),
        StackTrace.current,
      );
    }
  }
}

/// 任务被取消时抛出的内部异常，Provider 捕获后静默处理。
class _CancelledError implements Exception {
  const _CancelledError();
  @override
  String toString() => '图片加载任务已取消';
}

/// 视口感知的图片加载调度器（单例）。
///
/// 将加载请求分为高优先级（视口内）和低优先级（视口外）两个队列，
/// 分别限制并发数，确保可见图片优先加载。
///
/// **默认关闭**，需要显式开启：
/// ```dart
/// YuniImageLoadScheduler.instance.enabled = true;
/// ```
///
/// ## 使用方式
/// ```dart
/// // 提交加载任务，返回文件路径 Future
/// final future = YuniImageLoadScheduler.instance.submit(
///   url: url,
///   headers: headers,
///   cacheManager: cacheManager,
///   priority: YuniImageLoadPriority.high,
/// );
///
/// // 图片滑出视口时降级
/// YuniImageLoadScheduler.instance.deprioritize(url);
///
/// // 图片销毁时取消（500ms 延迟）
/// YuniImageLoadScheduler.instance.cancelDelayed(url);
/// ```
class YuniImageLoadScheduler {
  YuniImageLoadScheduler._();

  static final instance = YuniImageLoadScheduler._();

  /// 是否启用优先级调度。
  ///
  /// 默认为 `false`，此时所有请求直接透传给 [BaseCacheManager]，行为与未接入调度器相同。
  /// 设为 `true` 后，加载请求进入优先级队列，视口内图片优先占用并发槽位。
  ///
  /// 建议在图片列表页面进入时开启，离开时关闭：
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   YuniImageLoadScheduler.instance.enabled = true;
  /// }
  ///
  /// @override
  /// void dispose() {
  ///   YuniImageLoadScheduler.instance.enabled = false;
  ///   super.dispose();
  /// }
  /// ```
  bool enabled = false;

  /// 高优先级最大并发数。
  static const int _highConcurrency = 6;

  /// 低优先级最大并发数。
  static const int _lowConcurrency = 2;

  /// 滑出视口后延迟取消的时间。
  static const Duration _cancelDelay = Duration(milliseconds: 500);

  // 等待队列（按优先级分开，保持插入顺序）
  final Queue<_LoadTask> _highQueue = Queue();
  final Queue<_LoadTask> _lowQueue = Queue();

  // 正在执行的任务（url → task）
  final Map<String, _LoadTask> _running = {};

  // 当前各优先级正在执行的数量
  int _runningHigh = 0;
  int _runningLow = 0;

  // 待取消的 timer（url → timer）
  final Map<String, Timer> _cancelTimers = {};

  // 所有已知任务（url → task），用于优先级调整
  final Map<String, _LoadTask> _allTasks = {};

  /// 提交一个加载任务。
  ///
  /// 若 [enabled] 为 `false`，直接调用 [BaseCacheManager.getSingleFile]，
  /// 不经过优先级队列。
  ///
  /// 若相同 URL 已有任务在队列或执行中，直接复用并可升级优先级。
  /// 返回一个 Future，resolve 时携带本地文件路径。
  Future<String> submit({
    required String url,
    required Map<String, String> headers,
    required BaseCacheManager cacheManager,
    required YuniImageLoadPriority priority,
  }) async {
    // 调度器未启用时，直接透传，不走队列
    if (!enabled) {
      final file = await cacheManager.getSingleFile(url, headers: headers);
      return file.path;
    }
    // 取消待取消的 timer（重新进入视口）
    _cancelTimers.remove(url)?.cancel();

    // 已有任务：复用并尝试升级优先级
    final existing = _allTasks[url];
    if (existing != null && !existing.cancelled) {
      if (priority == YuniImageLoadPriority.high &&
          existing.priority == YuniImageLoadPriority.low) {
        _upgradeToHigh(existing);
      }
      return existing.completer.future;
    }

    // 新建任务
    final task = _LoadTask(
      url: url,
      headers: headers,
      cacheManager: cacheManager,
      priority: priority,
      completer: Completer<String>(),
    );
    _allTasks[url] = task;

    if (priority == YuniImageLoadPriority.high) {
      _highQueue.addLast(task);
    } else {
      _lowQueue.addLast(task);
    }

    _pump();
    return task.completer.future;
  }

  /// 将 [url] 对应的任务降级为低优先级（滑出视口时调用）。
  void deprioritize(String url) {
    final task = _allTasks[url];
    if (task == null || task.cancelled) return;
    if (task.priority == YuniImageLoadPriority.low) return;

    task.priority = YuniImageLoadPriority.low;

    // 若还在高优先级队列中，移到低优先级队列
    if (_highQueue.remove(task)) {
      _lowQueue.addLast(task);
    }
    // 若已在执行中，不中断，只是标记优先级（下次调度时不再占高优先级槽）
  }

  /// 延迟 500ms 后取消 [url] 对应的任务（组件 dispose 时调用）。
  /// 调度器未启用时此方法无效。
  void cancelDelayed(String url) {
    if (!enabled) return;
    _cancelTimers[url]?.cancel();
    _cancelTimers[url] = Timer(_cancelDelay, () {
      _cancelTimers.remove(url);
      _cancel(url);
    });
  }

  /// 立即取消 [url] 对应的任务。
  void _cancel(String url) {
    final task = _allTasks.remove(url);
    if (task == null) return;
    _highQueue.remove(task);
    _lowQueue.remove(task);
    task.cancel();
  }

  /// 将任务从低优先级升级到高优先级。
  void _upgradeToHigh(_LoadTask task) {
    task.priority = YuniImageLoadPriority.high;
    _lowQueue.remove(task);
    // 插到高优先级队列头部，尽快执行
    _highQueue.addFirst(task);
    _pump();
  }

  /// 调度循环：尽可能填满并发槽位。
  void _pump() {
    // 先填高优先级槽
    while (_runningHigh < _highConcurrency && _highQueue.isNotEmpty) {
      final task = _highQueue.removeFirst();
      if (task.cancelled) continue;
      _runningHigh++;
      _execute(task, isHigh: true);
    }

    // 再填低优先级槽
    while (_runningLow < _lowConcurrency && _lowQueue.isNotEmpty) {
      final task = _lowQueue.removeFirst();
      if (task.cancelled) continue;
      _runningLow++;
      _execute(task, isHigh: false);
    }
  }

  /// 执行单个任务。
  void _execute(_LoadTask task, {required bool isHigh}) {
    _running[task.url] = task;

    task.cacheManager
        .getSingleFile(task.url, key: task.url.MD5, headers: task.headers)
        .then((file) {
      if (!task.cancelled && !task.completer.isCompleted) {
        task.completer.complete(file.path);
      }
    }).catchError((Object e, StackTrace st) {
      if (!task.cancelled && !task.completer.isCompleted) {
        task.completer.completeError(e, st);
      }
    }).whenComplete(() {
      _running.remove(task.url);
      _allTasks.remove(task.url);
      if (isHigh) {
        _runningHigh--;
      } else {
        _runningLow--;
      }
      _pump();
    });
  }
}

/// 对外暴露的取消异常类型，Provider 可以用来静默处理取消。
typedef YuniImageCancelledError = _CancelledError;
