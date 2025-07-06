// 新增：用于存放进度信息的数据类
class DownloadProgress {
  final String taskDescription; // 任务描述，如 "Vid 1280x536 | 800 Kbps"
  final double percentage;      // 下载百分比 (0.0 到 1.0)
  final String segments;        // 分片进度，如 "25/708"
  final String downloadedSize;  // 已下载大小 (例如 "12.19MB")
  final String totalSize;       // 总大小 (例如 "359.73MB")
  final String speed;           // 下载速度 (例如 "1.66MBps")
  final String eta;             // 预计剩余时间 (例如 "00:03:55")

  DownloadProgress({
    this.taskDescription = "等待任务开始...",
    this.percentage = 0.0,
    this.segments = "0/0",
    this.downloadedSize = '0 B',
    this.totalSize = '0 B',
    this.speed = '0 B/s',
    this.eta = 'N/A',
  });

  // 一个工厂构造函数，用于从 N_m3u8DL-RE 的输出行解析数据
  factory DownloadProgress.fromLine(String line) {
    // 正则表达式，用于匹配进度行
    // Vid 1280x536 | 800 Kbps --- 25/708   3.53% 12.19MB/359.73MB 1.66MBps 00:03:55
    final regExp = RegExp(
      r'^(.*?)\s-+\s(\d+\/\d+)\s+(\d+\.\d{2})%\s+([\d.]+\wB)\/([\d.]+\wB)\s+([\d.]+\wBps)\s+([\d:]+)',
    );

    final match = regExp.firstMatch(line.trim());

    if (match != null) {
      // 成功匹配，提取数据
      final percentage = double.tryParse(match.group(3) ?? '0') ?? 0.0;
      return DownloadProgress(
        taskDescription: match.group(1)?.trim() ?? 'N/A',
        segments: match.group(2) ?? 'N/A',
        percentage: percentage / 100.0, // 转换为 0.0-1.0 范围
        downloadedSize: match.group(4) ?? 'N/A',
        totalSize: match.group(5) ?? 'N/A',
        speed: match.group(6) ?? 'N/A',
        eta: match.group(7) ?? 'N/A',
      );
    }
    // 如果不匹配，返回一个空进度对象
    return DownloadProgress();
  }
}