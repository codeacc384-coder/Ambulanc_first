class DriverProfile {
  DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.experienceYears,
    required this.supportedCategories,
    required this.currentLocation,
    this.latitude,
    this.longitude,
    this.locationAccuracyMeters = 0,
    this.locationUpdatedAt,
    required this.assignedAmbulanceNumber,
    required this.status,
    required this.totalTrips,
    required this.rating,
    this.assignedBookingId,
    this.availableMedications = const <String>[],
    this.availableEquipment = const <String>[],
    this.equipmentInventory = const <EquipmentInventoryItem>[],
  });

  String id;
  String name;
  String phone;
  String email;

  String licenseNumber;
  String licenseExpiry;

  int experienceYears;

  List<String> supportedCategories;

  String currentLocation;

  double? latitude;
  double? longitude;

  double locationAccuracyMeters;

  DateTime? locationUpdatedAt;

  String assignedAmbulanceNumber;

  String status;

  int totalTrips;

  double rating;

  String? assignedBookingId;

  List<String> availableMedications;
  List<String> availableEquipment;
  List<EquipmentInventoryItem> equipmentInventory;

  void applyFrom(DriverProfile other) {
    id = other.id;
    name = other.name;
    phone = other.phone;
    email = other.email;

    licenseNumber = other.licenseNumber;
    licenseExpiry = other.licenseExpiry;

    experienceYears = other.experienceYears;

    supportedCategories = List<String>.from(other.supportedCategories);

    currentLocation = other.currentLocation;

    latitude = other.latitude;
    longitude = other.longitude;

    locationAccuracyMeters = other.locationAccuracyMeters;

    locationUpdatedAt = other.locationUpdatedAt;

    assignedAmbulanceNumber = other.assignedAmbulanceNumber;

    status = other.status;

    totalTrips = other.totalTrips;

    rating = other.rating;

    assignedBookingId = other.assignedBookingId;
    availableMedications = List<String>.from(other.availableMedications);
    availableEquipment = List<String>.from(other.availableEquipment);
    equipmentInventory = List<EquipmentInventoryItem>.from(
      other.equipmentInventory,
    );
  }
}

class EquipmentInventoryItem {
  const EquipmentInventoryItem({
    required this.name,
    required this.available,
    required this.quantity,
    required this.functionalCondition,
    required this.inspectionStatus,
    this.checks = const <String, bool>{},
  });

  final String name;
  final bool available;
  final int quantity;
  final String functionalCondition;
  final String inspectionStatus;
  final Map<String, bool> checks;

  factory EquipmentInventoryItem.fromJson(Map<String, dynamic> json) {
    final rawChecks = json['checks'];
    return EquipmentInventoryItem(
      name: '${json['name'] ?? ''}',
      available: json['available'] == true,
      quantity: _equipmentInt(json['quantity']),
      functionalCondition:
          '${json['functional_condition'] ?? 'UNKNOWN'}'.toUpperCase(),
      inspectionStatus:
          '${json['inspection_status'] ?? 'NOT_RECORDED'}'.toUpperCase(),
      checks: rawChecks is Map
          ? rawChecks.map(
              (key, value) => MapEntry(key.toString(), value == true),
            )
          : const <String, bool>{},
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'available': available,
    'quantity': quantity,
    'functional_condition': functionalCondition,
    'inspection_status': inspectionStatus,
    'checks': checks,
  };
}

int _equipmentInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

/// Driver-side representation of a booking.
///
/// IMPORTANT:
/// Route values are READ from Supabase.
/// Flutter does not calculate the booking route or fare.
class DriverBooking {
  DriverBooking({
    required this.id,
    required this.status,
    this.tripMilestone = '',
    this.patientOnboardConfirmed = false,
    required this.serviceCategory,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.currentCondition,
    required this.medicalConditionSummary,
    required this.currentHospital,
    required this.destinationHospital,
    required this.pickupAddress,
    required this.pickupCity,
    required this.destinationAddress,
    required this.destinationCity,
    required this.preferredDate,
    required this.preferredTime,

    // Route
    required this.estimatedDistanceKm,
    required this.estimatedDurationMins,
    required this.routeDistanceMeters,
    required this.routeDurationSeconds,
    required this.routeProvider,
    required this.routeCalculatedAt,

    // Coordinates
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,

    // Customer
    required this.customerName,
    required this.customerMobile,

    // Assigned resources
    required this.vehicleNumber,
    required this.doctorName,
    required this.doctorPhone,
    required this.emtName,
    required this.emtPhone,

    // Live telemetry
    required this.speedKmh,
    required this.etaMinutes,

    // Medical requirements
    required this.oxygenRequired,
    required this.stretcherRequired,
    required this.doctorRequired,
    required this.icuRequired,
    required this.ventilatorRequired,
    required this.cardiacMonitorRequired,
    required this.specialInstructions,
    this.wheelchairRequired = false,
    this.pediatricPatient = false,
    this.additionalEquipment = const <String>[],
    this.serviceSubtype = '',
  });

