
import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class BudgetQuotationsScreen extends StatefulWidget {
  const BudgetQuotationsScreen({super.key});

  @override
  State<BudgetQuotationsScreen> createState() => _BudgetQuotationsScreenState();
}

class _BudgetQuotationsScreenState extends State<BudgetQuotationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // Do not query public.bookings directly here.
      // Team Lead reads use the SECURITY DEFINER RPC so RLS does not
      // silently turn a valid Team Lead feed into an empty screen.
      final result = await SupabaseService.client.rpc(
        'get_team_lead_bookings',
        params: {
          'p_filter': 'ALL',
          'p_search': '',
        },
      );

      final rows = _teamLeadBookingRows(result);

      if (!mounted) return;

      setState(() {
        _bookings = rows.where(_budgetRelevant).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> _teamLeadBookingRows(dynamic result) {
    if (result is! List) {
      return <Map<String, dynamic>>[];
    }

    final output = <Map<String, dynamic>>[];

    for (final raw in result) {
      if (raw is! Map) continue;

      final wrapper = Map<String, dynamic>.from(raw);

      final nested = wrapper['booking'];

      if (nested is Map) {
        final booking =
            Map<String, dynamic>.from(nested);

        final latestQuotation = wrapper['latest_quotation'];
        if (latestQuotation is Map) {
          final quotation = Map<String, dynamic>.from(latestQuotation);
          _putQuotationValue(booking, 'quotation_id', quotation, ['id', 'quotation_id']);
          _putQuotationValue(booking, 'quotation_status', quotation, ['status', 'quotation_status']);
          _putQuotationValue(booking, 'q_base_charge', quotation, ['base_ambulance_charge', 'base_charge']);
          _putQuotationValue(booking, 'q_distance_charge', quotation, ['distance_charge']);
          _putQuotationValue(booking, 'q_subtotal', quotation, ['subtotal']);
          _putQuotationValue(booking, 'q_discount', quotation, ['discount']);
          _putQuotationValue(booking, 'q_tax_percent', quotation, ['tax_percent']);
          _putQuotationValue(booking, 'q_tax_amount', quotation, ['tax_amount']);
          _putQuotationValue(
            booking,
            'q_final_amount',
            quotation,
            ['final_amount', 'total_amount', 'amount'],
          );
        }

        // Preserve useful RPC wrapper information without overwriting
        // real booking columns.
        final assignment = wrapper['assignment'];
        if (assignment is Map) {
          final a =
              Map<String, dynamic>.from(assignment);

          booking.putIfAbsent(
            'driver_name',
            () => a['driver_name'] ??
                a['driver_full_name'],
          );

          booking.putIfAbsent(
            'vehicle_number',
            () => a['vehicle_number'] ??
                a['registration_number'],
          );

          booking.putIfAbsent(
            'doctor_name',
            () => a['doctor_name'] ??
                a['doctor_full_name'],
          );

          booking.putIfAbsent(
            'emt_name',
            () => a['emt_name'] ??
                a['medical_crew_name'],
          );
        }

        output.add(booking);
      } else {
        // Supports installations where the RPC returns a flat row.
        output.add(wrapper);
      }
    }

    return output;
  }

  void _putQuotationValue(
    Map<String, dynamic> booking,
    String target,
    Map<String, dynamic> quotation,
    List<String> sourceKeys,
  ) {
    if (booking[target] != null) return;
    for (final sourceKey in sourceKeys) {
      if (quotation[sourceKey] != null) {
        booking[target] = quotation[sourceKey];
        return;
      }
    }
  }

  bool _budgetRelevant(Map<String, dynamic> b) {
    final s = '${b['status'] ?? ''}'.toUpperCase();
    return {
      'SENT_TO_TEAM_LEAD',
      'VERIFIED',
      'QUOTATION_PENDING',
      'QUOTATION_SENT',
      'CUSTOMER_REJECTED',
      'CUSTOMER_ACCEPTED',
      'ASSIGNED',
    }.contains(s);
  }

  Future<void> _prepare(Map<String, dynamic> booking) async {
    final additionalController = TextEditingController(text: '0');
    final termsController =
        TextEditingController(text: 'Payment before dispatch');

    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Prepare quotation • ${booking['id']}'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _line('Basic fare', _money(booking['basic_fare'])),
              _line('Distance', '${_num(booking['estimated_distance_km']).toStringAsFixed(2)} km'),
              const SizedBox(height: 12),
              TextField(
                controller: additionalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Additional charge',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: termsController,
                decoration: const InputDecoration(
                  labelText: 'Payment terms',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'additional': additionalController.text,
              'terms': termsController.text,
            }),
            child: const Text('Prepare & Send'),
          ),
        ],
      ),
    );

    additionalController.dispose();
    termsController.dispose();

    if (values == null) return;

    final additional =
        double.tryParse(values['additional'] ?? '0') ?? 0;

    try {
      await SupabaseService.client.rpc(
        'prepare_booking_quotation',
        params: {
          'p_booking_id': '${booking['id']}',
          'p_additional_charge': additional,
          'p_payment_terms': values['terms'],
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation prepared and sent.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quotation failed: $e')),
      );
    }
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );

  String _money(dynamic value) =>
      '₹${_num(value).toStringAsFixed(2)}';

  double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget & Quotations'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      backgroundColor: const Color(0xFFF6F8FB),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!),
                ))
              : _bookings.isEmpty
                  ? const Center(child: Text('No bookings require quotation work.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: _bookings.length,
                      itemBuilder: (_, i) => _card(_bookings[i]),
                    ),
    );
  }

  Widget _card(Map<String, dynamic> b) {
    final status = '${b['status'] ?? ''}'.toUpperCase();
    final finalAmount = _num(b['q_final_amount']);
    final basic = _num(b['basic_fare']);
    final hasQuotation =
        finalAmount > 0 &&
        '${b['quotation_status'] ?? ''}'.isNotEmpty;

    final canPrepare = {
      'SENT_TO_TEAM_LEAD',
      'VERIFIED',
      'QUOTATION_PENDING',
      'CUSTOMER_REJECTED',
    }.contains(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${b['id'] ?? ''} • ${b['patient_name'] ?? 'Patient'}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                _badge(status),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              '${b['service_category'] ?? 'ROAD'}'
              '${b['service_subtype'] == null ? '' : ' • ${b['service_subtype']}'}'
              ' • ${_num(b['estimated_distance_km']).toStringAsFixed(2)} km',
            ),
            const Divider(height: 22),
            _line('Basic fare', _money(basic)),
            if (hasQuotation) ...[
              _line('Subtotal', _money(b['q_subtotal'])),
              _line('Tax (${_num(b['q_tax_percent']).toStringAsFixed(2)}%)',
                  _money(b['q_tax_amount'])),
              _line('Final quotation', _money(finalAmount)),
              _line('Quotation status', '${b['quotation_status'] ?? ''}'),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  'Quotation not prepared yet.',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              ),
            const SizedBox(height: 12),
            if (canPrepare)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _prepare(b),
                  icon: const Icon(Icons.calculate_outlined),
                  label: Text(hasQuotation ? 'Re-prepare quotation' : 'Prepare quotation'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text.replaceAll('_', ' '),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      );
}
