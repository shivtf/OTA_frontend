// lib/features/flights/models/flight_offer.dart
//
// Single source of truth for all flight-related models.
// FlightService lives in core/services/flight_service.dart and imports from here.

class FlightSearchResult {
  final String offerRequestId;
  final int totalOffers;

  FlightSearchResult({
    required this.offerRequestId,
    required this.totalOffers,
  });

  factory FlightSearchResult.fromJson(Map<String, dynamic> j) =>
      FlightSearchResult(
        offerRequestId: j['offerRequestId'] as String? ?? '',
        totalOffers: j['totalOffers'] as int? ?? 0,
      );
}

class OffersResult {
  final int totalOffers;
  final List<FlightOffer> offers;

  OffersResult({required this.totalOffers, required this.offers});

  factory OffersResult.fromJson(Map<String, dynamic> j) {
    final list = j['offers'] as List<dynamic>? ?? [];
    return OffersResult(
      totalOffers: j['totalOffers'] as int? ?? list.length,
      offers: list
          .map((e) => FlightOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FlightOffer — extended with all fields the details screen needs
// ─────────────────────────────────────────────────────────────────────────────

class FlightOffer {
  final String offerId;
  final OfferPricing pricing;
  final OfferConditions? conditions;
  final AirlineInfo? owner;
  final List<FlightSlice> slices;
  final String? expiresAt;

  // Extended fields (populated by GET /flights/offers/:id)
  final bool liveMode;
  final bool partial;
  final PaymentRequirements? paymentRequirements;
  final bool passengerIdentityDocumentsRequired;
  final List<String> supportedPassengerIdentityDocumentTypes;
  final List<AvailableService> availableServices;
  final List<OfferPassenger> passengers;
  final bool refundable;
  final bool changeable;

  FlightOffer({
    required this.offerId,
    required this.pricing,
    this.conditions,
    this.owner,
    required this.slices,
    this.expiresAt,
    this.liveMode = false,
    this.partial = false,
    this.paymentRequirements,
    this.passengerIdentityDocumentsRequired = false,
    this.supportedPassengerIdentityDocumentTypes = const [],
    this.availableServices = const [],
    this.passengers = const [],
    this.refundable = false,
    this.changeable = false,
  });

  // ── Convenience getters ──────────────────────────────────────────────────
  FlightSlice get outbound => slices.first;
  String get airline => owner?.name ?? '';
  String get airlineIata => owner?.iataCode ?? '';
  // alias used by flight_details_screen
  String get airlineIataCode => owner?.iataCode ?? '';
  String get airlineLogoUrl => owner?.logoUrl ?? '';
  String get origin => outbound.origin.iataCode;
  String get destination => outbound.destination.iataCode;
  String get originCity => outbound.origin.cityName;
  String get destinationCity => outbound.destination.cityName;
  int get stops => outbound.stops;
  double get totalAmount => pricing.totalAmount;
  String get currency => pricing.totalCurrency;
  // Convenience: first segment's cabin class name (used in passenger form)
  String get cabinClass {
    final seg = outbound.segments.isNotEmpty ? outbound.segments.first : null;
    final pax =
        seg?.passengers.isNotEmpty == true ? seg!.passengers.first : null;
    return pax?.cabin?.marketingName ?? pax?.cabin?.name ?? 'Economy';
  }

  factory FlightOffer.fromJson(Map<String, dynamic> j) {
    final sliceList = j['slices'] as List<dynamic>? ?? [];
    return FlightOffer(
      offerId: j['offerId'] as String? ?? j['id'] as String? ?? '',
      pricing:
          OfferPricing.fromJson(j['pricing'] as Map<String, dynamic>? ?? {}),
      conditions: j['conditions'] != null
          ? OfferConditions.fromJson(j['conditions'] as Map<String, dynamic>)
          : null,
      owner: j['owner'] != null
          ? AirlineInfo.fromJson(j['owner'] as Map<String, dynamic>)
          : null,
      slices: sliceList
          .map((s) => FlightSlice.fromJson(s as Map<String, dynamic>))
          .toList(),
      expiresAt: j['expiresAt'] as String?,
      liveMode: j['liveMode'] as bool? ?? false,
      partial: j['partial'] as bool? ?? false,
      paymentRequirements: j['paymentRequirements'] != null
          ? PaymentRequirements.fromJson(
              j['paymentRequirements'] as Map<String, dynamic>)
          : null,
      passengerIdentityDocumentsRequired:
          j['passengerIdentityDocumentsRequired'] as bool? ?? false,
      supportedPassengerIdentityDocumentTypes:
          (j['supportedPassengerIdentityDocumentTypes'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      availableServices: (j['availableServices'] as List<dynamic>?)
              ?.map((e) => AvailableService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      passengers: (j['passengers'] as List<dynamic>?)
              ?.map((e) => OfferPassenger.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      refundable: j['refundable'] as bool? ?? false,
      changeable: j['changeable'] as bool? ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OfferPricing — extended with emissions + currency fields
// ─────────────────────────────────────────────────────────────────────────────

class OfferPricing {
  final double baseAmount;
  final String baseCurrency;
  final double taxAmount;
  final String taxCurrency;
  final double totalAmount;
  final String totalCurrency;
  final String? totalEmissionsKg;

  OfferPricing({
    required this.baseAmount,
    this.baseCurrency = 'USD',
    required this.taxAmount,
    this.taxCurrency = 'USD',
    required this.totalAmount,
    required this.totalCurrency,
    this.totalEmissionsKg,
  });

  factory OfferPricing.fromJson(Map<String, dynamic> j) => OfferPricing(
        baseAmount: double.tryParse(j['baseAmount']?.toString() ?? '0') ?? 0,
        baseCurrency: j['baseCurrency'] as String? ?? 'USD',
        taxAmount: double.tryParse(j['taxAmount']?.toString() ?? '0') ?? 0,
        taxCurrency: j['taxCurrency'] as String? ?? 'USD',
        totalAmount: double.tryParse(j['totalAmount']?.toString() ?? '0') ?? 0,
        totalCurrency: j['totalCurrency'] as String? ?? 'USD',
        totalEmissionsKg: j['totalEmissionsKg']?.toString(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// OfferConditions — unchanged, already has all fields screen needs
// ─────────────────────────────────────────────────────────────────────────────

class OfferConditions {
  final bool refundable;
  final bool changeable;
  final String? refundPenaltyAmount;
  final String? refundPenaltyCurrency;
  final String? changePenaltyAmount;
  final String? changePenaltyCurrency;

  OfferConditions({
    required this.refundable,
    required this.changeable,
    this.refundPenaltyAmount,
    this.refundPenaltyCurrency,
    this.changePenaltyAmount,
    this.changePenaltyCurrency,
  });

  factory OfferConditions.fromJson(Map<String, dynamic> j) => OfferConditions(
        refundable: j['refundable'] as bool? ?? false,
        changeable: j['changeable'] as bool? ?? false,
        refundPenaltyAmount: j['refundPenaltyAmount']?.toString(),
        refundPenaltyCurrency: j['refundPenaltyCurrency'] as String?,
        changePenaltyAmount: j['changePenaltyAmount']?.toString(),
        changePenaltyCurrency: j['changePenaltyCurrency'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AirlineInfo — extended with conditionsOfCarriageUrl
// ─────────────────────────────────────────────────────────────────────────────

class AirlineInfo {
  final String id;
  final String iataCode;
  final String name;
  final String logoUrl;
  final String? logoLockupUrl;
  final String? conditionsOfCarriageUrl;

  AirlineInfo({
    required this.id,
    required this.iataCode,
    required this.name,
    this.logoUrl = '',
    this.logoLockupUrl,
    this.conditionsOfCarriageUrl,
  });

  factory AirlineInfo.fromJson(Map<String, dynamic> j) => AirlineInfo(
        id: j['id'] as String? ?? '',
        iataCode: j['iataCode'] as String? ?? '',
        name: j['name'] as String? ?? '',
        logoUrl: j['logoUrl'] as String? ?? '',
        logoLockupUrl: j['logoLockupUrl'] as String?,
        conditionsOfCarriageUrl: j['conditionsOfCarriageUrl'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// FlightSlice — extended with fareBrandName, stops, connections
// ─────────────────────────────────────────────────────────────────────────────

class FlightSlice {
  final String sliceId;
  final AirportInfo origin;
  final AirportInfo destination;
  final String departureAt;
  final String arrivalAt;
  final String duration;
  final List<FlightSegment> segments;

  // Extended fields
  final String? fareBrandName;
  final int connections;

  FlightSlice({
    required this.sliceId,
    required this.origin,
    required this.destination,
    required this.departureAt,
    required this.arrivalAt,
    required this.duration,
    required this.segments,
    this.fareBrandName,
    this.connections = 0,
  });

  // Number of stops = segments - 1 (non-stop = 0)
  int get stops => segments.isEmpty ? 0 : segments.length - 1;

  factory FlightSlice.fromJson(Map<String, dynamic> j) {
    final segList = j['segments'] as List<dynamic>? ?? [];
    return FlightSlice(
      sliceId: j['sliceId'] as String? ?? '',
      origin: AirportInfo.fromJson(j['origin'] as Map<String, dynamic>? ?? {}),
      destination:
          AirportInfo.fromJson(j['destination'] as Map<String, dynamic>? ?? {}),
      departureAt: j['departureAt'] as String? ?? '',
      arrivalAt: j['arrivalAt'] as String? ?? '',
      duration: j['duration'] as String? ?? '',
      segments: segList
          .map((s) => FlightSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      fareBrandName: j['fareBrandName'] as String?,
      connections: j['connections'] as int? ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AirportInfo — extended with airportName, id, latitude, longitude
// ─────────────────────────────────────────────────────────────────────────────

class AirportInfo {
  final String id;
  final String iataCode;
  final String? icaoCode;
  final String? airportName; // mapped from JSON "name"
  final String cityName;
  final String? cityIataCode;
  final String? countryCode;
  final String? timeZone;
  final double? latitude;
  final double? longitude;

  AirportInfo({
    this.id = '',
    required this.iataCode,
    this.icaoCode,
    this.airportName,
    required this.cityName,
    this.cityIataCode,
    this.countryCode,
    this.timeZone,
    this.latitude,
    this.longitude,
  });

  factory AirportInfo.fromJson(Map<String, dynamic> j) => AirportInfo(
        id: j['id'] as String? ?? '',
        iataCode: j['iataCode'] as String? ?? '',
        icaoCode: j['icaoCode'] as String?,
        airportName: j['name'] as String?, // JSON key is "name"
        cityName: j['cityName'] as String? ?? '',
        cityIataCode: j['cityIataCode'] as String?,
        countryCode: j['countryCode'] as String?,
        timeZone: j['timeZone'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// FlightSegment — extended with operatingCarrier, passengers
// ─────────────────────────────────────────────────────────────────────────────

class FlightSegment {
  final String id;
  final AirportInfo origin;
  final AirportInfo destination;
  final String departingAt;
  final String arrivingAt;
  final String duration;
  final String? distance;
  final AirlineInfo? marketingCarrier;
  final String? flightNumber;
  final AirlineInfo? operatingCarrier;
  final String? operatingFlightNumber;
  final String? originTerminal;
  final String? destinationTerminal;
  final List<SegmentPassenger> passengers;

  FlightSegment({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departingAt,
    required this.arrivingAt,
    required this.duration,
    this.distance,
    this.marketingCarrier,
    this.flightNumber,
    this.operatingCarrier,
    this.operatingFlightNumber,
    this.originTerminal,
    this.destinationTerminal,
    this.passengers = const [],
  });

  factory FlightSegment.fromJson(Map<String, dynamic> j) => FlightSegment(
        id: j['id'] as String? ?? '',
        origin:
            AirportInfo.fromJson(j['origin'] as Map<String, dynamic>? ?? {}),
        destination: AirportInfo.fromJson(
            j['destination'] as Map<String, dynamic>? ?? {}),
        departingAt: j['departingAt'] as String? ?? '',
        arrivingAt: j['arrivingAt'] as String? ?? '',
        duration: j['duration'] as String? ?? '',
        distance: j['distance']?.toString(),
        marketingCarrier: j['marketingCarrier'] != null
            ? AirlineInfo.fromJson(
                j['marketingCarrier'] as Map<String, dynamic>)
            : null,
        flightNumber: j['marketingCarrierFlightNumber']?.toString(),
        operatingCarrier: j['operatingCarrier'] != null
            ? AirlineInfo.fromJson(
                j['operatingCarrier'] as Map<String, dynamic>)
            : null,
        operatingFlightNumber: j['operatingCarrierFlightNumber']?.toString(),
        originTerminal: j['originTerminal'] as String?,
        destinationTerminal: j['destinationTerminal'] as String?,
        passengers: (j['passengers'] as List<dynamic>?)
                ?.map(
                    (e) => SegmentPassenger.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SegmentPassenger (cabin class, baggage, amenities per passenger per segment)
// ─────────────────────────────────────────────────────────────────────────────

class SegmentPassenger {
  final String passengerId;
  final String? fareBasisCode;
  final String? cabinClass;
  final String? cabinClassMarketingName;
  final CabinInfo? cabin;
  final List<Map<String, dynamic>> baggages;

  SegmentPassenger({
    required this.passengerId,
    this.fareBasisCode,
    this.cabinClass,
    this.cabinClassMarketingName,
    this.cabin,
    this.baggages = const [],
  });

  factory SegmentPassenger.fromJson(Map<String, dynamic> j) => SegmentPassenger(
        passengerId: j['passengerId'] as String? ?? '',
        fareBasisCode: j['fareBasisCode'] as String?,
        cabinClass: j['cabinClass'] as String?,
        cabinClassMarketingName: j['cabinClassMarketingName'] as String?,
        cabin: j['cabin'] != null
            ? CabinInfo.fromJson(j['cabin'] as Map<String, dynamic>)
            : null,
        baggages: (j['baggages'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// CabinInfo + CabinAmenities
// ─────────────────────────────────────────────────────────────────────────────

class CabinInfo {
  final String? name;
  final String? marketingName;
  final CabinAmenities? amenities;

  CabinInfo({this.name, this.marketingName, this.amenities});

  factory CabinInfo.fromJson(Map<String, dynamic> j) => CabinInfo(
        name: j['name'] as String?,
        marketingName: j['marketingName'] as String?,
        amenities: j['amenities'] != null
            ? CabinAmenities.fromJson(j['amenities'] as Map<String, dynamic>)
            : null,
      );
}

class CabinAmenities {
  final Map<String, dynamic>? wifi;
  final Map<String, dynamic>? seat;
  final Map<String, dynamic>? power;

  CabinAmenities({this.wifi, this.seat, this.power});

  factory CabinAmenities.fromJson(Map<String, dynamic> j) => CabinAmenities(
        wifi: j['wifi'] != null
            ? Map<String, dynamic>.from(j['wifi'] as Map)
            : null,
        seat: j['seat'] != null
            ? Map<String, dynamic>.from(j['seat'] as Map)
            : null,
        power: j['power'] != null
            ? Map<String, dynamic>.from(j['power'] as Map)
            : null,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PaymentRequirements
// ─────────────────────────────────────────────────────────────────────────────

class PaymentRequirements {
  final bool? requiresInstantPayment;
  final String? priceGuaranteeExpiresAt;
  final String? paymentRequiredBy;

  PaymentRequirements({
    this.requiresInstantPayment,
    this.priceGuaranteeExpiresAt,
    this.paymentRequiredBy,
  });

  factory PaymentRequirements.fromJson(Map<String, dynamic> j) =>
      PaymentRequirements(
        requiresInstantPayment: j['requiresInstantPayment'] as bool?,
        priceGuaranteeExpiresAt: j['priceGuaranteeExpiresAt'] as String?,
        paymentRequiredBy: j['paymentRequiredBy'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AvailableService (baggage add-ons, seat upgrades, etc.)
// ─────────────────────────────────────────────────────────────────────────────

class AvailableService {
  final String id;
  final String type;
  final String? totalAmount;
  final String? totalCurrency;
  final int? maximumQuantity;
  final List<String> passengerIds;
  final List<String> segmentIds;

  AvailableService({
    required this.id,
    required this.type,
    this.totalAmount,
    this.totalCurrency,
    this.maximumQuantity,
    this.passengerIds = const [],
    this.segmentIds = const [],
  });

  factory AvailableService.fromJson(Map<String, dynamic> j) => AvailableService(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? '',
        totalAmount: j['totalAmount']?.toString(),
        totalCurrency: j['totalCurrency'] as String?,
        maximumQuantity: j['maximumQuantity'] as int?,
        passengerIds: (j['passengerIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        segmentIds: (j['segmentIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// OfferPassenger (offer-level passenger info)
// ─────────────────────────────────────────────────────────────────────────────

class OfferPassenger {
  final String id;
  final String type;
  final int? age;
  final String? givenName;
  final String? familyName;

  OfferPassenger({
    required this.id,
    required this.type,
    this.age,
    this.givenName,
    this.familyName,
  });

  factory OfferPassenger.fromJson(Map<String, dynamic> j) => OfferPassenger(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? 'adult',
        age: j['age'] as int?,
        givenName: j['givenName'] as String?,
        familyName: j['familyName'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking models (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class FlightBooking {
  final String bookingId;
  final String bookingRef;
  final OfferPricing pricing;
  final double amount;
  final String currency;
  final OfferConditions? conditions;
  final String? offerExpiresAt;
  final String status;

  FlightBooking({
    required this.bookingId,
    required this.bookingRef,
    required this.pricing,
    required this.amount,
    required this.currency,
    this.conditions,
    this.offerExpiresAt,
    this.status = 'PENDING_PAYMENT',
  });

  factory FlightBooking.fromJson(Map<String, dynamic> j) => FlightBooking(
        bookingId: j['bookingId'] as String? ?? j['id'] as String? ?? '',
        bookingRef: j['bookingRef'] as String? ?? '',
        pricing: j['pricing'] != null
            ? OfferPricing.fromJson(j['pricing'] as Map<String, dynamic>)
            : OfferPricing.fromJson({}),
        amount: double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
        currency: j['currency'] as String? ?? 'USD',
        conditions: j['conditions'] != null
            ? OfferConditions.fromJson(j['conditions'] as Map<String, dynamic>)
            : null,
        offerExpiresAt: j['offerExpiresAt'] as String?,
        status: j['status'] as String? ?? 'PENDING_PAYMENT',
      );
}

class FlightBookingListItem {
  final String id;
  final String bookingRef;
  final String status;
  final double totalAmount;
  final String currency;
  final DateTime createdAt;

  FlightBookingListItem({
    required this.id,
    required this.bookingRef,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.createdAt,
  });

  factory FlightBookingListItem.fromJson(Map<String, dynamic> j) =>
      FlightBookingListItem(
        id: j['id'] as String? ?? '',
        bookingRef:
            j['booking_ref'] as String? ?? j['bookingRef'] as String? ?? '',
        status: j['status'] as String? ?? '',
        totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String? ?? 'USD',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class PassengerInput {
  final String type;
  final String title;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String gender;
  final String email;
  final String phone;
  final String? passportNumber;
  final String? issuingCountry;
  final String? passportExpiryDate;

  PassengerInput({
    this.type = 'adult',
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.email,
    required this.phone,
    this.passportNumber,
    this.issuingCountry,
    this.passportExpiryDate,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'title': title,
        'email': email,
        'phone': phone,
        'passengerType': type,
        if (passportNumber != null) 'passportNumber': passportNumber,
        if (issuingCountry != null) 'issuingCountry': issuingCountry,
        if (passportExpiryDate != null) 'passportExpiry': passportExpiryDate,
      };
}

class SeatMapResult {
  final bool available;
  final List<dynamic> seatMaps;
  final String? reason;

  SeatMapResult({
    required this.available,
    required this.seatMaps,
    this.reason,
  });

  factory SeatMapResult.fromJson(Map<String, dynamic> j) => SeatMapResult(
        available: j['available'] as bool? ?? false,
        seatMaps: j['seatMaps'] as List<dynamic>? ?? [],
        reason: j['reason'] as String?,
      );
}
