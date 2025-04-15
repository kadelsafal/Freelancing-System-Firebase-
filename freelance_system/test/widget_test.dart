import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelance_system/main.dart'; // Import your app file

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Create a mock navigator key
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    // Build our app and trigger a frame
    await tester.pumpWidget(
        MyApp(navigatorKey: navigatorKey)); // Pass the navigatorKey here

    // Verify that the counter starts at 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that the counter has incremented
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
