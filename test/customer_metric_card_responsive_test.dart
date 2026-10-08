import 'package:ambulance_first/roles/customer/widgets/ambulance_first_metric_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('metric cards fit the narrow single-column dashboard layout', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(240, 800);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 216,
              child: GridView.count(
                crossAxisCount: 1,
                childAspectRatio: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  AmbulanceFirstMetricCard(
                    title: 'Total Bookings',
                    value: '02',
                    subtitle: 'All-time requests',
                    icon: Icons.assignment_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Bookings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
