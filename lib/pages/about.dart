import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // 引入新添加的包

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}
class _AboutPageState extends State<AboutPage> {
  PackageInfo _packageInfo = PackageInfo(
    appName: '未知',
    packageName: '未知',
    version: '未知',
    buildNumber: '未知',
  );
  @override
  void initState() {
    super.initState();
    // 在页面初始化时，异步加载应用信息
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final logoWidget = Image.asset(
      'assets/images/logo.png',
      width: 80, // 您可以根据需要调整大小
      height: 80,
    );
    return  Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            logoWidget,
            const SizedBox(height: 16),
            Text(
              _packageInfo.appName, // *** 使用动态获取的应用名称 ***
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // *** 使用动态获取的版本号和构建号 ***
            Text(
              '版本: ${_packageInfo.version} (Build ${_packageInfo.buildNumber})',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text('一个基于 Flutter 和 N_m3u8DL-RE 构建的桌面应用。'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                showLicensePage(
                  context: context,
                  applicationName: _packageInfo.appName,
                  applicationVersion: _packageInfo.version,
                  applicationIcon:  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Image.asset('assets/images/logo.png', width: 48),
                  ),
                );
              },
              child: const Text('查看开源许可'),
            ),
          ],
        ),
      ),
    );
  }
}