import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_life_os/core/theme/app_theme.dart';

void main() {
  testWidgets('light theme applies scaffold background color', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(child: Text('AI Life OS')),
        ),
      ),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.scaffoldBackgroundColor, AppTheme.lightBg);
    expect(find.text('AI Life OS'), findsOneWidget);
  });
}
