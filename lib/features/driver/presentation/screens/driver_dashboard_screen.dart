import 'package:flutter/material.dart';

import '../../../../core/models/driver_models.dart';
import '../../../../shared/booking_date_time_formatter.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';
import '../widgets/driver_duty_switcher.dart';

class DriverDashboardScreen extends StatefulWidget {
  static const List<String> emergencyMedicationChecklist = [
    'Epinephrine',
    'Atropine',
    'Flumazenil',
    'Glucagon',
    'Amiodarone',
    'Sodium bicarbonate',
    'Naloxone',
    'Midazolam',
    'Lorazepam',
    'Diazepam',
    'Vasopressors',
    'Dopamine',
    'Norepinephrine',
    'Adenosine',
    'Metoprolol',
    'Chlorpheniramine',
    'Dexamethasone',
    'Hydrocortisone',
    'Tramadol',
  ];

  static const List<String> medicalEquipmentChecklist = [
    'Oxygen cylinder',
    'Oxygen mask and nasal cannula',
    'Bag-valve mask',
    'BiPAP machine',
    'Laryngoscope with compatible blades',
    'Portable suction unit',
    'Pulse oximeter',
    'Blood pressure monitor',
    'Cardiac monitor',
    'AED / defibrillator',
    'Portable ECG machine',
    'Transport ventilator',
    'Nebulizer',
    'Glucometer',
    'IV infusion pump',
    'Syringe pump',
    'Airway management kit',
    'Cervical collars',
    'Spine board',
    'Splints',
    'Trauma and wound-care kit',
    'Hemorrhage-control kit',
    'PPE and isolation kit',
    'Burn dressing kit',
    'Obstetric delivery kit',
    'Neonatal transport incubator',
    'Stretcher',

  ];

  const DriverDashboardScreen({
    super.key,
    required this.driver,
    required this.bookings,
    required this.onSaveInventory,
    required this.onAdvance,
    required this.onOpenActiveTrip,
    required this.onOpenAssignments,
    required this.onStatusChanged,
    this.lastLocationSharedAt,
    this.isLiveGpsSharing = false,
  });

  final DriverProfile driver;
  final List<DriverBooking> bookings;
  final Future<void> Function(
    List<String> medications,
    List<EquipmentInventoryItem> equipment,
  )
  onSaveInventory;
  final void Function(DriverBooking booking, String nextStatus) onAdvance;
  final VoidCallback onOpenActiveTrip;
  final VoidCallback onOpenAssignments;
  final ValueChanged<String> onStatusChanged;
  final DateTime? lastLocationSharedAt;
  final bool isLiveGpsSharing;

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final Set<String> _selectedMedicines = <String>{};
  final Set<String> _selectedEquipment = <String>{};
  final Map<String, EquipmentInventoryItem> _equipmentDetails = {};
  Set<String> _savedMedicines = <String>{};
  Set<String> _savedEquipment = <String>{};
  bool _savingInventory = false;

  @override
  void initState() {
    super.initState();
    _selectedMedicines.addAll(widget.driver.availableMedications);
    _selectedEquipment.addAll(widget.driver.availableEquipment);
    for (final item in widget.driver.equipmentInventory) {
      _equipmentDetails[item.name] = item;
      if (item.available) _selectedEquipment.add(item.name);
    }
    _savedMedicines = Set<String>.from(widget.driver.availableMedications);
    _savedEquipment = Set<String>.from(widget.driver.availableEquipment);
  }

  @override
  void didUpdateWidget(covariant DriverDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final latestSavedMedicines = Set<String>.from(
      widget.driver.availableMedications,
    );
    final latestSavedEquipment = Set<String>.from(
      widget.driver.availableEquipment,
    );
    final medicinesChanged = !_sameItems(latestSavedMedicines, _savedMedicines);
    final equipmentChanged = !_sameItems(latestSavedEquipment, _savedEquipment);
    if (medicinesChanged || equipmentChanged) {
      final selectionWasUnchanged =
          _sameItems(_selectedMedicines, _savedMedicines) &&
          _sameItems(_selectedEquipment, _savedEquipment);
      _savedMedicines = latestSavedMedicines;
      _savedEquipment = latestSavedEquipment;
      if (selectionWasUnchanged) {
        _selectedMedicines
          ..clear()
          ..addAll(latestSavedMedicines);
        _selectedEquipment
          ..clear()
          ..addAll(latestSavedEquipment);
      }
    }
  }

