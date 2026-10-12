import 'package:ambulance_first/roles/admin/screens/admin_dashboard_screen.dart';
import 'package:ambulance_first/roles/admin/screens/admin_fleet_screen.dart';
import 'package:ambulance_first/roles/admin/screens/admin_fleet_register_screen.dart';
import 'package:ambulance_first/roles/admin/screens/admin_staff_screen.dart';
import 'package:ambulance_first/roles/admin/screens/admin_shell.dart';
import 'package:ambulance_first/roles/admin/store/admin_store.dart';
import 'package:ambulance_first/core/models/auth_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin dashboard lays out at 320px without exceptions', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 498);

    final store = AdminStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminDashboardScreen(
            store: store,
            onOpenBookingDetail: (_) {},
            onNavigateTab: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Revenue & Quotations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin fleet is responsive and touch-scrollable at 320px', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 498);

    final store = AdminStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdminFleetScreen(store: store)),
      ),
    );

    expect(find.text('Fleet Command'), findsOneWidget);
    expect(find.text('TOTAL FLEET'), findsOneWidget);
    expect(find.text('AVAILABLE'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('TOTAL FLEET')).dy,
      tester.getTopLeft(find.text('AVAILABLE').first).dy,
    );

    final verticalScrollView = find
        .descendant(
          of: find.byType(SingleChildScrollView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.drag(verticalScrollView, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(
      tester.state<ScrollableState>(verticalScrollView).position.pixels,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin shell fits common phone, tablet, and desktop widths', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    final user = const AuthUser(
      id: 'admin',
      name: 'Administrator',
      email: 'admin@example.com',
      phone: '',
      role: 'ADMIN',
    );

    for (final width in [280.0, 320.0, 375.0, 440.0, 768.0, 1024.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(user: user, onSignOut: () {}),
        ),
      );
      await tester.pump();

      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason:
            'Admin shell overflowed at $width px: '
            '${exception is FlutterError ? exception.toStringDeep() : exception}',
      );
    }

    tester.view.physicalSize = const Size(280, 800);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminShell(user: user, onSignOut: () {}),
      ),
    );
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Admin drawer overflowed');
  });

  testWidgets('staff provisioning dialog fits a phone viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);

    final store = AdminStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AdminStaffScreen(store: store)),
      ),
    );
    await tester.tap(find.text('+ Provision Staff'));
    await tester.pumpAndSettle();

    expect(find.text('Provision New Staff Member'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fleet registration form fits a phone viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);

    final store = AdminStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminFleetRegisterScreen(store: store, onFinished: () {}),
      ),
    );

    expect(find.text('Register Ambulance Unit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
