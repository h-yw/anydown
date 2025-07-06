import 'dart:convert';
import 'dart:io';

Future<void> startDownload(String m3u8Url) async {
  // exe 文件的路径
  String downloaderPath = 'assets/downloader/m3u8.exe';

  // 从 README.md 获取的命令行参数
  List<String> args = [
    m3u8Url,
    '--save-dir',
    'downloads', // 保存到 downloads 文件夹
    '--save-name',
    'my_video', // 视频文件名
    '--thread-count',
    '16' // 下载线程数
  ];

  try {
    // 启动进程
    Process process = await Process.start(downloaderPath, args);

    // 监听标准输出
    process.stdout.transform(utf8.decoder).listen((data) {
      print(data); // 在这里处理下载进度等信息
    });

    // 监听错误输出
    process.stderr.transform(utf8.decoder).listen((data) {
      print('Error: $data');
    });

    // 等待进程结束
    int exitCode = await process.exitCode;
    if (exitCode == 0) {
      print('下载成功!');
    } else {
      print('下载失败，退出码: $exitCode');
    }
  } catch (e) {
    print('执行出错: $e');
  }
}