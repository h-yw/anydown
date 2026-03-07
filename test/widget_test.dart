import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anydown/main.dart';
import 'package:anydown/utils/settings_service.dart';

void main() {
  testWidgets('应用可以正常启动渲染', (WidgetTester tester) async {
    final settings = AppSettings();
    await tester.pumpWidget(MyApp(settings: settings));

    // 验证核心 UI 元素存在
    expect(find.byIcon(Icons.download), findsOneWidget);
    expect(find.text('下载列表:'), findsOneWidget);
  });
}
