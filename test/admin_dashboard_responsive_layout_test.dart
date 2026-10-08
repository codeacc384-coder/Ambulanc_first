import 'package:ambulance_first/roles/admin/screens/admin_dashboard_screen.dart';
import 'package:ambulance_first/roles/admin/screens/admin_fleet_screen.dart';
import 'package:ambulance_first/roles/admin/store/admin_store.dart';
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
}
