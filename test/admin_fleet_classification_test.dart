import 'package:ambulance_first/roles/admin/screens/admin_fleet_register_screen.dart';
import 'package:ambulance_first/roles/admin/store/admin_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopAdminStore extends AdminStore {
  @override
  Future<void> refresh() async {}
}

void main() {
  testWidgets('Type-B Basic Oxygen registration sets matching capabilities', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);

    final store = _NoopAdminStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminFleetRegisterScreen(store: store, onFinished: () {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Type-B Basic Oxygen (BLS)').last);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Matches BASIC_OXYGEN bookings'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).at(0), 'ECHO-BLS-01');
    await tester.enterText(find.byType(TextField).at(1), 'MED-BLS-01');
    await tester.tap(find.text('Next Step →'));
    await tester.pumpAndSettle();

    final switches = tester.widgetList<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switches.first.value, isTrue);
    expect(switches.skip(1).every((item) => !item.value), isTrue);
    expect(tester.takeException(), isNull);
  });
}
