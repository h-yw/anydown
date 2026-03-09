import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'download_progress.dart';
import 'download_task.dart';
import 'settings_service.dart';

/// 下载服务：封装下载器路径解析、参数构建、进程管理等业务逻辑
class DownloadService {
  final AppSettings settings;
  String? _cachedDownloaderPath;

  DownloadService({required this.settings});

  /// 准备并获取下载器可执行文件路径
  /// 从 Flutter assets 提取到可写目录，避免 sandbox 权限问题
  Future<String> getDownloaderPath() async {
    if (_cachedDownloaderPath != null && File(_cachedDownloaderPath!).existsSync()) {
      return _cachedDownloaderPath!;
    }

    final directory = await getApplicationSupportDirectory();
    final fileName = Platform.isWindows ? 'm3u8.exe' : 'm3u8';
    final targetPath = p.join(directory.path, 'bin', fileName);
    final targetFile = File(targetPath);

    // 如果文件不存在，从 assets 提取
    if (!await targetFile.exists()) {
      await targetFile.create(recursive: true);
      final assetName = Platform.isWindows ? 'assets/downloader/m3u8.exe' : 'assets/downloader/m3u8';
      final data = await rootBundle.load(assetName);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await targetFile.writeAsBytes(bytes);
    }

    // macOS/Linux 上赋予执行权限
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', targetPath]);
    }

