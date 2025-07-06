import 'dart:io';
import 'package:anydown/utils/download_progress.dart';
import 'package:flutter/material.dart';

// 定义下载任务的几种状态
enum TaskStatus { queued, running, completed, failed, canceled }

// DownloadTask 类，用于封装单个下载任务的所有信息
class DownloadTask extends ChangeNotifier {
  final String id; // 每个任务的唯一标识
  final String m3u8Url;
  final String savePath;
  final String saveName;
  final String tmpPath; // <-- 新增：存储此任务的临时文件夹路径


  TaskStatus status = TaskStatus.queued;
  DownloadProgress progress = DownloadProgress();
  StringBuffer logOutput = StringBuffer(); // 使用 StringBuffer 以提高性能
  Process? process; // 用于控制和取消进程

  DownloadTask({
    required this.m3u8Url,
    required this.savePath,
    required this.saveName,
    required this.tmpPath, // <-- 新增：在构造时传入

  }) : id = UniqueKey().toString(); // 自动生成唯一ID

  // 更新进度
  void updateProgress(DownloadProgress newProgress) {
    progress = newProgress;
    notifyListeners(); // 通知UI更新
  }

  // 追加日志
  void addLog(String log) {
    logOutput.writeln(log);
    notifyListeners(); // 通知UI更新
  }

  // 更新状态
  void updateStatus(TaskStatus newStatus) {
    status = newStatus;
    notifyListeners(); // 通知UI更新
  }

  // 取消下载任务
  void cancel() {
    if (process != null) {
      process!.kill(); // 强制结束进程
      updateStatus(TaskStatus.canceled);
      addLog("任务已被用户取消。");
    }
  }
}