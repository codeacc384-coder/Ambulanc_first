import 'package:ambulance_first/core/models/driver_models.dart';
import 'package:ambulance_first/features/driver/presentation/shell/driver_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final driver = DriverProfile(
    id: 'driver-test-id',
    name: 'Kishore',
    phone: '9876543210',
    email: 'driver@example.com',
    licenseNumber: 'DL123456',
    licenseExpiry: '2030-01-01',
    experienceYears: 5,
    supportedCategories: const [],
    currentLocation: '',
    assignedAmbulanceNumber: '',
    status: 'AVAILABLE',
    totalTrips: 0,
    rating: 0,
  );

  testWidgets('driver top bar aligns controls on narrow screens', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final viewport in [const Size(320, 640), const Size(375, 812)]) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: DriverTopBar(driver: driver, onSosTriggered: () {}),
            body: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kishore'), findsOneWidget);
      expect(find.text('AVAILABLE'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
