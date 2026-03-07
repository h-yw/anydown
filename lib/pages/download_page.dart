import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/download_service.dart';
import '../utils/download_task.dart';
import '../utils/settings_service.dart';
import '../widgets/task_card.dart';

class DownloadPage extends StatefulWidget {
  final AppSettings settings;
  const DownloadPage({Key? key, required this.settings}) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final List<DownloadTask> _tasks = [];
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _saveNameController = TextEditingController();
  String? _savePath;
  late final DownloadService _downloadService;

  @override
  void initState() {
    super.initState();
    _downloadService = DownloadService(settings: widget.settings);
  }

  Future<void> _selectSaveFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() => _savePath = selectedDirectory);
    }
  }

  void _showLogDialog(DownloadTask task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('任务日志: ${task.saveName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              task.logOutput.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('关闭'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  void _deleteTask(DownloadTask task) {
    _downloadService.deleteTempFiles(task.tmpPath);
    setState(() {
      _tasks.remove(task);
    });
  }

  Future<void> _addTaskAndStartDownload() async {
    String m3u8Url = _urlController.text.trim();
    if (m3u8Url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('错误：请输入 M3U8 链接！')),
      );
      return;
    }

    final saveName = _saveNameController.text.trim().isNotEmpty
        ? _saveNameController.text.trim()
        : 'video_${DateTime.now().millisecondsSinceEpoch}';

    final taskTmpPath = await _downloadService.getTaskTmpPath(saveName);

    String finalSavePath;
    if (_savePath != null && _savePath!.isNotEmpty) {
      finalSavePath = _savePath!;
    } else {
      finalSavePath = await _downloadService.getDefaultSavePath();
    }
    await Directory(finalSavePath).create(recursive: true);

    final task = DownloadTask(
      m3u8Url: m3u8Url,
      savePath: finalSavePath,
      saveName: saveName,
      tmpPath: taskTmpPath,
    );
    setState(() {
      _tasks.add(task);
    });

    _urlController.clear();
    _saveNameController.clear();
    _downloadService.runDownload(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputSection(),
            const Divider(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '下载列表:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[_tasks.length - 1 - index];
                  return TaskCard(
                    task: task,
                    onDelete: () => _deleteTask(task),
                    onShowLog: () => _showLogDialog(task),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.link, color: Colors.blueAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'M3U8 链接',
                      isDense: true,
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _saveNameController,
                    decoration: const InputDecoration(
                      labelText: '自定义文件名 (可选)',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.folder_open_outlined, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '保存到: ${_savePath ?? "默认 (下载/N_m3u8DL-RE_Downloads)"}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.folder_open),
              onPressed: _selectSaveFolder,
              tooltip: '选择保存文件夹',
              color: Colors.blueAccent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_task),
            onPressed: _addTaskAndStartDownload,
            label: const Text('添加到下载列表'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blueAccent,
            ),
          ),
        ),
      ],
    );
  }
}
