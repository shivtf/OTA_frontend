// lib/features/flights/change_request/models/flight_change_models.dart
//
// All models for the 3-step flight change request flow.

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Create Change Request
// ─────────────────────────────────────────────────────────────────────────────

class ChangeRequestSliceInput {
  final String sliceId;
  final String origin;
  final String destination;
  final String departureDate; // YYYY-MM-DD
  final String cabinClass; // economy | premium_economy | business | first

  const ChangeRequestSliceInput({
    required this.sliceId,
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.cabinClass = 'economy',
  });

  Map<String, dynamic> toJson() => {
    'slice_id': sliceId,
    'origin': origin.toUpperCase(),
    'destination': destination.toUpperCase(),
    'departure_date': departureDate,
    'cabin_class': cabinClass,
  };
}

class ChangeRequest {
  final String id; // ocr_…
  final String orderId;
  final bool liveMode;
  final String createdAt;

  const ChangeRequest({
    required this.id,
    required this.orderId,
    required this.liveMode,
    required this.createdAt,
  });

  factory ChangeRequest.fromJson(Map<String, dynamic> j) => ChangeRequest(
    id: j['id'] as String? ?? '',
    orderId: j['order_id'] as String? ?? '',
    liveMode: j['live_mode'] as bool? ?? false,
    createdAt: j['created_at'] as String? ?? '',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Change Offers
// ─────────────────────────────────────────────────────────────────────────────

class ChangeOffer {
  final String id; // oco_…
  final String changeTotalAmount;
  final String changeTotalCurrency;
  final String newTotalAmount;
  final String newTotalCurrency;
  final String penaltyTotalAmount;
  final String penaltyTotalCurrency;
  final String expiresAt;
  final List<ChangeOfferSlice> addSlices;
  final List<ChangeOfferSliceRemove> removeSlices;
  final ChangeOfferConditions? conditions;

  const ChangeOffer({
    required this.id,
    required this.changeTotalAmount,
    required this.changeTotalCurrency,
    required this.newTotalAmount,
    required this.newTotalCurrency,
    required this.penaltyTotalAmount,
    required this.penaltyTotalCurrency,
    required this.expiresAt,
    required this.addSlices,
    required this.removeSlices,
    this.conditions,
  });

  factory ChangeOffer.fromJson(Map<String, dynamic> j) {
    final slices = j['slices'] as Map<String, dynamic>? ?? {};
    final addList = slices['add'] as List<dynamic>? ?? [];
    final removeList = slices['remove'] as List<dynamic>? ?? [];

    return ChangeOffer(
      id: j['id'] as String? ?? '',
      changeTotalAmount: j['change_total_amount']?.toString() ?? '0.00',
      changeTotalCurrency: j['change_total_currency'] as String? ?? 'GBP',
      newTotalAmount: j['new_total_amount']?.toString() ?? '0.00',
      newTotalCurrency: j['new_total_currency'] as String? ?? 'GBP',
      penaltyTotalAmount: j['penalty_total_amount']?.toString() ?? '0.00',
      penaltyTotalCurrency: j['penalty_total_currency'] as String? ?? 'GBP',
      expiresAt: j['expires_at'] as String? ?? '',
      addSlices: addList
          .map((e) => ChangeOfferSlice.fromJson(e as Map<String, dynamic>))
          .toList(),
      removeSlices: removeList
          .map((e) =>
          ChangeOfferSliceRemove.fromJson(e as Map<String, dynamic>))
          .toList(),
      conditions: j['conditions'] != null
          ? ChangeOfferConditions.fromJson(
          j['conditions'] as Map<String, dynamic>)
          : null,
    );
  }

  // Convenience: extra charge as double
  double get changeAmount =>
      double.tryParse(changeTotalAmount) ?? 0.0;
  double get newTotal => double.tryParse(newTotalAmount) ?? 0.0;

  // How many minutes until expiry
  Duration get timeUntilExpiry {
    try {
      final expiry = DateTime.parse(expiresAt);
      final diff = expiry.difference(DateTime.now());
      return diff.isNegative ? Duration.zero : diff;
    } catch (_) {
      return Duration.zero;
    }
  }

  bool get isExpired => timeUntilExpiry == Duration.zero;
}

class ChangeOfferSlice {
  final String id;
  final ChangeAirport origin;
  final ChangeAirport destination;
  final String duration; // ISO 8601 e.g. PT07H30M
  final String? fareBrandName;
  final List<ChangeSegment> segments;

  const ChangeOfferSlice({
    required this.id,
    required this.origin,
    required this.destination,
    required this.duration,
    this.fareBrandName,
    required this.segments,
  });

  factory ChangeOfferSlice.fromJson(Map<String, dynamic> j) {
    final segList = j['segments'] as List<dynamic>? ?? [];
    return ChangeOfferSlice(
      id: j['id'] as String? ?? '',
      origin: ChangeAirport.fromJson(
          j['origin'] as Map<String, dynamic>? ?? {}),
      destination: ChangeAirport.fromJson(
          j['destination'] as Map<String, dynamic>? ?? {}),
      duration: j['duration'] as String? ?? '',
      fareBrandName: j['fare_brand_name'] as String?,
      segments: segList
          .map((e) => ChangeSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // Parse ISO 8601 duration to human-readable
  String get durationHuman {
    final r = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?');
    final m = r.firstMatch(duration);
    if (m == null) return duration;
    final h = m.group(1) ?? '0';
    final min = m.group(2) ?? '0';
    return '${h}h ${min}m';
  }
}

class ChangeOfferSliceRemove {
  final String id;
  const ChangeOfferSliceRemove({required this.id});
  factory ChangeOfferSliceRemove.fromJson(Map<String, dynamic> j) =>
      ChangeOfferSliceRemove(id: j['id'] as String? ?? '');
}

class ChangeAirport {
  final String iataCode;
  final String name;
  final String cityName;

  const ChangeAirport({
    required this.iataCode,
    required this.name,
    required this.cityName,
  });

  factory ChangeAirport.fromJson(Map<String, dynamic> j) => ChangeAirport(
    iataCode: j['iata_code'] as String? ?? '',
    name: j['name'] as String? ?? '',
    cityName: j['city_name'] as String? ?? '',
  );
}

class ChangeSegment {
  final String departingAt;
  final String arrivingAt;
  final ChangeCarrier marketingCarrier;
  final String marketingCarrierFlightNumber;
  final String? aircraftName;

  const ChangeSegment({
    required this.departingAt,
    required this.arrivingAt,
    required this.marketingCarrier,
    required this.marketingCarrierFlightNumber,
    this.aircraftName,
  });

  factory ChangeSegment.fromJson(Map<String, dynamic> j) => ChangeSegment(
    departingAt: j['departing_at'] as String? ?? '',
    arrivingAt: j['arriving_at'] as String? ?? '',
    marketingCarrier: ChangeCarrier.fromJson(
        j['marketing_carrier'] as Map<String, dynamic>? ?? {}),
    marketingCarrierFlightNumber:
    j['marketing_carrier_flight_number'] as String? ?? '',
    aircraftName:
    (j['aircraft'] as Map<String, dynamic>?)?['name'] as String?,
  );

  DateTime? get departingDateTime {
    try {
      return DateTime.parse(departingAt);
    } catch (_) {
      return null;
    }
  }

  DateTime? get arrivingDateTime {
    try {
      return DateTime.parse(arrivingAt);
    } catch (_) {
      return null;
    }
  }
}

class ChangeCarrier {
  final String iataCode;
  final String name;

  const ChangeCarrier({required this.iataCode, required this.name});

  factory ChangeCarrier.fromJson(Map<String, dynamic> j) => ChangeCarrier(
    iataCode: j['iata_code'] as String? ?? '',
    name: j['name'] as String? ?? '',
  );
}

class ChangeOfferConditions {
  final bool changeAllowed;
  final String? changePenaltyAmount;
  final String? changePenaltyCurrency;
  final bool refundAllowed;
  final String? refundPenaltyAmount;
  final String? refundPenaltyCurrency;

  const ChangeOfferConditions({
    required this.changeAllowed,
    this.changePenaltyAmount,
    this.changePenaltyCurrency,
    required this.refundAllowed,
    this.refundPenaltyAmount,
    this.refundPenaltyCurrency,
  });

  factory ChangeOfferConditions.fromJson(Map<String, dynamic> j) {
    final change =
        j['change_before_departure'] as Map<String, dynamic>? ?? {};
    final refund =
        j['refund_before_departure'] as Map<String, dynamic>? ?? {};
    return ChangeOfferConditions(
      changeAllowed: change['allowed'] as bool? ?? false,
      changePenaltyAmount: change['penalty_amount']?.toString(),
      changePenaltyCurrency: change['penalty_currency'] as String?,
      refundAllowed: refund['allowed'] as bool? ?? false,
      refundPenaltyAmount: refund['penalty_amount']?.toString(),
      refundPenaltyCurrency: refund['penalty_currency'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Confirm Change
// ─────────────────────────────────────────────────────────────────────────────

class ConfirmedChange {
  final String id; // oce_…
  final String orderId;
  final String changeTotalAmount;
  final String changeTotalCurrency;
  final String newTotalAmount;
  final String newTotalCurrency;

  const ConfirmedChange({
    required this.id,
    required this.orderId,
    required this.changeTotalAmount,
    required this.changeTotalCurrency,
    required this.newTotalAmount,
    required this.newTotalCurrency,
  });

  factory ConfirmedChange.fromJson(Map<String, dynamic> j) => ConfirmedChange(
    id: j['id'] as String? ?? '',
    orderId: j['order_id'] as String? ?? '',
    changeTotalAmount: j['change_total_amount']?.toString() ?? '0.00',
    changeTotalCurrency: j['change_total_currency'] as String? ?? 'GBP',
    newTotalAmount: j['new_total_amount']?.toString() ?? '0.00',
    newTotalCurrency: j['new_total_currency'] as String? ?? 'GBP',
  );
}
