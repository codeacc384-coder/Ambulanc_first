import 'package:ambulance_first/shared/booking_date_time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats ISO booking date and 24-hour time for display', () {
    expect(
      BookingDateTimeFormatter.formatDateTime('2026-10-01', '14:30:00'),
      '1 Oct 2026 · 2:30 PM',
    );
  });

  test('preserves existing human-readable date and unscheduled labels', () {
    expect(BookingDateTimeFormatter.formatDate('Today'), 'Today');
    expect(BookingDateTimeFormatter.formatTime('Not scheduled'), 'Not scheduled');
    expect(
      BookingDateTimeFormatter.formatDateTime('Not scheduled', 'Not scheduled'),
      'Not scheduled',
    );
  });

  test('returns the available part when date or time is missing', () {
    expect(
      BookingDateTimeFormatter.formatDateTime('2026-10-01', ''),
      '1 Oct 2026',
    );
    expect(
      BookingDateTimeFormatter.formatDateTime('', '14:30'),
      '2:30 PM',
    );
  });

  test('formats ISO timestamps with a readable local date and time', () {
    expect(
      BookingDateTimeFormatter.formatTimestamp('2026-10-01T14:30:00'),
      '1 Oct 2026 · 2:30 PM',
    );
  });
}