    _cachedDownloaderPath = targetPath;
    return targetPath;
  }

  /// 计算默认保存路径
  Future<String> getDefaultSavePath() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      return userProfile != null
          ? '$userProfile\\Downloads\\N_m3u8DL-RE_Downloads'
          : '${(await getApplicationDocumentsDirectory()).path}\\N_m3u8DL-RE_Downloads';
    } else {
      final home = Platform.environment['HOME'];
      return home != null
          ? '$home/Downloads/N_m3u8DL-RE_Downloads'
          : '${(await getApplicationDocumentsDirectory()).path}/N_m3u8DL-RE_Downloads';
    }
  }

  /// 计算任务的临时文件路径
  Future<String> getTaskTmpPath(String saveName) async {
    final baseTmpDir = settings.tmpDir.isNotEmpty
        ? settings.tmpDir
        : (await getTemporaryDirectory()).path;
    return '$baseTmpDir${Platform.pathSeparator}$saveName';
  }

  /// 按照 N_m3u8DL-RE 官方 CLI 文档构建命令行参数
  List<String> buildArguments(DownloadTask task) {
    final args = <String>[
      task.m3u8Url,
      '--save-dir', task.savePath,
      '--save-name', task.saveName,
      '--tmp-dir', task.tmpPath,
      '--thread-count', settings.threadCount.toString(),
      '--download-retry-count', settings.retryCount.toString(),
      '--force-ansi-console', // 强制输出实时进度（非 tty 环境下必须）
      '--no-ansi-color',      // 去掉颜色码方便解析
    ];

    // 网络设置
    if (settings.httpRequestTimeout != 100) {
      args.addAll(['--http-request-timeout', settings.httpRequestTimeout.toString()]);
    }
    if (settings.maxSpeed.isNotEmpty) {
      args.addAll(['-R', settings.maxSpeed]);
    }
    if (settings.customProxy.isNotEmpty) {
      args.addAll(['--custom-proxy', settings.customProxy]);
    }

    // 请求头：每个 header 需单独传递一次 -H
    if (settings.customHeaders.isNotEmpty) {
      for (final header in settings.customHeaders.split(';')) {
        final trimmed = header.trim();
        if (trimmed.isNotEmpty) {
          args.addAll(['-H', trimmed]);
        }
      }
    }

    // 下载行为
    if (settings.concurrentDownload) args.add('--concurrent-download');
    if (settings.deleteAfterDone) args.add('--del-after-done');
    if (settings.binaryMerge) args.add('--binary-merge');
    if (settings.skipMerge) args.add('--skip-merge');

    // 输出控制
    if (settings.noDateInfo) args.add('--no-date-info');
    if (settings.noLog) args.add('--no-log');

    // 字幕
    if (settings.subtitleFormat != 'SRT') {
      args.addAll(['--sub-format', settings.subtitleFormat]);
    }

    // 解密
    if (settings.keyTextFile.isNotEmpty) {
      args.addAll(['--key-text-file', settings.keyTextFile]);
    }
    if (settings.decryptionEngine != 'MP4DECRYPT') {
      args.addAll(['--decryption-engine', settings.decryptionEngine]);
    }

    // 日志级别
    if (settings.logLevel != 'INFO') {
      args.addAll(['--log-level', settings.logLevel]);
    }

    return args;
  }

  /// 启动下载任务
  Future<void> runDownload(DownloadTask task) async {
    task.updateStatus(TaskStatus.running);
    task.updateStage(TaskStage.analyzing); // 初始阶段：解析中
    task.addLog('准备下载...');
    try {
      final downloaderPath = await getDownloaderPath();
      if (!File(downloaderPath).existsSync()) {
        task.updateStatus(TaskStatus.failed);
        task.addLog('错误：未找到下载器可执行文件于: $downloaderPath');
        return;
      }

      final args = buildArguments(task);
      await _runProcess(task, downloaderPath, args);
    } catch (e) {
      task.updateStatus(TaskStatus.failed);
      task.addLog('发生错误: $e\n');
    }
  }

  Future<void> _runProcess(
      DownloadTask task, String executable, List<String> arguments) async {
    try {
      final process = await Process.start(executable, arguments);
      task.process = process;

      process.stdout.transform(systemEncoding.decoder).listen(
        (data) => _parseOutput(data, task),
      );
      process.stderr.transform(systemEncoding.decoder).listen(
        (data) => _parseOutput('错误: $data', task),
      );

      final exitCode = await process.exitCode;
      
      // 执行额外清理（针对取消或失败的情况，N_m3u8DL-RE 可能没来得及清理）
      if (settings.deleteAfterDone) {
        task.isCleaningUp = true;
        task.updateStage(TaskStage.completing);
        await deleteTempFiles(task.tmpPath);
        task.isCleaningUp = false;
      }

      if (task.status == TaskStatus.running) {
        task.updateStatus(exitCode == 0 ? TaskStatus.completed : TaskStatus.failed);
        task.addLog(exitCode == 0 ? '\n下载成功！' : '\n下载失败，退出码: $exitCode');
      }
    } catch (e) {
      if (task.status != TaskStatus.canceled) {
        task.updateStatus(TaskStatus.failed);
        task.addLog('进程启动失败: $e');
      }
    }
  }

  /// 去除 ANSI 转义序列
  static final _ansiEscape = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]|\x1B\].*?\x07');

  /// 解析下载器输出，更新进度或追加日志
  void _parseOutput(String data, DownloadTask task) {
    final logPattern = RegExp(r'^\d{2}:\d{2}:\d{2}\.\d{3}\s+(INFO|WARN)\s+:\s+');
    
    // 关键阶段识别关键词
    final Map<String, TaskStage> stageKeywords = {
      '正在解析媒体信息': TaskStage.analyzing,
      '开始下载': TaskStage.downloading,
      '开始合并': TaskStage.merging,
      '所有任务已完成': TaskStage.completing,
      '任务已取消': TaskStage.none,
      '下载失败': TaskStage.none,
    };

    // 去除 ANSI 转义码后再解析
    final cleanData = data.replaceAll(_ansiEscape, '');
    final lines = cleanData.trim().split(RegExp(r'[\r\n]+'));
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // 1. 尝试识别阶段切换
      for (final entry in stageKeywords.entries) {
        if (trimmedLine.contains(entry.key)) {
          task.updateStage(entry.value);
          break;
        }
      }

      // 2. 尝试从进度行更新
      final newProgress = DownloadProgress.fromLine(trimmedLine);
      if (newProgress.taskDescription != "等待任务开始...") {
        task.updateProgress(newProgress);
        // 如果能解析到进度，确保阶段是下载中
        if (task.stage == TaskStage.analyzing) {
            task.updateStage(TaskStage.downloading);
        }
      } else {
        // 3. 否则作为常规日志
        if (settings.noLog && logPattern.hasMatch(trimmedLine)) continue;
        task.addLog(trimmedLine);
      }
    }
  }

  /// 删除任务的临时文件
  Future<void> deleteTempFiles(String path) async {
    try {
      final directory = Directory(path);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('删除临时文件夹时出错: $e');
    }
  }
}
