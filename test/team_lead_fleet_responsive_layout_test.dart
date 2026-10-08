import 'package:ambulance_first/roles/team_lead/screens/fleet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('team lead fleet layout aligns cards and scrolls on mobile', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 498);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FleetScreen())),
    );

    expect(find.text('Ambulance Fleet Registry & Readiness'), findsOneWidget);
    expect(find.text('All Units'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Total Fleet')).dy,
      tester.getTopLeft(find.text('Available').first).dy,
    );

    final pageScroll = find.byType(SingleChildScrollView);
    final scrollable = find
        .descendant(of: pageScroll, matching: find.byType(Scrollable))
        .first;
    await tester.drag(pageScroll, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
  });
}
