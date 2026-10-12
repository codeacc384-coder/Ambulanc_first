import 'package:ambulance_first/core/models/auth_user.dart';
import 'package:ambulance_first/roles/customer/screens/book_ambulance_wizard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = AuthUser(
  id: 'condition-autocomplete-test',
  name: 'Customer Test',
  email: 'customer@example.com',
  phone: '9876543210',
  role: 'CUSTOMER',
);

void main() {
  testWidgets('accepts a custom condition that is not in the list', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 900);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookAmbulanceWizardScreen(
            user: _user,
            onBookingCreated: (_) {},
            onCancel: () {},
          ),
        ),
      ),
    );

    await _continue(tester);
    await _continue(tester);

    final patientFields = find.byType(TextFormField);
    await tester.ensureVisible(patientFields.first);
    await tester.enterText(patientFields.first, 'Patient Example');
    await tester.enterText(patientFields.at(1), '35');

    final gender = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(gender);
    await tester.tap(gender);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female').last);
    await tester.pumpAndSettle();

    final conditionField = find.descendant(
      of: find.byType(Autocomplete<String>),
      matching: find.byType(TextFormField),
    );
    await tester.ensureVisible(conditionField);
    await tester.enterText(conditionField, 'Rare metabolic condition');
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Add custom condition: Rare metabolic condition'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rare metabolic condition'), findsOneWidget);
    await _continue(tester);
    expect(find.textContaining('Step 4 of 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _continue(WidgetTester tester) async {
  final button = find.text('CONTINUE');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}
