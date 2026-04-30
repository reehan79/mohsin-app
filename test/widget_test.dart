// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mohsin_app/main.dart';

void main() {
  testWidgets('Firebase status screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MohsinSpeechPracticeApp(anonymousUid: 'test-uid'),
    );

    expect(find.text('Mohsin Speech Practice'), findsOneWidget);
    expect(find.text('Firebase status: Connected'), findsOneWidget);
    expect(find.text('Anonymous UID: test-uid'), findsOneWidget);
    expect(find.text('Speech MVP setup ready'), findsOneWidget);
  });
}
