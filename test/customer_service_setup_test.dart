import 'package:ambulance_first/core/models/auth_user.dart';
import 'package:ambulance_first/core/models/booking.dart';
import 'package:ambulance_first/roles/customer/screens/book_ambulance_wizard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const user = AuthUser(
  id: 'service-setup-test',
  name: 'Customer Test',
  email: 'customer@example.com',
  phone: '9876543210',
  role: 'CUSTOMER',
);

void main() {
  testWidgets('road and air setup cards are ordered ICU, NICU, Oxygen', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(700, 900);

    await tester.pumpWidget(_wizard());
    _expectSetupOrder(tester);

    await tester.tap(find.text('Air Ambulance'));
    await tester.pumpAndSettle();
    _expectSetupOrder(tester);
  });

  testWidgets(
    'rail offers only ICU and dead body offers both freezer choices',
    (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(700, 900);

      await tester.pumpWidget(_wizard());
      await tester.tap(find.text('Rail Ambulance'));
      await tester.pumpAndSettle();

      expect(find.text('ICU Ambulance'), findsOneWidget);
      expect(find.text('NICU Ambulance'), findsNothing);
      expect(find.text('Oxygen Ambulance'), findsNothing);

      await tester.tap(find.text('Dead Body Transfer'));
      await tester.pumpAndSettle();

      expect(find.text('With Freezer'), findsOneWidget);
      expect(find.text('Without Freezer'), findsOneWidget);
      await tester.tap(find.text('Without Freezer'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'dead-body freezer requirement defaults to true for existing bookings',
    () {
      Booking makeBooking({
        String? subtype,
        DeadBodyTransferDetails? details,
        String specialInstructions = '',
      }) {
        return Booking(
          id: 'body-transfer',
          pickup: 'Pickup',
          destination: 'Destination',
          date: '',
          time: '',
          ambulanceType: 'Dead Body Transfer',
          transportMode: 'DEAD_BODY_TRANSFER',
          serviceSubtype: subtype,
          deadBodyDetails: details,
          specialInstructions: specialInstructions,
          status: 'NEW',
          amount: 0,
        );
      }

      expect(makeBooking().deadBodyFreezerRequired, isTrue);
      expect(
        makeBooking(
          specialInstructions: 'Freezer not required for dead body transfer.',
        ).deadBodyFreezerRequired,
        isFalse,
      );
      expect(
        makeBooking(subtype: 'DEAD_BODY_FREEZER').deadBodyFreezerRequired,
        isTrue,
      );
      expect(
        makeBooking(
          subtype: 'DEAD_BODY_NO_FREEZER',
          details: const DeadBodyTransferDetails(freezerRequired: true),
        ).deadBodyFreezerRequired,
        isTrue,
      );
    },
  );
}

Widget _wizard() {
  return MaterialApp(
    home: Scaffold(
      body: BookAmbulanceWizardScreen(
        user: user,
        onBookingCreated: (_) {},
        onCancel: () {},
      ),
    ),
  );
}

void _expectSetupOrder(WidgetTester tester) {
  final positions = [
    tester.getTopLeft(find.text('ICU Ambulance')),
    tester.getTopLeft(find.text('NICU Ambulance')),
    tester.getTopLeft(find.text('Oxygen Ambulance')),
  ];

  for (var index = 0; index < positions.length - 1; index++) {
    final current = positions[index];
    final next = positions[index + 1];
    expect(
      current.dy < next.dy || (current.dy == next.dy && current.dx < next.dx),
      isTrue,
    );
  }
}