  bool _sameItems(Set<String> first, Set<String> second) =>
      first.length == second.length && first.containsAll(second);

  @override
  void dispose() {
    _selectedMedicines.clear();
    _selectedEquipment.clear();
    _savedMedicines.clear();
    _savedEquipment.clear();
    super.dispose();
  }

  DriverBooking? get _activeTrip {
    for (final b in widget.bookings) {
      if (b.isActive) return b;
    }
    return null;
  }

  List<DriverBooking> get _pendingAssignments {
    return widget.bookings
        .where((b) => b.status == 'ASSIGNED' || b.status == 'DRIVER_ASSIGNED')
        .toList();
  }

  void _toggleMedicine(String medicine) {
    setState(() {
      if (_selectedMedicines.contains(medicine)) {
        _selectedMedicines.remove(medicine);
      } else {
        _selectedMedicines.add(medicine);
      }
    });
  }

  void _toggleEquipment(String equipment) {
    setState(() {
      if (_selectedEquipment.contains(equipment)) {
        _selectedEquipment.remove(equipment);
      } else {
        _selectedEquipment.add(equipment);
      }
    });
  }

  static const Map<String, List<String>> _deviceChecks = {
    'BiPAP machine': [
      'Power supply and battery checked',
      'Circuit and tubing present',
      'Compatible mask/interface present',
      'Filter present',
      'Self-test and alarms checked',
    ],
    'Laryngoscope with compatible blades': [
      'Handle operates',
      'Light or power function works',
      'Compatible blades available',
    ],
  };

  Map<String, bool> _defaultChecks(String name) => {
    for (final check in _deviceChecks[name] ?? const <String>[]) check: false,
  };

  EquipmentInventoryItem _inventoryItemFor(String name) {
    final current = _equipmentDetails[name];
    final available = _selectedEquipment.contains(name);
    return EquipmentInventoryItem(
      name: name,
      available: available,
      quantity: available ? (current?.quantity ?? 1) : 0,
      functionalCondition: current?.functionalCondition ?? 'UNKNOWN',
      inspectionStatus: current?.inspectionStatus ?? 'NOT_INSPECTED',
      checks: Map<String, bool>.from(current?.checks ?? _defaultChecks(name)),
    );
  }

  String _inventorySummaryFor(String requestedEquipment) {
    final requested = requestedEquipment.trim().toLowerCase();
    final inventory = widget.driver.equipmentInventory.where(
      (item) => item.name.trim().toLowerCase() == requested,
    );
    if (inventory.isNotEmpty) {
      final item = inventory.first;
      if (!item.available || item.quantity <= 0) return 'Not stocked';
      return '${item.quantity} available · ${item.functionalCondition} · ${item.inspectionStatus}';
    }

    final legacyAvailable = widget.driver.availableEquipment.any(
      (name) => name.trim().toLowerCase() == requested,
    );
    return legacyAvailable
        ? 'Stocked · inspection details not recorded'
        : 'Not reported in inventory';
  }

  bool _inspectionIsComplete(EquipmentInventoryItem item) {
    if (item.inspectionStatus != 'PASSED') return true;
    return item.functionalCondition == 'FUNCTIONAL' &&
        (_deviceChecks[item.name] ?? const <String>[]).every(
          (check) => item.checks[check] == true,
        );
  }

