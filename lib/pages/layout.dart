import 'package:anydown/pages/about.dart';
import 'package:anydown/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/settings_service.dart';
// 我们稍后会创建这个文件

// 用于管理导航状态的 ChangeNotifier
class NavigationState extends ChangeNotifier {
  int _selectedIndex = 0;
  bool _isExtended = false;

  int get selectedIndex => _selectedIndex;
  bool get isExtended => _isExtended;

  void setIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void toggleRail() {
    _isExtended = !_isExtended;
    notifyListeners();
  }
}

class MainLayout extends StatelessWidget {
  final Widget child; // 主内容区的 Widget
  final AppSettings settings;

  const MainLayout({Key? key, required this.child, required this.settings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NavigationState(),
      child: Consumer<NavigationState>(
        builder: (context, navigationState, _) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationState.selectedIndex,
                  onDestinationSelected: (int index) {
                    navigationState.setIndex(index);
                  },
                  extended: navigationState.isExtended,
                  leading: IconButton(
                    icon: Icon(navigationState.isExtended ? Icons.menu_open : Icons.menu),
                    onPressed: () => navigationState.toggleRail(),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.download_outlined),
                      selectedIcon: Icon(Icons.download),
                      label: Text('下载'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('设置'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.info_outline),
                      selectedIcon: Icon(Icons.info),
                      label: Text('关于'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: navigationState.selectedIndex,
                    children: [
                      child, // 下载页面
                      SettingsPage(settings: settings), // 设置页面
                      const AboutPage(), // 关于页面
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}