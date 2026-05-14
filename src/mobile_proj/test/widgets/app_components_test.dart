import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_proj/widgets/app_button.dart';
import 'package:mobile_proj/widgets/app_empty_state.dart';
import 'package:mobile_proj/widgets/app_text_field.dart';

void main() {
  testWidgets('AppButton disables taps while loading', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Save',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(taps, 0);
  });

  testWidgets('AppTextField shows validation messages', (tester) async {
    final key = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: key,
            child: AppTextField(
              label: 'Email',
              validator: (_) => 'Email is required',
            ),
          ),
        ),
      ),
    );

    key.currentState!.validate();
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('AppEmptyState renders title, message, and action', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            icon: Icons.search_off,
            title: 'No results',
            message: 'Try another filter.',
            actionLabel: 'Refresh',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No results'), findsOneWidget);
    expect(find.text('Try another filter.'), findsOneWidget);
    await tester.tap(find.text('Refresh'));
    expect(tapped, isTrue);
  });
}