  // ------------------------------------------------------------
  // BOOKING
  // ------------------------------------------------------------

  final String id;

  String status;

  /// Authoritative workflow milestone returned with the booking row.
  final String tripMilestone;

  final bool patientOnboardConfirmed;

  final String serviceCategory;

  // ------------------------------------------------------------
  // PATIENT
  // ------------------------------------------------------------

  final String patientName;

  final int patientAge;

  final String patientGender;

  final String currentCondition;

  final String medicalConditionSummary;

  final String currentHospital;

  final String destinationHospital;

  // ------------------------------------------------------------
  // LOCATIONS
  // ------------------------------------------------------------

  final String pickupAddress;

  final String pickupCity;

  final String destinationAddress;

  final String destinationCity;

  // ------------------------------------------------------------
  // SCHEDULE
  // ------------------------------------------------------------

  final String preferredDate;

  final String preferredTime;

  // ------------------------------------------------------------
  // GOOGLE ROUTE DATA
  // ------------------------------------------------------------

  /// Total road distance calculated by Google Routes API.
  ///
  /// This is the original booking distance.
  /// It should NOT be changed when the driver moves.
  final double estimatedDistanceKm;

  /// Total route duration calculated by Google.
  final int estimatedDurationMins;

  /// Exact route distance returned by Google.
  final int routeDistanceMeters;

  /// Exact route duration returned by Google.
  final int routeDurationSeconds;

  /// Example:
  /// GOOGLE_ROUTES_API
  final String routeProvider;

  /// When the backend calculated the route.
  final DateTime? routeCalculatedAt;

  // ------------------------------------------------------------
  // PICKUP COORDINATES
  // ------------------------------------------------------------

  final double? pickupLatitude;

  final double? pickupLongitude;

  // ------------------------------------------------------------
  // DESTINATION COORDINATES
  // ------------------------------------------------------------

  final double? destinationLatitude;

  final double? destinationLongitude;

  // ------------------------------------------------------------
  // CUSTOMER
  // ------------------------------------------------------------

  final String customerName;

  final String customerMobile;

  // ------------------------------------------------------------
  // ASSIGNED AMBULANCE
  // ------------------------------------------------------------

  final String vehicleNumber;

  // ------------------------------------------------------------
  // DOCTOR
  // ------------------------------------------------------------

  final String doctorName;

  final String doctorPhone;

  // ------------------------------------------------------------
  // EMT
  // ------------------------------------------------------------

  final String emtName;

  final String emtPhone;

  // ------------------------------------------------------------
  // LIVE TELEMETRY
  // ------------------------------------------------------------

  double speedKmh;

  int etaMinutes;

  // ------------------------------------------------------------
  // MEDICAL REQUIREMENTS
  // ------------------------------------------------------------

  final bool oxygenRequired;

  final bool stretcherRequired;

  final bool doctorRequired;

  final bool icuRequired;

  final bool ventilatorRequired;

  final bool cardiacMonitorRequired;

  final String specialInstructions;

  final bool wheelchairRequired;

  final bool pediatricPatient;

  final List<String> additionalEquipment;

  final String serviceSubtype;

  List<String> get requiredEquipment => {
    if (oxygenRequired) 'Oxygen cylinder',
    if (cardiacMonitorRequired) 'Cardiac monitor',
    if (ventilatorRequired) 'Transport ventilator',
    if (icuRequired) 'ICU equipment kit',
    if (stretcherRequired) 'Stretcher',
    if (wheelchairRequired) 'Wheelchair',
    ...additionalEquipment,
  }.toList();

  // ------------------------------------------------------------
  // STATUS HELPERS
  // ------------------------------------------------------------

  bool get isActive {
    return const {
      'ASSIGNED',
      'DRIVER_ASSIGNED',
      'PICKUP_STARTED',
      'PATIENT_PICKED_UP',
      'IN_TRANSIT',
      'ARRIVED',
    }.contains(status);
  }

  bool get isCompleted {
    return status == 'SERVICE_COMPLETED';
  }

  String get statusLabel {
    return status.replaceAll('_', ' ');
  }

  // ------------------------------------------------------------
  // ROUTE DISPLAY HELPERS
  // ------------------------------------------------------------

  String get formattedDistance {
    if (estimatedDistanceKm <= 0) {
      return '--';
    }

    return '${estimatedDistanceKm.toStringAsFixed(1)} KM';
  }

  String get formattedDuration {
    if (estimatedDurationMins <= 0) {
      return '--';
    }

    if (estimatedDurationMins < 60) {
      return '$estimatedDurationMins min';
    }

    final hours = estimatedDurationMins ~/ 60;

    final minutes = estimatedDurationMins % 60;

    if (minutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${minutes}m';
  }

  String get formattedRouteProvider {
    if (routeProvider.trim().isEmpty) {
      return '--';
    }

    return routeProvider;
  }
}
