import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambulance_first/features/driver/presentation/widgets/hud_telemetry_bar.dart';

void main() {
  testWidgets(
    'recalculates ETA when distance remains but telemetry ETA is zero',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HudTelemetryBar(speedKmh: 0, etaMinutes: 0, remainingKm: 14),
          ),
        ),
      );

      expect(find.text('30'), findsOneWidget);
    },
  );
}
