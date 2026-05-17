import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_driving_assistant/main.dart';

void main() {
  testWidgets('Setup Screen render test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DrivingAssistantApp());

    // Verify that our setup screen's main header is present.
    expect(find.text('Where to?'), findsOneWidget);
    expect(find.text('Set your route for AI assistance'), findsOneWidget);
    expect(find.text('STARTING POINT'), findsOneWidget);
    expect(find.text('DESTINATION'), findsOneWidget);
    expect(find.text('START JOURNEY'), findsOneWidget);
  });
}
