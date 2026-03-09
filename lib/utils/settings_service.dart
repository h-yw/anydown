import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

// 用于设置的数据模型
class AppSettings extends ChangeNotifier {
  late SharedPreferences _prefs;

  // 下载设置
  int threadCount = 16;
  int retryCount = 3;
  String tmpDir = ''; // 临时文件目录
  String defaultSavePath = ''; // 默认保存目录 (持久化)
  String ffmpegPath = ''; // FFmpeg 可执行文件路径
  bool autoSelect = true; // 自动选择所有类型的最佳轨道
  String muxFormat = 'mp4'; // 混流容器格式
  String savePattern = ''; // 文件名命名模板
  bool appendUrlParams = false; // 将 Url Params 添加至分片
  bool checkSegmentsCount = true; // 检测分片数量匹配

  // 文件设置
  bool deleteAfterDone = true;
  bool binaryMerge = false;

  // 网络设置
  bool useSystemProxy = true;
  String customProxy = '';
  String customHeaders = ''; // 以 key:value;key2:value2 的形式存储


  // 高级网络
  int httpRequestTimeout = 100;
  String maxSpeed = ''; // 存储字符串，如 "10M" 或 "500K"

  // 字幕设置
  String subtitleFormat = 'SRT'; // 'SRT' 或 'VTT'
  bool autoSubtitleFix = true;

  // 解密设置
  String keyTextFile = '';
  String decryptionEngine = 'MP4DECRYPT';

  // 高级/调试设置
  bool skipMerge = false;
  bool noDateInfo = false;
  bool noLog = false;
  bool writeMetaJson = true;
  bool concurrentDownload = false;
  String logLevel = 'INFO';

  AppSettings();

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    // 已有设置
    threadCount = _prefs.getInt('threadCount') ?? 16;
    retryCount = _prefs.getInt('retryCount') ?? 3;
    deleteAfterDone = _prefs.getBool('deleteAfterDone') ?? true;
    binaryMerge = _prefs.getBool('binaryMerge') ?? false;
    useSystemProxy = _prefs.getBool('useSystemProxy') ?? true;
    customProxy = _prefs.getString('customProxy') ?? '';
    customHeaders = _prefs.getString('customHeaders') ?? '';

    // --- 新加载的设置 ---
    httpRequestTimeout = _prefs.getInt('httpRequestTimeout') ?? 100;
    maxSpeed = _prefs.getString('maxSpeed') ?? '';
    subtitleFormat = _prefs.getString('subtitleFormat') ?? 'SRT';
    autoSubtitleFix = _prefs.getBool('autoSubtitleFix') ?? true;
    keyTextFile = _prefs.getString('keyTextFile') ?? '';
    decryptionEngine = _prefs.getString('decryptionEngine') ?? 'MP4DECRYPT';
    skipMerge = _prefs.getBool('skipMerge') ?? false;
    noDateInfo = _prefs.getBool('noDateInfo') ?? false;
    noLog = _prefs.getBool('noLog') ?? false;
    writeMetaJson = _prefs.getBool('writeMetaJson') ?? true;
    concurrentDownload = _prefs.getBool('concurrentDownload') ?? false;
    logLevel = _prefs.getString('logLevel') ?? 'INFO';
    tmpDir = _prefs.getString('tmpDir') ?? '';
    defaultSavePath = _prefs.getString('defaultSavePath') ?? '';
    ffmpegPath = _prefs.getString('ffmpegPath') ?? '';
    autoSelect = _prefs.getBool('autoSelect') ?? true;
    muxFormat = _prefs.getString('muxFormat') ?? 'mp4';
    savePattern = _prefs.getString('savePattern') ?? '';
    appendUrlParams = _prefs.getBool('appendUrlParams') ?? false;
    checkSegmentsCount = _prefs.getBool('checkSegmentsCount') ?? true;

    notifyListeners();
  }

  Future<void> saveSettings() async {
    // 已有设置
    await _prefs.setInt('threadCount', threadCount);
    await _prefs.setInt('retryCount', retryCount);
    await _prefs.setBool('deleteAfterDone', deleteAfterDone);
    await _prefs.setBool('binaryMerge', binaryMerge);
    await _prefs.setBool('useSystemProxy', useSystemProxy);
    await _prefs.setString('customProxy', customProxy);
    await _prefs.setString('customHeaders', customHeaders);

    // --- 新保存的设置 ---
    await _prefs.setInt('httpRequestTimeout', httpRequestTimeout);
    await _prefs.setString('maxSpeed', maxSpeed);
    await _prefs.setString('subtitleFormat', subtitleFormat);
    await _prefs.setBool('autoSubtitleFix', autoSubtitleFix);
    await _prefs.setString('keyTextFile', keyTextFile);
    await _prefs.setString('decryptionEngine', decryptionEngine);
    await _prefs.setBool('skipMerge', skipMerge);
    await _prefs.setBool('noDateInfo', noDateInfo);
    await _prefs.setBool('noLog', noLog);
    await _prefs.setBool('writeMetaJson', writeMetaJson);
    await _prefs.setBool('concurrentDownload', concurrentDownload);
    await _prefs.setString('logLevel', logLevel);
    await _prefs.setString('tmpDir', tmpDir);
    await _prefs.setString('defaultSavePath', defaultSavePath);
    await _prefs.setString('ffmpegPath', ffmpegPath);
    await _prefs.setBool('autoSelect', autoSelect);
    await _prefs.setString('muxFormat', muxFormat);
    await _prefs.setString('savePattern', savePattern);
    await _prefs.setBool('appendUrlParams', appendUrlParams);
    await _prefs.setBool('checkSegmentsCount', checkSegmentsCount);


    notifyListeners();
  }
}