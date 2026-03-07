import 'package:anydown/pages/layout.dart';
import 'package:anydown/pages/download_page.dart';
import 'package:anydown/utils/settings_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.loadSettings();
  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final AppSettings settings;
  const MyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M3U8 下载器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(settings: settings),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final AppSettings settings;
  const MyHomePage({super.key, required this.settings});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChange);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChange);
    super.dispose();
  }

  void _onSettingsChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      settings: widget.settings,
      child: DownloadPage(settings: widget.settings),
    );
  }
}