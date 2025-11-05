// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_keyword_recorder/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VoiceKeywordRecorderApp());

    // Verify that our app loads with the correct content.
    expect(find.text('Project structure initialized'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    
    // Verify we have at least one instance of the app title
    expect(find.text('Voice Keyword Recorder'), findsWidgets);
  });
}
