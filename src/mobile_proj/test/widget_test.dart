import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_proj/screens/loginscreen.dart';

void main() {
  testWidgets('login screen shows primary auth actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });

  testWidgets('login validates empty credentials', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.tap(find.text('Login').last);
    await tester.pump();

    expect(find.text('Please fill in both fields'), findsOneWidget);
  });
}
