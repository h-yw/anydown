/// 用于存放进度信息的数据类
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

  /// 从 N_m3u8DL-RE 的输出行解析进度数据
  /// 示例格式:
  ///   Vid 1280x536 | 800 Kbps --- 25/708   3.53% 12.19MB/359.73MB 1.66MBps 00:03:55
  ///   Aud 48000Hz | 128 Kbps --- 10/100  10.00% 1.20MB/12.00MB 0.50MBps 00:00:22
  factory DownloadProgress.fromLine(String line) {
    // 为了兼容剥离 ANSI 码后的格式：
    // Vid Kbps ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 1/582 0.17% 229.49KB/130.43MB 229.41KBps 00:09:41
    // 需要极其宽松地匹配中间的各种可能的进度条字符（包括全角横线、方块等），直到遇到 M/N 的分片格式
    final regExp = RegExp(
      r'(.*?)\s+'           // 任务描述
      r'[*━─═\|█▓░\s]+'     // 匹配各种进度条字符和空格
      r'(\d+/\d+)\s+'       // 分片进度 (如 25/708)
      r'([\d.]+)%\s+'       // 百分比 (如 3.53%)
      r'([\d.]+\s*\w*B|\-)\s*/\s*([\d.]+\s*\w*B|\-)\s+' // 已下载大小 / 总大小 (可能为 -)
      r'([\d.]+\s*\w*Bps|\-)\s+' // 速度 (可能为 -)
      r'([\d:\-]+)',         // 预计时间 (可能为 --:--:--)
    );

    final match = regExp.firstMatch(line.trim());

    if (match != null) {
      final percentage = double.tryParse(match.group(3) ?? '0') ?? 0.0;
      return DownloadProgress(
        taskDescription: match.group(1)?.trim() ?? 'N/A',
        segments: match.group(2) ?? 'N/A',
        percentage: percentage / 100.0,
        downloadedSize: match.group(4) ?? 'N/A',
        totalSize: match.group(5) ?? 'N/A',
        speed: match.group(6) ?? 'N/A',
        eta: match.group(7) ?? 'N/A',
      );
    }
    return DownloadProgress();
  }
}