// lib/features/payment/models/payment_model.dart

enum BookingType { flight, hotel, car }

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
  final double serviceFee;
  final String emoji;

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
    required this.serviceFee,
    required this.emoji,
  });

  double get total => basePrice + taxAmount + serviceFee;

  String get typeLabel {
    switch (type) {
      case BookingType.flight: return 'Flight';
      case BookingType.hotel: return 'Hotel';
      case BookingType.car: return 'Car Rental';
    }
  }
}

enum PaymentStatus { idle, processing, success, failed }

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
      case 'visa': return '💳';
      case 'mastercard': return '🔴';
      case 'amex': return '🟦';
      default: return '💳';
    }
  }
}

// Dummy saved cards
const List<SavedCard> dummySavedCards = [
  SavedCard(id: 'card_1', last4: '4242', brand: 'Visa', expiry: '12/26', isDefault: true),
  SavedCard(id: 'card_2', last4: '5555', brand: 'Mastercard', expiry: '08/25', isDefault: false),
];
