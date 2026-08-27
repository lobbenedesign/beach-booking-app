// Basic smoke test: the app boots to the login screen when no user is
// authenticated, and renders without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beach_booking/main.dart';

void main() {
  testWidgets('App boots and shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BeachBookingApp());
    await tester.pumpAndSettle();

    // Unauthenticated on launch -> redirected to /login.
    expect(find.byType(TextField), findsWidgets);
  });
}
