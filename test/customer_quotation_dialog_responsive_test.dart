import 'package:ambulance_first/core/models/booking.dart';
import 'package:ambulance_first/roles/customer/theme/ambulance_first_theme.dart';
import 'package:ambulance_first/roles/customer/widgets/quotation_acceptance_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'quotation dialog fits a short mobile viewport without overflow',
    (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 498);

      final booking = Booking(
        id: 'BK-2026-000000000001',
        pickup: 'Long pickup address, Bengaluru, Karnataka',
        destination: 'Long destination hospital, Whitefield, Bengaluru',
        date: 'Today',
        time: 'Immediate',
        ambulanceType: 'Advanced Life Support ICU Ambulance',
        status: 'QUOTATION_SENT',
        amount: 18277.09,
        patientName: 'Patient Name',
        patientAge: 42,
        patientGender: 'Female',
        distanceKm: 18.5,
        quotation: Quotation(
          id: 'Q-BK-2026-000000000001',
          status: 'SENT',
          baseAmbulanceCharge: 4500,
          distanceCharge: 1200,
          doctorCharge: 900,
          emtCharge: 600,
          oxygenCharge: 250,
          icuCharge: 800,
          ventilatorCharge: 500,
          equipmentCharge: 300,
          attendantCharge: 200,
          additionalCharges: 100,
          discount: 0,
          taxPercent: 5,
          paymentTerms: 'Patient transport charges payable on completion',
          validUntil: '24 hours',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AmbulanceFirstTheme.lightTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => QuotationAcceptanceDialog.show(
                    context,
                    booking: booking,
                    onConfirmAcceptance: () async {},
                    onConfirmRejection: (_) async {},
                  ),
                  child: const Text('Open quotation'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open quotation'));
      await tester.pumpAndSettle();

      final dialog = find.byType(Dialog);
      final dialogRect = tester.getRect(dialog);
      expect(dialogRect.left, greaterThanOrEqualTo(0));
      expect(dialogRect.right, lessThanOrEqualTo(320));
      expect(dialogRect.top, greaterThanOrEqualTo(0));
      expect(dialogRect.bottom, lessThanOrEqualTo(498));

      final confirm = find.text('CONFIRM ACCEPTANCE');
      expect(confirm, findsOneWidget);
      expect(
        tester.getRect(confirm).bottom,
        lessThanOrEqualTo(dialogRect.bottom),
      );

      await tester.drag(
        find.descendant(
          of: dialog,
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(0, -240),
      );
      await tester.pumpAndSettle();

      expect(confirm, findsOneWidget);
      expect(
        tester.getRect(confirm).bottom,
        lessThanOrEqualTo(dialogRect.bottom),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(440, 956);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open quotation'));
      await tester.pumpAndSettle();

      final widerDialogRect = tester.getRect(dialog);
      expect(widerDialogRect.left, greaterThanOrEqualTo(0));
      expect(widerDialogRect.right, lessThanOrEqualTo(440));
      expect(widerDialogRect.bottom, lessThanOrEqualTo(956));
      expect(tester.takeException(), isNull);
    },
  );
}
