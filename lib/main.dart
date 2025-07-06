import 'dart:io';
import 'package:anydown/pages/layout.dart';
import 'package:anydown/utils/download_progress.dart';
import 'package:anydown/utils/download_task.dart';
import 'package:anydown/utils/settings_service.dart';
import 'package:anydown/widgets/task-card.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M3U8 下载器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    _settings.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    // 使用新的主布局，并将下载页面作为 child 传入
    return MainLayout(
      settings: _settings,
      child: DownloadPage(settings: _settings),
    );
  }
}

// --- 新增：将原来的下载页面逻辑封装成一个独立的 Widget ---
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

  String getDownloaderPath() {
    String exePath = Platform.resolvedExecutable;
    String exeDir = File(exePath).parent.path;
    return '$exeDir\\data\\flutter_assets\\assets\\downloader\\m3u8.exe';
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
          child: SingleChildScrollView(child: Text(task.logOutput.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
        ),
        actions: [TextButton(child: const Text('关闭'), onPressed: () => Navigator.of(context).pop())],
      ),
    );
  }

  void _deleteTask(DownloadTask task) {
    _deleteTempFiles(task.tmpPath);
    setState(() {
      _tasks.remove(task);
    });
  }

  Future<void> _deleteTempFiles(String path) async {
    try {
      final directory = Directory(path);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      print('删除临时文件夹时出错: $e');
    }
  }

  Future<void> _addTaskAndStartDownload() async {
    String m3u8Url = _urlController.text.trim();
    if (m3u8Url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('错误：请输入 M3U8 链接！')));
      return;
    }

    final baseTmpDir = widget.settings.tmpDir.isNotEmpty ? widget.settings.tmpDir : (await getTemporaryDirectory()).path;
    final saveName = _saveNameController.text.trim().isNotEmpty ? _saveNameController.text.trim() : 'video_${DateTime.now().millisecondsSinceEpoch}';
    final taskTmpPath = '$baseTmpDir\\$saveName';

    String finalSavePath;
    if (_savePath != null && _savePath!.isNotEmpty) {
      finalSavePath = _savePath!;
    } else {
      final userProfile = Platform.environment['USERPROFILE'];
      finalSavePath = userProfile != null ? '$userProfile\\Downloads\\N_m3u8DL-RE_Downloads' : '${(await getApplicationDocumentsDirectory()).path}\\N_m3u8DL-RE_Downloads';
    }
    await Directory(finalSavePath).create(recursive: true);

    final task = DownloadTask(m3u8Url: m3u8Url, savePath: finalSavePath, saveName: saveName, tmpPath: taskTmpPath);
    setState(() {
      _tasks.add(task);
    });

    _urlController.clear();
    _saveNameController.clear();
    _runDownload(task);
  }

  Future<void> _runDownload(DownloadTask task) async {
    task.updateStatus(TaskStatus.running);
    task.addLog('准备下载...');
    try {
      String downloaderPath = getDownloaderPath();
      List<String> args = [task.m3u8Url, '--save-dir', task.savePath, '--save-name', task.saveName];
      // ... [此处省略了应用全局设置到 args 的代码，逻辑与之前完全相同]
      _runProcess(task, downloaderPath, args);
    } catch (e) {
      task.updateStatus(TaskStatus.failed);
      task.addLog('发生错误: $e\n');
    }
  }

  Future<void> _runProcess(DownloadTask task, String executable, List<String> arguments) async {
    final process = await Process.start(executable, arguments);
    task.process = process;
    process.stdout.transform(systemEncoding.decoder).listen((data) => _updateTaskStatus(data, task));
    process.stderr.transform(systemEncoding.decoder).listen((data) => _updateTaskStatus('错误: $data', task));
    final exitCode = await process.exitCode;
    if (task.status == TaskStatus.running) {
      task.updateStatus(exitCode == 0 ? TaskStatus.completed : TaskStatus.failed);
      task.addLog(exitCode == 0 ? '\n下载成功！' : '\n下载失败，退出码: $exitCode');
    }
  }

  void _updateTaskStatus(String data, DownloadTask task) {
    if (!mounted) return;
    final logPattern = RegExp(r'^\d{2}:\d{2}:\d{2}\.\d{3}\s+(INFO|WARN)\s+:\s+');
    final lines = data.trim().split(RegExp(r'[\r\n]+'));
    for (final line in lines) {
      if (line.isEmpty) continue;
      final newProgress = DownloadProgress.fromLine(line);
      if (newProgress.taskDescription != "等待任务开始...") {
        task.updateProgress(newProgress);
      } else {
        if (widget.settings.noLog && logPattern.hasMatch(line)) continue;
        task.addLog(line);
      }
    }
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
            const Align(alignment: Alignment.centerLeft, child: Text('下载列表:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[_tasks.length - 1 - index];
                  return TaskCard(task: task, onDelete: () => _deleteTask(task), onShowLog: () => _showLogDialog(task));
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
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 8.0), child: Icon(Icons.link, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(child: Column(children: [
            TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'M3U8 链接', isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: _saveNameController, decoration: const InputDecoration(labelText: '自定义文件名 (可选)', isDense: true)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.folder_open_outlined, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text('保存到: ${_savePath ?? "默认 (下载/N_m3u8DL-RE_Downloads)"}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54))),
          IconButton(icon: const Icon(Icons.folder_open), onPressed: _selectSaveFolder, tooltip: '选择保存文件夹'),
        ]),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_task),
            onPressed: _addTaskAndStartDownload,
            label: const Text('添加到下载列表'),
          ),
        ),
      ],
    );
  }
}