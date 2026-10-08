import 'dart:convert';

import 'package:ambulance_first/core/models/customer_care_case.dart';
import 'package:ambulance_first/core/services/customer_care_repository.dart';
import 'package:ambulance_first/core/services/supabase_booking_repository.dart';

import 'package:ambulance_first/core/services/supabase_service.dart';
import 'package:ambulance_first/core/services/supabase_workflow_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'mocked customer-to-driver booking lifecycle uses expected RPCs',
    () async {
      var bookingStatus = 'NEW';
      final calls = <String>[];
      final client = MockClient((request) async {
        final path = request.url.path;
        http.Response jsonResponse(Object? body) => http.Response(
          jsonEncode(body),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );

        if (path.endsWith('/auth/v1/user')) {
          return jsonResponse({
            'id': '00000000-0000-4000-8000-000000000001',
            'aud': 'authenticated',
            'role': 'authenticated',
            'email': 'mock-customer@example.test',
            'app_metadata': {
              'provider': 'email',
              'providers': ['email'],
            },
            'user_metadata': {},
            'identities': [],
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
        }

        if (path.endsWith('/functions/v1/calculate-booking-route')) {
          calls.add('calculate-booking-route');
          expect(jsonDecode(request.body), {'bookingId': 'BK-MOCK-01'});
          return jsonResponse({'success': true});
        }

        if (path.startsWith('/rest/v1/rpc/')) {
          final rpc = path.split('/').last;
          final decodedBody = request.body.isEmpty
              ? null
              : jsonDecode(request.body);
          final parameters = decodedBody is Map
              ? Map<String, dynamic>.from(decodedBody)
              : <String, dynamic>{};
          calls.add(rpc);

          switch (rpc) {
            case 'create_customer_booking':
              bookingStatus = 'NEW';
              return jsonResponse('BK-MOCK-01');
            case 'calculate_booking_basic_fare':
              return jsonResponse({
                'basic_fare': 3500,
                'basic_fare_distance_km': 18.5,
              });
            case 'get_customer_bookings':
              return jsonResponse([_customerBookingRow(bookingStatus)]);
            case 'get_customer_quotations':
              return jsonResponse(<dynamic>[]);
            case 'get_customer_care_dashboard':
              return jsonResponse({
                'new_inbound_count': 0,
                'code_red_count': 0,
                'pending_calls_count': 0,
                'verified_count': 0,
                'sent_to_team_lead_count': 0,
                'active_trips_count': 0,
                'total_open_count': 0,
              });
            case 'get_customer_care_bookings':
              return jsonResponse([
                {'id': 'BK-MOCK-01', 'status': bookingStatus},
              ]);
            case 'get_customer_care_notifications':
            case 'get_customer_care_active_trips':
              return jsonResponse(<dynamic>[]);
            case 'verify_customer_care_booking':
              expect(parameters['p_verification']['booking_id'], 'BK-MOCK-01');
              bookingStatus = 'VERIFIED';
              return jsonResponse({'success': true, 'status': bookingStatus});
            case 'send_customer_care_to_team_lead':
              expect(parameters['p_booking_id'], 'BK-MOCK-01');
              bookingStatus = 'SENT_TO_TEAM_LEAD';
              return jsonResponse({'success': true, 'status': bookingStatus});
            case 'prepare_booking_quotation':
              expect(parameters['p_booking_id'], 'BK-MOCK-01');
              bookingStatus = 'QUOTATION_SENT';
              return jsonResponse({'success': true, 'status': bookingStatus});
            case 'respond_to_quotation':
              expect(parameters['p_booking_id'], 'BK-MOCK-01');
              expect(parameters['p_accept'], isTrue);
              bookingStatus = 'CUSTOMER_ACCEPTED';
              return jsonResponse({'success': true, 'status': bookingStatus});
            case 'allocate_booking':
              expect(parameters['p_booking_id'], 'BK-MOCK-01');
              expect(parameters['p_driver_id'], 'driver-mock-id');
              bookingStatus = 'ASSIGNED';
              return jsonResponse({'success': true, 'status': bookingStatus});
            case 'driver_respond_to_assignment':
              expect(parameters['p_booking_id'], 'BK-MOCK-01');
              expect(parameters['p_accept'], isTrue);
              bookingStatus = 'DRIVER_ASSIGNED';
              return jsonResponse({'success': true, 'status': bookingStatus});
            case 'driver_advance_booking':
              bookingStatus = parameters['p_next_status'] as String;
              return jsonResponse({'success': true, 'status': bookingStatus});
            case 'publish_driver_location':
              expect(parameters['p_booking_id'], 'BK-MOCK-01');
              expect(parameters['p_driver_id'], 'driver-mock-id');
              expect(parameters['p_latitude'], 17.385044);
              expect(parameters['p_longitude'], 78.486671);
              return jsonResponse({'success': true});
            default:
              fail('Unexpected Supabase RPC: $rpc');
          }
        }

        if (path.startsWith('/rest/v1/bookings')) {
          return jsonResponse({'id': 'BK-MOCK-01', 'status': bookingStatus});
        }

        fail('Unexpected mock backend request: ${request.method} $path');
      });

      try {
        await SupabaseService.initialize(
          httpClient: client,
          urlOverride: 'https://mock.supabase.test',
          publishableKeyOverride: 'mock-publishable-key',
          enableRealtime: false,
          authOptions: const FlutterAuthClientOptions(
            persistSession: false,
            autoRefreshToken: false,
            pkceAsyncStorage: _MemoryAuthStorage(),
          ),
        );
        final jwt = _mockJwt();
        await Supabase.instance.client.auth.setSession(
          'mock-refresh-token',
          accessToken: jwt,
        );

        final workflow = SupabaseWorkflowRepository();
        final bookingId = await workflow.createCustomerBooking({
          'customer_name': 'Mock Customer',
          'patient_name': 'Mock Patient',
        });
        expect(bookingId, 'BK-MOCK-01');
        await workflow.calculateBookingRoute(bookingId);
        final fare = await workflow.calculateBasicFare(bookingId);
        expect(fare['basic_fare'], 3500);

        final customerBookings = await SupabaseBookingRepository()
            .getCustomerBookings();
        expect(customerBookings.single.id, bookingId);
        expect(customerBookings.single.status, 'NEW');

        final verification = CustomerCareVerificationPayload(
          bookingId: bookingId,
          patientConditionConfirmed: true,
          medicalRequirementsConfirmed: true,
          locationConfirmed: true,
          datetimeConfirmed: true,
          checkPatientCondition: true,
          checkOxygenTherapy: true,
          checkVentilatorLoaded: true,
          checkDoctorDesignated: true,
          checkReceivingBedSecured: true,
          checkRoutePriorityCleared: true,
          priority: 'NORMAL',
          notes: 'Mock integration verification',
        );
        expect(
          await CustomerCareRepository.instance.verifyCustomerCareBooking(
            verification: verification,
          ),
          isTrue,
        );
        expect(
          await CustomerCareRepository.instance.sendCustomerCareToTeamLead(
            bookingId,
            'Mock handoff',
          ),
          isTrue,
        );

        await workflow.prepareQuotation(bookingId: bookingId);
        await workflow.respondToQuotation(bookingId: bookingId, accept: true);
        await workflow.allocateBooking(
          bookingId: bookingId,
          ambulanceId: 'ambulance-mock-id',
          driverId: 'driver-mock-id',
        );
        await workflow.driverRespondToAssignment(
          bookingId: bookingId,
          accept: true,
        );
        await workflow.driverAdvanceBooking(
          bookingId: bookingId,
          nextStatus: 'PICKUP_STARTED',
        );
        await workflow.publishDriverLocation(
          driverId: 'driver-mock-id',
          bookingId: bookingId,
          latitude: 17.385044,
          longitude: 78.486671,
        );

        expect(bookingStatus, 'PICKUP_STARTED');
        final trackedBookings = await SupabaseBookingRepository()
            .getCustomerBookings();
        final trackedBooking = trackedBookings.single;
        expect(trackedBooking.assignedDriverId, 'driver-mock-id');
        expect(trackedBooking.driverName, 'Mock Assigned Driver');
        expect(trackedBooking.driverPhone, '+911234567890');
        expect(trackedBooking.vehicleNumber, 'KA-01-MOCK-01');
        expect(trackedBooking.driverLatitude, 17.385044);
        expect(trackedBooking.driverLongitude, 78.486671);
        expect(
          calls,
          containsAllInOrder([
            'create_customer_booking',
            'calculate_booking_basic_fare',
            'get_customer_bookings',
            'verify_customer_care_booking',
            'send_customer_care_to_team_lead',
            'prepare_booking_quotation',
            'respond_to_quotation',
            'allocate_booking',
            'driver_respond_to_assignment',
            'driver_advance_booking',
            'publish_driver_location',
          ]),
        );
      } finally {
        if (Supabase.instance.isInitialized) {
          await Supabase.instance.dispose();
        }
        client.close();
      }
    },
  );
}

