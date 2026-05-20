import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test1/app.dart';

void main() {
  testWidgets('MyApp loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
