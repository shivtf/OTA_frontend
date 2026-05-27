
class CarModel {
  final String id;
  final String name;
  final String brand;
  final String category; // Economy, Compact, SUV, Luxury, Van
  final double pricePerDay;
  final int seats;
  final String transmission; // Auto, Manual
  final String fuelType; // Petrol, Diesel, Electric, Hybrid
  final int luggage;
  final double rating;
  final int reviewCount;
  final List<String> features;
  final String emoji;
  final bool unlimitedMileage;
  final bool freeCancellation;
  final String rentalCompany;
  final String pickupLocation;
  final String dropoffLocation;

  const CarModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.pricePerDay,
    required this.seats,
    required this.transmission,
    required this.fuelType,
    required this.luggage,
    required this.rating,
    required this.reviewCount,
    required this.features,
    required this.emoji,
    required this.unlimitedMileage,
    required this.freeCancellation,
    required this.rentalCompany,
    required this.pickupLocation,
    required this.dropoffLocation,
  });
}

class CarData {
  static List<CarModel> search({String location = 'Dubai'}) {
    return [
      CarModel(
        id: 'C001',
        name: 'Corolla',
        brand: 'Toyota',
        category: 'Economy',
        pricePerDay: 38.0,
        seats: 5,
        transmission: 'Auto',
        fuelType: 'Petrol',
        luggage: 2,
        rating: 4.5,
        reviewCount: 2341,
        features: ['AC', 'Bluetooth', 'USB', 'Backup Camera'],
        emoji: '🚗',
        unlimitedMileage: true,
        freeCancellation: true,
        rentalCompany: 'Budget',
        pickupLocation: location,
        dropoffLocation: location,
      ),
      CarModel(
        id: 'C002',
        name: 'Camry',
        brand: 'Toyota',
        category: 'Compact',
        pricePerDay: 55.0,
        seats: 5,
        transmission: 'Auto',
        fuelType: 'Hybrid',
        luggage: 3,
        rating: 4.7,
        reviewCount: 1893,
        features: ['AC', 'Bluetooth', 'USB', 'Apple CarPlay', 'Lane Assist'],
        emoji: '🚙',
        unlimitedMileage: true,
        freeCancellation: true,
        rentalCompany: 'Hertz',
        pickupLocation: location,
        dropoffLocation: location,
      ),
      CarModel(
        id: 'C003',
        name: 'Fortuner',
        brand: 'Toyota',
        category: 'SUV',
        pricePerDay: 89.0,
        seats: 7,
        transmission: 'Auto',
        fuelType: 'Diesel',
        luggage: 5,
        rating: 4.8,
        reviewCount: 987,
        features: ['AC', 'Bluetooth', 'USB', '4WD', 'Sunroof', 'GPS'],
        emoji: '🚐',
        unlimitedMileage: false,
        freeCancellation: true,
        rentalCompany: 'Avis',
        pickupLocation: location,
        dropoffLocation: location,
      ),
      CarModel(
        id: 'C004',
        name: 'Model 3',
        brand: 'Tesla',
        category: 'Luxury',
        pricePerDay: 145.0,
        seats: 5,
        transmission: 'Auto',
        fuelType: 'Electric',
        luggage: 3,
        rating: 4.9,
        reviewCount: 654,
        features: ['Autopilot', 'AC', 'Premium Sound', 'Supercharger Access', 'OTA Updates'],
        emoji: '⚡',
        unlimitedMileage: false,
        freeCancellation: false,
        rentalCompany: 'Enterprise',
        pickupLocation: location,
        dropoffLocation: location,
      ),
      CarModel(
        id: 'C005',
        name: 'G-Class',
        brand: 'Mercedes',
        category: 'Luxury',
        pricePerDay: 320.0,
        seats: 5,
        transmission: 'Auto',
        fuelType: 'Petrol',
        luggage: 4,
        rating: 4.9,
        reviewCount: 421,
        features: ['AC', 'Burmester Sound', 'Sunroof', '4MATIC', 'Massage Seats', 'Night Vision'],
        emoji: '🏎️',
        unlimitedMileage: false,
        freeCancellation: false,
        rentalCompany: 'Sixt',
        pickupLocation: location,
        dropoffLocation: location,
      ),
      CarModel(
        id: 'C006',
        name: 'Carnival',
        brand: 'Kia',
        category: 'Van',
        pricePerDay: 72.0,
        seats: 8,
        transmission: 'Auto',
        fuelType: 'Diesel',
        luggage: 6,
        rating: 4.4,
        reviewCount: 1102,
        features: ['AC', 'Bluetooth', 'USB', 'Sliding Doors', 'Rear Entertainment'],
        emoji: '🚌',
        unlimitedMileage: true,
        freeCancellation: true,
        rentalCompany: 'Budget',
        pickupLocation: location,
        dropoffLocation: location,
      ),
    ];
  }
}