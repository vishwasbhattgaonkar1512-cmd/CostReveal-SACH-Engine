import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:costreveal_sach_engine/main.dart';
import 'package:costreveal_sach_engine/state/app_state.dart';

void main() {
  testWidgets('CostReveal App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build our app with required providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the initial screen text is found.
    // We look for stable UI elements on the InputScreen.

    expect(find.text('Manual entry'), findsOneWidget);
    
    // Smoke check passed: The app pumps without errors and renders initial UI.
  });
}
