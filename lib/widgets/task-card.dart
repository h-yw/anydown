
// --- 新增：用于显示单个任务信息的卡片 Widget ---
import 'package:flutter/material.dart';
import '../utils/download_task.dart'; // 引入新的任务类
class TaskCard extends StatefulWidget {
  final DownloadTask task;
  final VoidCallback onDelete; // 新增：删除任务的回调函数
  final VoidCallback onShowLog; // 新增：显示日志的回调函数

  const TaskCard({
    Key? key,
    required this.task,
    required this.onDelete,
    required this.onShowLog,
  }) : super(key: key);

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  @override
  void initState() {
    super.initState();
    // 监听任务的变化，当任务状态更新时，重绘这个卡片
    widget.task.addListener(_onTaskUpdate);
  }

  @override
  void dispose() {
    // 移除监听，避免内存泄漏
    widget.task.removeListener(_onTaskUpdate);
    super.dispose();
  }

  void _onTaskUpdate() {
    // 调用 setState 来通知 Flutter 重绘这个 Widget
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.task.progress;
    final status = widget.task.status;

    Icon statusIcon;
    Color statusColor;

    switch (status) {
      case TaskStatus.running:
        statusIcon = Icon(Icons.downloading, color: Colors.blue.shade700);
        statusColor = Colors.blue.shade100;
        break;
      case TaskStatus.completed:
        statusIcon = Icon(Icons.check_circle, color: Colors.green.shade700);
        statusColor = Colors.green.shade100;
        break;
      case TaskStatus.failed:
        statusIcon = Icon(Icons.error, color: Colors.red.shade700);
        statusColor = Colors.red.shade100;
        break;
      case TaskStatus.canceled:
        statusIcon = Icon(Icons.cancel, color: Colors.grey.shade700);
        statusColor = Colors.grey.shade300;
        break;
      default:
        statusIcon = Icon(Icons.hourglass_empty, color: Colors.grey.shade700);
        statusColor = Colors.grey.shade300;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: statusColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                statusIcon,
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.task.saveName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // --- 新增：操作按钮区域 ---
                IconButton(
                  icon: const Icon(Icons.subject), // 日志按钮图标
                  onPressed: widget.onShowLog,
                  tooltip: '查看日志',
                ),
                if (status == TaskStatus.running)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => widget.task.cancel(),
                    tooltip: '取消下载',
                  )
                // *** 核心修复：只要任务不是运行中或排队中，就显示删除按钮 ***
                else if (status != TaskStatus.queued)
                  IconButton(
                    icon: const Icon(Icons.delete_forever),
                    color: Colors.red.shade700,
                    onPressed: widget.onDelete,
                    tooltip: '删除此条记录',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (status == TaskStatus.running) ...[
              LinearProgressIndicator(
                value: progress.percentage,
                minHeight: 8,
                // borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(progress.segments, style: const TextStyle(fontSize: 12)),
                  Text('${(progress.percentage * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(progress.speed, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text(progress.eta, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ] else ... [
              Text(
                '状态: ${status.toString().split('.').last}',
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }
}