  Widget _inventoryDetails(String name) {
    final item = _inventoryItemFor(name);

    void update(EquipmentInventoryItem updated) {
      setState(() => _equipmentDetails[name] = updated);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DriverColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Quantity'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: item.quantity.clamp(1, 50).toInt(),
                items: [
                  for (var quantity = 1; quantity <= 50; quantity++)
                    DropdownMenuItem(
                      value: quantity,
                      child: Text('$quantity'),
                    ),
                ],
                onChanged: (quantity) {
                  if (quantity == null) return;
                  update(
                    EquipmentInventoryItem(
                      name: name,
                      available: true,
                      quantity: quantity,
                      functionalCondition: item.functionalCondition,
                      inspectionStatus: item.inspectionStatus,
                      checks: item.checks,
                    ),
                  );
                },
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: item.functionalCondition,
            decoration: const InputDecoration(
              labelText: 'Functional condition',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'UNKNOWN', child: Text('Not checked')),
              DropdownMenuItem(value: 'FUNCTIONAL', child: Text('Functional')),
              DropdownMenuItem(
                value: 'PARTIALLY_FUNCTIONAL',
                child: Text('Partially functional'),
              ),
              DropdownMenuItem(
                value: 'NON_FUNCTIONAL',
                child: Text('Non-functional'),
              ),
            ],
            onChanged: (condition) {
              if (condition == null) return;
              update(
                EquipmentInventoryItem(
                  name: name,
                  available: true,
                  quantity: item.quantity,
                  functionalCondition: condition,
                  inspectionStatus: item.inspectionStatus,
                  checks: item.checks,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: item.inspectionStatus,
            decoration: const InputDecoration(
              labelText: 'Inspection status',
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: 'NOT_INSPECTED',
                child: Text('Not inspected'),
              ),
              DropdownMenuItem(value: 'PASSED', child: Text('Passed')),
              DropdownMenuItem(
                value: 'NEEDS_SERVICE',
                child: Text('Needs service'),
              ),
              DropdownMenuItem(value: 'FAILED', child: Text('Failed')),
            ],
            onChanged: (status) {
              if (status == null) return;
              update(
                EquipmentInventoryItem(
                  name: name,
                  available: true,
                  quantity: item.quantity,
                  functionalCondition: item.functionalCondition,
                  inspectionStatus: status,
                  checks: item.checks,
                ),
              );
            },
          ),
          for (final check in _deviceChecks[name] ?? const <String>[])
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(check, style: DriverTextStyles.bodySmall),
              value: item.checks[check] ?? false,
              onChanged: (checked) {
                if (checked == null) return;
                update(
                  EquipmentInventoryItem(
                    name: name,
                    available: true,
                    quantity: item.quantity,
                    functionalCondition: item.functionalCondition,
                    inspectionStatus: item.inspectionStatus,
                    checks: {...item.checks, check: checked},
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _saveInventory() async {
    setState(() => _savingInventory = true);
    try {
      final medications = _selectedMedicines.toList()..sort();
      final equipment = _selectedEquipment.toList()..sort();
      final equipmentInventory = [
        for (final name in DriverDashboardScreen.medicalEquipmentChecklist)
          _inventoryItemFor(name),
      ];
      final incompleteInspection = equipmentInventory.where(
        (item) => !_inspectionIsComplete(item),
      );
      if (incompleteInspection.isNotEmpty) {
        throw StateError(
          'A passed inspection requires functional condition and all device checks for ${incompleteInspection.map((item) => item.name).join(', ')}.',
        );
      }
      await widget.onSaveInventory(medications, equipmentInventory);
      widget.driver.availableMedications = medications;
      widget.driver.availableEquipment = equipment;
      widget.driver.equipmentInventory = equipmentInventory;
      _savedMedicines = Set<String>.from(medications);
      _savedEquipment = Set<String>.from(equipment);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambulance inventory updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update ambulance inventory: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingInventory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeTrip;
    final pending = _pendingAssignments;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pilot Identity Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DriverColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DriverColors.surfaceContainerHigh),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: DriverColors.primaryContainer,
                      child: Text(
                        widget.driver.name.isNotEmpty
                            ? widget.driver.name[0]
                            : 'R',
                        style: DriverTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.driver.name,
                            style: DriverTextStyles.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'PILOT ID: ${widget.driver.id}  •  ${widget.driver.assignedAmbulanceNumber}',
                            style: DriverTextStyles.telemetryMicro.copyWith(
                              color: DriverColors.primaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'License ${widget.driver.licenseNumber} (Exp: ${widget.driver.licenseExpiry})',
                            style: DriverTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DriverColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: DriverColors.secondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.driver.rating.toStringAsFixed(1),
                            style: DriverTextStyles.telemetryMicro.copyWith(
                              color: DriverColors.secondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(
                  height: 1,
                  color: DriverColors.surfaceContainerHigh,
                ),
                const SizedBox(height: 14),
                // Duty Status Switcher
                DriverDutySwitcher(
                  currentStatus: widget.driver.status,
                  hasActiveTrip: active != null,
                  onStatusChanged: widget.onStatusChanged,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Active Mission Card or Standby Readiness
          if (active != null) ...[
            Container(
              decoration: BoxDecoration(
                color: DriverColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: DriverColors.primaryContainer,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DriverColors.primaryContainer.withValues(
                      alpha: 0.08,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: DriverColors.primaryContainer,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.navigation_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ACTIVE MISSION IN PROGRESS',
                              style: DriverTextStyles.telemetryMicro.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (widget.isLiveGpsSharing) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: DriverColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'GPS LIVE',
                                  style: DriverTextStyles.telemetryMicro
                                      .copyWith(
                                        color: DriverColors.secondary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 9,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          active.id,
                          style: DriverTextStyles.bookingId.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${active.patientName} (${active.patientAge} ${active.patientGender[0]})',
                              style: DriverTextStyles.titleMedium,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: DriverColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                active.statusLabel,
                                style: DriverTextStyles.telemetryMicro.copyWith(
                                  color: DriverColors.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          active.medicalConditionSummary,
                          style: DriverTextStyles.bodySmall,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'SERVICE & VEHICLE CONFIGURATION',
                          style: DriverTextStyles.telemetryMicro.copyWith(
                            color: DriverColors.primaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Service: ${active.serviceSubtype.isEmpty ? active.serviceCategory : active.serviceSubtype} · Ambulance: ${active.vehicleNumber.isEmpty ? 'Not recorded' : active.vehicleNumber}',
                          style: DriverTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'EQUIPMENT EXPLICITLY REQUESTED IN THIS BOOKING',
                          style: DriverTextStyles.telemetryMicro.copyWith(
                            color: DriverColors.primaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (active.requiredEquipment.isEmpty)
                          Text(
                            'No optional equipment was specified. Confirm requirements against the selected service and ambulance configuration.',
                            style: DriverTextStyles.bodySmall,
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final equipment
                                      in active.requiredEquipment)
                                    Chip(
                                      label: Text(equipment),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                              for (final equipment in active.requiredEquipment)
                                Text(
                                  '$equipment: ${_inventorySummaryFor(equipment)}',
                                  style: DriverTextStyles.bodySmall,
                                ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: DriverColors.tertiary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${active.pickupAddress} ➔ ${active.destinationAddress}',
                                style: DriverTextStyles.telemetryMicro.copyWith(
                                  color: DriverColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: widget.onOpenActiveTrip,
                            icon: const Icon(Icons.speed_rounded, size: 18),
                            label: const Text('OPEN ACTIVE TRIP CONSOLE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DriverColors.primaryContainer,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DriverColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DriverColors.surfaceContainerHigh),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DriverColors.secondaryContainer.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: DriverColors.secondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready on Standby Depot',
                          style: DriverTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Ambulance unit ${widget.driver.assignedAmbulanceNumber} is online and operational for dispatch.',
                          style: DriverTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DriverColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DriverColors.surfaceContainerHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      color: DriverColors.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MEDICINES AVAILABLE WITH DRIVER',
                      style: DriverTextStyles.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select the medicines currently stocked in your ambulance, then update the list for Team Lead.',
                  style: DriverTextStyles.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final medicine
                        in DriverDashboardScreen.emergencyMedicationChecklist)
                      FilterChip(
                        label: Text(medicine),
                        selected: _selectedMedicines.contains(medicine),
                        showCheckmark: true,
                        checkmarkColor: Colors.white,
                        selectedColor: DriverColors.primaryContainer,
                        backgroundColor: DriverColors.secondaryContainer,
                        side: BorderSide(
                          color: _selectedMedicines.contains(medicine)
                              ? DriverColors.primaryContainer
                              : DriverColors.surfaceContainerHigh,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: DriverTextStyles.telemetryMicro.copyWith(
                          color: _selectedMedicines.contains(medicine)
                              ? Colors.white
                              : DriverColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => _toggleMedicine(medicine),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedMedicines.length} medicine${_selectedMedicines.length == 1 ? '' : 's'} selected',
                  style: DriverTextStyles.bodySmall.copyWith(
                    color: DriverColors.primaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DriverColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DriverColors.surfaceContainerHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.medical_information_outlined,
                      color: DriverColors.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MEDICAL EQUIPMENT AVAILABLE',
                      style: DriverTextStyles.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select equipment currently stocked and operational in your ambulance.',
                  style: DriverTextStyles.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final equipment
                        in DriverDashboardScreen.medicalEquipmentChecklist)
                      FilterChip(
                        label: Text(equipment),
                        selected: _selectedEquipment.contains(equipment),
                        showCheckmark: true,
                        checkmarkColor: Colors.white,
                        selectedColor: DriverColors.primaryContainer,
                        backgroundColor: DriverColors.secondaryContainer,
                        side: BorderSide(
                          color: _selectedEquipment.contains(equipment)
                              ? DriverColors.primaryContainer
                              : DriverColors.surfaceContainerHigh,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: DriverTextStyles.telemetryMicro.copyWith(
                          color: _selectedEquipment.contains(equipment)
                              ? Colors.white
                              : DriverColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (_) => _toggleEquipment(equipment),
                      ),
                  ],
                ),
                ..._selectedEquipment.map(_inventoryDetails),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedEquipment.length} equipment items selected',
                        style: DriverTextStyles.bodySmall.copyWith(
                          color: DriverColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _savingInventory ? null : _saveInventory,
                      icon: _savingInventory
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        _savingInventory ? 'Updating…' : 'Update inventory',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Pending Assignments Queue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ASSIGNED TO YOU', style: DriverTextStyles.headlineSmall),
              TextButton.icon(
                onPressed: widget.onOpenAssignments,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(
                  'View All (${pending.length})',
                  style: DriverTextStyles.button.copyWith(
                    color: DriverColors.primaryContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (pending.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DriverColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DriverColors.surfaceContainerHigh),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 36,
                    color: DriverColors.outlineVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No Pending Assignments',
                    style: DriverTextStyles.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You are current on all dispatch queue orders.',
                    style: DriverTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ] else ...[
            ...pending.take(2).map((b) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DriverColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DriverColors.surfaceContainerHigh),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DriverColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_hospital_outlined,
                        size: 20,
                        color: DriverColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(b.id, style: DriverTextStyles.bookingId),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: DriverColors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  BookingDateTimeFormatter.formatTime(
                                    b.preferredTime,
                                  ),
                                  style: DriverTextStyles.telemetryMicro,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${b.patientName} • ${b.pickupCity} ➔ ${b.destinationCity}',
                            style: DriverTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => widget.onAdvance(b, 'PICKUP_STARTED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DriverColors.primaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'START',
                        style: DriverTextStyles.button.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 20),

          // Operational Statistics Bar
          Text('PILOT PERFORMANCE', style: DriverTextStyles.headlineSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'TOTAL TRANSPORTS',
                  value: widget.driver.totalTrips.toString(),
                  icon: Icons.check_circle_outline,
                  color: DriverColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'RESPONSE METRIC',
                  value: '--',
                  icon: Icons.timer_outlined,
                  color: DriverColors.primaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'PILOT RATING',
                  value: '${widget.driver.rating} ★',
                  icon: Icons.star_border,
                  color: DriverColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DriverColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: DriverTextStyles.telemetryMedium.copyWith(
              color: DriverColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: DriverTextStyles.telemetryMicro.copyWith(
              fontSize: 8.5,
              color: DriverColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
