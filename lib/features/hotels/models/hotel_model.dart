
class HotelModel {
  final String id;
  final String name;
  final String city;
  final String country;
  final String address;
  final double rating;
  final int reviewCount;
  final double pricePerNight;
  final String category; // Hotel, Resort, Boutique, Hostel
  final List<String> amenities;
  final List<String> images; // emoji placeholders
  final String description;
  final bool isFeatured;
  final bool breakfastIncluded;
  final bool freeCancellation;
  final double distanceFromCenter; // km
  final String checkIn;
  final String checkOut;

  const HotelModel({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.pricePerNight,
    required this.category,
    required this.amenities,
    required this.images,
    required this.description,
    required this.isFeatured,
    required this.breakfastIncluded,
    required this.freeCancellation,
    required this.distanceFromCenter,
    required this.checkIn,
    required this.checkOut,
  });
}

class HotelData {
  static List<HotelModel> search({String city = 'Dubai'}) {
    return [
      HotelModel(
        id: 'H001',
        name: 'Burj Al Arab Jumeirah',
        city: city,
        country: 'UAE',
        address: 'Jumeirah St, Dubai',
        rating: 4.9,
        reviewCount: 3842,
        pricePerNight: 899.0,
        category: 'Resort',
        amenities: ['Pool', 'Spa', 'Wi-Fi', 'Restaurant', 'Gym', 'Bar', 'Concierge', 'Room Service'],
        images: ['🏨', '🏊', '🍽️'],
        description:
        'An iconic sail-shaped silhouette dominates the Dubai skyline. Experience unmatched luxury with butler service, private beach, and world-class dining. Each suite offers panoramic views of the Arabian Gulf.',
        isFeatured: true,
        breakfastIncluded: true,
        freeCancellation: true,
        distanceFromCenter: 2.3,
        checkIn: '3:00 PM',
        checkOut: '12:00 PM',
      ),
      HotelModel(
        id: 'H002',
        name: 'Atlantis The Palm',
        city: city,
        country: 'UAE',
        address: 'Crescent Rd, Palm Jumeirah',
        rating: 4.7,
        reviewCount: 5210,
        pricePerNight: 620.0,
        category: 'Resort',
        amenities: ['Water Park', 'Pool', 'Spa', 'Wi-Fi', 'Restaurant', 'Beach', 'Kids Club'],
        images: ['🌴', '🏊', '🐠'],
        description:
        'Set on the iconic Palm Jumeirah, Atlantis offers an extraordinary aquatic adventure. Home to Aquaventure Waterpark and The Lost Chambers Aquarium, this resort promises an unforgettable family getaway.',
        isFeatured: true,
        breakfastIncluded: true,
        freeCancellation: false,
        distanceFromCenter: 5.8,
        checkIn: '3:00 PM',
        checkOut: '12:00 PM',
      ),
      HotelModel(
        id: 'H003',
        name: 'Address Downtown',
        city: city,
        country: 'UAE',
        address: 'Sheikh Mohammed Bin Rashid Blvd',
        rating: 4.8,
        reviewCount: 2971,
        pricePerNight: 480.0,
        category: 'Hotel',
        amenities: ['Pool', 'Spa', 'Wi-Fi', 'Restaurant', 'Gym', 'Concierge', 'Valet'],
        images: ['🏙️', '🌆', '🍾'],
        description:
        'Steps from the Burj Khalifa and Dubai Mall, Address Downtown is the epitome of urban luxury. Stunning views of the Dubai Fountain from every room.',
        isFeatured: false,
        breakfastIncluded: false,
        freeCancellation: true,
        distanceFromCenter: 0.4,
        checkIn: '2:00 PM',
        checkOut: '11:00 AM',
      ),
      HotelModel(
        id: 'H004',
        name: 'Rove Downtown Dubai',
        city: city,
        country: 'UAE',
        address: 'Al Makhool St, Downtown',
        rating: 4.4,
        reviewCount: 8103,
        pricePerNight: 145.0,
        category: 'Boutique',
        amenities: ['Pool', 'Wi-Fi', 'Restaurant', 'Gym', 'Self Laundry'],
        images: ['🏬', '☕', '🛋️'],
        description:
        'A smart, design-forward hotel in the heart of Downtown Dubai. Rove is the perfect base for exploring the city\'s most iconic attractions on a comfortable budget.',
        isFeatured: false,
        breakfastIncluded: false,
        freeCancellation: true,
        distanceFromCenter: 0.9,
        checkIn: '3:00 PM',
        checkOut: '12:00 PM',
      ),
      HotelModel(
        id: 'H005',
        name: 'One&Only Royal Mirage',
        city: city,
        country: 'UAE',
        address: 'King Salman Bin Abdulaziz Al Saud St',
        rating: 4.8,
        reviewCount: 1654,
        pricePerNight: 760.0,
        category: 'Resort',
        amenities: ['Private Beach', 'Pool', 'Spa', 'Wi-Fi', 'Restaurant', 'Tennis', 'Watersports'],
        images: ['🏝️', '🌅', '🕌'],
        description:
        'An Arabesque palace set among lush gardens with 1 km of private beach. A rare blend of traditional architecture and contemporary luxury along Dubai\'s glittering coast.',
        isFeatured: true,
        breakfastIncluded: true,
        freeCancellation: true,
        distanceFromCenter: 3.5,
        checkIn: '3:00 PM',
        checkOut: '12:00 PM',
      ),
    ];
  }

  static List<Map<String, dynamic>> popularCities = [
    {'city': 'Dubai', 'country': 'UAE', 'emoji': '🏙️', 'hotels': 1240},
    {'city': 'Paris', 'country': 'France', 'emoji': '🗼', 'hotels': 2810},
    {'city': 'Tokyo', 'country': 'Japan', 'emoji': '⛩️', 'hotels': 1890},
    {'city': 'New York', 'country': 'USA', 'emoji': '🗽', 'hotels': 3120},
    {'city': 'Bali', 'country': 'Indonesia', 'emoji': '🌴', 'hotels': 980},
  ];
}