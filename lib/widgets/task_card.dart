
import 'package:flutter/material.dart';
import '../utils/download_task.dart';

class TaskCard extends StatefulWidget {
  final DownloadTask task;
  final VoidCallback onDelete;
  final VoidCallback onShowLog;

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
    widget.task.addListener(_onTaskUpdate);
  }

  @override
  void dispose() {
    widget.task.removeListener(_onTaskUpdate);
    super.dispose();
  }

  void _onTaskUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.task.progress;
    final status = widget.task.status;

    IconData statusIconData;
    Color statusColor;
    String statusText;

    switch (status) {
      case TaskStatus.running:
        statusIconData = Icons.downloading_rounded;
        statusColor = Colors.blueAccent;
        // 根据阶段显示更细腻的文案
        switch (widget.task.stage) {
          case TaskStage.analyzing:
            statusText = '正在解析媒体...';
            break;
          case TaskStage.merging:
            statusText = '正在合并/转换...';
            break;
          case TaskStage.completing:
            statusText = '正在收尾...';
            break;
          case TaskStage.downloading:
          default:
            statusText = '正在下载...';
        }
        break;
      case TaskStatus.completed:
        statusIconData = Icons.check_circle_rounded;
        statusColor = Colors.green;
        statusText = '已完成';
        break;
      case TaskStatus.failed:
        statusIconData = Icons.error_rounded;
        statusColor = Colors.redAccent;
        statusText = '下载失败';
        break;
      case TaskStatus.canceled:
        statusIconData = Icons.cancel_rounded;
        statusColor = Colors.orangeAccent;
        statusText = '已取消';
        break;
      case TaskStatus.queued:
      default:
        statusIconData = Icons.schedule_rounded;
        statusColor = Colors.grey;
        statusText = '排队中';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIconData, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.task.saveName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.article_outlined),
                        onPressed: widget.onShowLog,
                        tooltip: '查看日志',
                        color: Colors.blueGrey,
                      ),
                      if (status == TaskStatus.running)
                        IconButton(
                          icon: const Icon(Icons.stop_circle_outlined),
                          onPressed: () => widget.task.cancel(),
                          tooltip: '取消下载',
                          color: Colors.redAccent,
                        )
                      else if (status != TaskStatus.queued)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: Colors.redAccent,
                          onPressed: widget.onDelete,
                          tooltip: '删除记录',
                        ),
                    ],
                  ),
                  if (status == TaskStatus.running) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        // 解析或合并阶段显示不确定进度条，除非已有确切百分比
                        value: (widget.task.stage == TaskStage.analyzing || widget.task.stage == TaskStage.merging) 
                                && progress.percentage == 0 
                               ? null 
                               : progress.percentage,
                        minHeight: 8,
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 第一行：分片进度和百分比
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoText(progress.segments, Icons.segment, label: '分片'),
                        Text(
                          '${(progress.percentage * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 第二行：大小对比
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoText('${progress.downloadedSize} / ${progress.totalSize}', Icons.sd_storage_outlined),
                        _buildInfoText(progress.speed, Icons.speed),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 第三行：任务描述和 ETA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildInfoText(progress.taskDescription, Icons.info_outline, isSmall: true)),
                        _buildInfoText(progress.eta, Icons.timer),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoText(String text, IconData icon, {String? label, bool isSmall = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isSmall ? 10 : 13, color: Colors.black45),
        const SizedBox(width: 4),
        if (label != null) ...[
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              color: Colors.black38,
            ),
          ),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}