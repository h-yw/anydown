import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:anydown/utils/settings_service.dart';

class SettingsPage extends StatefulWidget {
  final AppSettings settings;
  const SettingsPage({Key? key, required this.settings}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _threadController;
  late TextEditingController _retryController;
  late TextEditingController _proxyController;
  late TextEditingController _headersController;

  // --- 新增 Controller ---
  late TextEditingController _timeoutController;
  late TextEditingController _maxSpeedController;
  late TextEditingController _keyFileController;
  late TextEditingController _tmpDirController;

  @override
  void initState() {
    super.initState();
    // 初始化控制器，并用当前设置填充
    _threadController = TextEditingController(text: widget.settings.threadCount.toString());
    _retryController = TextEditingController(text: widget.settings.retryCount.toString());
    _proxyController = TextEditingController(text: widget.settings.customProxy);
    _headersController = TextEditingController(text: widget.settings.customHeaders);

    _timeoutController = TextEditingController(text: widget.settings.httpRequestTimeout.toString());
    _maxSpeedController = TextEditingController(text: widget.settings.maxSpeed);
    _keyFileController = TextEditingController(text: widget.settings.keyTextFile);
    _tmpDirController = TextEditingController(text: widget.settings.tmpDir);

  }

  @override
  void dispose() {
    // 保存设置并释放控制器
    _saveSettings();
    _threadController.dispose();
    _retryController.dispose();
    _proxyController.dispose();
    _headersController.dispose();
    // --- 释放新增 Controller ---
    _timeoutController.dispose();
    _maxSpeedController.dispose();
    _keyFileController.dispose();
    _tmpDirController.dispose();

    super.dispose();
  }

  void _saveSettings() {
    widget.settings.threadCount = int.tryParse(_threadController.text) ?? 16;
    widget.settings.retryCount = int.tryParse(_retryController.text) ?? 3;
    widget.settings.customProxy = _proxyController.text.trim();
    widget.settings.customHeaders = _headersController.text.trim();
    // --- 保存新增设置 ---
    widget.settings.httpRequestTimeout = int.tryParse(_timeoutController.text) ?? 100;
    widget.settings.maxSpeed = _maxSpeedController.text.trim();
    widget.settings.keyTextFile = _keyFileController.text.trim();
    widget.settings.tmpDir = _tmpDirController.text.trim();


    // 对于 Switch 和 Dropdown，值已经在 onChanged 中直接更新了 widget.settings
    widget.settings.saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('全局设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _saveSettings();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('设置已保存！'),
                duration: Duration(seconds: 2),
              ));
            },
            tooltip: '保存设置',
          ),
          const SizedBox(width: 8), // 增加一点边距
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCategoryTitle('下载设置'),
          _buildTextField('下载线程数', _threadController, '默认: 16', keyboardType: TextInputType.number),
          _buildTextField('分片下载重试次数', _retryController, '默认: 3', keyboardType: TextInputType.number),
          _buildSwitchTile('并发下载音视频字幕', widget.settings.concurrentDownload, (val) {
            setState(() => widget.settings.concurrentDownload = val);
          }),
          _buildDirectoryPicker(
            '临时文件目录 (可选)',
            _tmpDirController,
            '将临时分片文件存放到指定目录',
          ),
          _buildSwitchTile('完成后删除临时文件', widget.settings.deleteAfterDone, (val) {
            setState(() => widget.settings.deleteAfterDone = val);
          }),

          _buildCategoryTitle('网络设置'),
          _buildTextField('HTTP请求超时(秒)', _timeoutController, '默认: 100', keyboardType: TextInputType.number),
          _buildTextField('全局限速', _maxSpeedController, '例如: 10M 或 500K'),
          _buildSwitchTile('使用系统代理', widget.settings.useSystemProxy, (val) {
            setState(() => widget.settings.useSystemProxy = val);
          }),
          _buildTextField('自定义代理', _proxyController, '例如: http://127.0.0.1:8888'),
          _buildTextField('自定义请求头', _headersController, '格式: key:value;key2:value2'),

          _buildCategoryTitle('文件与合并'),
          _buildSwitchTile('完成后删除临时文件', widget.settings.deleteAfterDone, (val) {
            setState(() => widget.settings.deleteAfterDone = val);
          }),
          _buildSwitchTile('二进制合并', widget.settings.binaryMerge, (val) {
            setState(() => widget.settings.binaryMerge = val);
          }),
          _buildSwitchTile('跳过合并分片', widget.settings.skipMerge, (val) {
            setState(() => widget.settings.skipMerge = val);
          }),
          _buildSwitchTile('混流时不写入日期信息', widget.settings.noDateInfo, (val) {
            setState(() => widget.settings.noDateInfo = val);
          }),

          _buildCategoryTitle('字幕设置'),
          _buildDropdown('字幕格式', widget.settings.subtitleFormat, ['SRT', 'VTT'], (val) {
            if (val != null) setState(() => widget.settings.subtitleFormat = val);
          }),
          _buildSwitchTile('自动修正字幕', widget.settings.autoSubtitleFix, (val) {
            setState(() => widget.settings.autoSubtitleFix = val);
          }),

          _buildCategoryTitle('解密设置'),
          _buildDropdown('解密引擎', widget.settings.decryptionEngine, ['MP4DECRYPT', 'SHAKA_PACKAGER', 'FFMPEG'], (val) {
            if (val != null) setState(() => widget.settings.decryptionEngine = val);
          }),
          _buildTextField('全局密钥文件路径', _keyFileController, '例如: C:\\keys.txt'),

          _buildCategoryTitle('高级/调试'),
          _buildDropdown('日志级别', widget.settings.logLevel, ['INFO', 'DEBUG', 'WARN', 'ERROR', 'OFF'], (val) {
            if (val != null) setState(() => widget.settings.logLevel = val);
          }),
          _buildSwitchTile('关闭日志文件输出', widget.settings.noLog, (val) {
            setState(() => widget.settings.noLog = val);
          }),
          _buildSwitchTile('输出meta.json文件', widget.settings.writeMetaJson, (val) {
            setState(() => widget.settings.writeMetaJson = val);
          }),
          const SizedBox(height: 80), // 在底部增加一些空间，防止列表内容被FAB遮挡
        ],
      ),
    );
  }
  // --- 新增一个通用的 Dropdown Widget ---
  Widget _buildDropdown(String title, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: title,
          border: const OutlineInputBorder(),
        ),
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
  Widget _buildCategoryTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue)),
  );

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
      keyboardType: keyboardType,
    ),
  );

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
    title: Text(title),
    value: value,
    onChanged: onChanged,
    contentPadding: EdgeInsets.zero,
  );
  // --- 新增一个通用的文件夹选择器 Widget ---
  Widget _buildDirectoryPicker(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () async {
              String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
              if (selectedDirectory != null) {
                controller.text = selectedDirectory;
              }
            },
            tooltip: '选择文件夹',
          ),
        ],
      ),
    );
  }
}