// lib/features/payment/models/payment_model.dart
//
// All UI-layer data models for the payment feature.
// BookingItem is the single DTO the PaymentScreen consumes —
// regardless of which payment provider is active.
//
// NEW additions vs original:
//   • BookingItem.bookingId, .currency, .duffelOfferId
//   • BookingItem.fromFlightBooking() factory
//   • PassengerSummary  — lightweight display model for the checkout page
//   • PaymentScreenState — enum that drives the UI state machine

enum BookingType { flight, hotel, car }

// ── BookingItem ───────────────────────────────────────────────────────────────

class BookingItem {
  final BookingType type;
  final String title;
  final String subtitle;
  final String detail1Label;
  final String detail1Value;
  final String detail2Label;
  final String detail2Value;
  final double basePrice;
  final double taxAmount;
  // final double serviceFee;
  final String emoji;

  /// The pending booking ID from POST /flights/book — sent to PaymentController.
  final String? bookingId;

  /// ISO-4217 currency code (default USD).
  final String currency;

  /// Duffel offer ID — required by DuffelPaymentProvider.
  final String? duffelOfferId;

  /// Passenger display summaries shown in checkout breakdown.
  final List<PassengerSummary> passengers;

  const BookingItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.detail1Label,
    required this.detail1Value,
    required this.detail2Label,
    required this.detail2Value,
    required this.basePrice,
    required this.taxAmount,
    // required this.serviceFee,
    required this.emoji,
    this.bookingId,
    this.currency = 'USD',
    this.duffelOfferId,
    this.passengers = const [],
  });
  double get total => basePrice + taxAmount;
  // double get total => basePrice + taxAmount + serviceFee;

  String get typeLabel {
    switch (type) {
      case BookingType.flight:
        return 'Flight';
      case BookingType.hotel:
        return 'Hotel';
      case BookingType.car:
        return 'Car Rental';
    }
  }

  // ── Bridge factory: FlightBooking → BookingItem ───────────────────────────
  // Used in FlightDetailsScreen / PassengerFormScreen before pushing /payment.
  //
  // Example:
  //   final item = BookingItem.fromFlightBooking(
  //     bookingId:        booking.bookingId,
  //     baseAmount:       offer.pricing.baseAmount,
  //     taxAmount:        offer.pricing.taxAmount,
  //     serviceFee:       15.00,
  //     currency:         offer.currency,
  //     flightTitle:      '${offer.airline}  ${offer.origin} → ${offer.destination}',
  //     flightSubtitle:   '${departureDate}  ·  ${passengerCount} Adult  ·  ${cabinClass}',
  //     departureTime:    '08:30 AM',
  //     arrivalTime:      '11:15 AM',
  //     duffelOfferId:    offer.offerId,
  //     passengers:       passengerSummaries,
  //   );
  factory BookingItem.fromFlightBooking({
    required String bookingId,
    required double baseAmount,
    required double taxAmount,
    // required double serviceFee,
    required String currency,
    required String flightTitle,
    required String flightSubtitle,
    required String departureTime,
    required String arrivalTime,
    String? duffelOfferId,
    List<PassengerSummary> passengers = const [],
  }) =>
      BookingItem(
        type: BookingType.flight,
        title: flightTitle,
        subtitle: flightSubtitle,
        detail1Label: 'Departure',
        detail1Value: departureTime,
        detail2Label: 'Arrival',
        detail2Value: arrivalTime,
        basePrice: baseAmount,
        taxAmount: taxAmount,
        // serviceFee: serviceFee,
        emoji: '✈️',
        bookingId: bookingId,
        currency: currency,
        duffelOfferId: duffelOfferId,
        passengers: passengers,
      );
}

// ── PassengerSummary ──────────────────────────────────────────────────────────

class PassengerSummary {
  final String name;
  final String type; // 'adult' | 'child' | 'infant_without_seat'
  final String? seatNumber;

  const PassengerSummary({
    required this.name,
    this.type = 'adult',
    this.seatNumber,
  });

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'child':
        return 'Child';
      case 'infant_without_seat':
        return 'Infant';
      default:
        return 'Adult';
    }
  }
}

// ── PaymentScreenState ────────────────────────────────────────────────────────
// Controls the PaymentScreen UI state machine. This is purely a UI enum —
// never leaked to provider implementations.

enum PaymentScreenState {
  idle,
  processing,
  success,
  failure,
  cancelled,
  retrying,
}

// ── SavedCard ─────────────────────────────────────────────────────────────────

class SavedCard {
  final String id;
  final String last4;
  final String brand;
  final String expiry;
  final bool isDefault;

  const SavedCard({
    required this.id,
    required this.last4,
    required this.brand,
    required this.expiry,
    required this.isDefault,
  });

  String get brandIcon {
    switch (brand.toLowerCase()) {
      case 'visa':
        return '💳';
      case 'mastercard':
        return '🔴';
      case 'amex':
        return '🟦';
      default:
        return '💳';
    }
  }
}

// Dummy saved cards — replace with real data from your backend
const List<SavedCard> dummySavedCards = [
  SavedCard(
    id: 'card_1',
    last4: '4242',
    brand: 'Visa',
    expiry: '12/26',
    isDefault: true,
  ),
  SavedCard(
    id: 'card_2',
    last4: '5555',
    brand: 'Mastercard',
    expiry: '08/25',
    isDefault: false,
  ),
];
