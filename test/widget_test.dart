import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carmen_goudie/app.dart';

void main() {
  testWidgets('MyApp loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
