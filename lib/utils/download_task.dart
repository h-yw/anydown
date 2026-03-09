import 'dart:io';
import 'package:anydown/utils/download_progress.dart';
import 'package:flutter/material.dart';

// 定义下载任务的几种主要状态
enum TaskStatus { queued, running, completed, failed, canceled }

// 定义任务执行的具体阶段，用于更细粒度的进度展示
enum TaskStage { 
  none,       // 无 
  analyzing,  // 正在解析媒体信息
  downloading,// 正在下载分片
  merging,    // 正在合并/转换格式
  completing  // 正在完成清理
}

// DownloadTask 类，用于封装单个下载任务的所有信息
class DownloadTask extends ChangeNotifier {
  final String id; // 每个任务的唯一标识
  final String m3u8Url;
  final String savePath;
  String saveName; // 改为可变，以支持动态更新最终文件名
  final String tmpPath; // <-- 新增：存储此任务的临时文件夹路径


  TaskStatus status = TaskStatus.queued;
  TaskStage stage = TaskStage.none; // <-- 新增阶段跟踪
  DownloadProgress progress = DownloadProgress();
  StringBuffer logOutput = StringBuffer(); // 使用 StringBuffer 以提高性能
  Process? process; // 用于控制和取消进程
  bool isCleaningUp = false; // <-- 新增：标记是否正在进行清理操作

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

  // 更新阶段
  void updateStage(TaskStage newStage) {
    if (stage != newStage) {
      stage = newStage;
      notifyListeners();
    }
  }

  // 更新保存文件名（例如解析出真实标题后）
  void updateSaveName(String newName) {
    if (saveName != newName) {
      saveName = newName;
      notifyListeners();
    }
  }

  // 更新状态
  void updateStatus(TaskStatus newStatus) {
    status = newStatus;
    // 如果状态变为完成，强制设置阶段为 none
    if (status == TaskStatus.completed) {
      stage = TaskStage.none;
    }
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