Map<String, dynamic> _customerBookingRow(String status) => {
  'id': 'BK-MOCK-01',
  'status': status,
  'customer_id': '00000000-0000-4000-8000-000000000001',
  'pickup_address': 'Mock Pickup',
  'destination_address': 'Mock Destination',
  'estimated_distance_km': 18.5,
  'basic_fare': 3500,
  'patient_name': 'Mock Patient',
  'customer_name': 'Mock Customer',
  'preferred_date': 'Today',
  'preferred_time': 'Immediate',
  'service_category': 'ROAD',
  if (status == 'PICKUP_STARTED') ...{
    'assignment': {
      'driver_id': 'driver-mock-id',
      'driver_full_name': 'Mock Assigned Driver',
      'driver_mobile': '+911234567890',
      'ambulance_vehicle_number': 'KA-01-MOCK-01',
    },
    'driver_location': {
      'latitude': 17.385044,
      'longitude': 78.486671,
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
    },
  },
};

String _mockJwt() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'sub': '00000000-0000-4000-8000-000000000001',
            'aud': 'authenticated',
            'role': 'authenticated',
            'iat': now,
            'exp': now + 3600,
          }),
        ),
      )
      .replaceAll('=', '');
  return 'eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.$payload.';
}

class _MemoryAuthStorage extends GotrueAsyncStorage {
  const _MemoryAuthStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}
