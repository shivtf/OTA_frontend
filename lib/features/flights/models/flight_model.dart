// lib/features/flights/models/flight_model.dart

class FlightModel {
  final String id;
  final String airline;
  final String airlineCode;
  final String from;
  final String fromCity;
  final String to;
  final String toCity;
  final String departure;
  final String arrival;
  final String duration;
  final int stops;
  final double price;
  final String cabin;
  final int seatsLeft;
  final double rating;
  final bool isRefundable;
  final bool hasMeal;
  final bool hasWifi;
  final bool hasEntertainment;
  final String aircraft;
  final List<String> amenities;

  const FlightModel({
    required this.id,
    required this.airline,
    required this.airlineCode,
    required this.from,
    required this.fromCity,
    required this.to,
    required this.toCity,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.stops,
    required this.price,
    required this.cabin,
    required this.seatsLeft,
    required this.rating,
    required this.isRefundable,
    required this.hasMeal,
    required this.hasWifi,
    required this.hasEntertainment,
    required this.aircraft,
    required this.amenities,
  });
}

// Dummy flight data
class FlightData {
  static List<FlightModel> search({
    required String from,
    required String to,
  }) {
    return [
      FlightModel(
        id: 'FL001',
        airline: 'Emirates',
        airlineCode: 'EK',
        from: from.isEmpty ? 'DXB' : from,
        fromCity: 'Dubai',
        to: to.isEmpty ? 'LHR' : to,
        toCity: 'London',
        departure: '08:30',
        arrival: '13:15',
        duration: '7h 45m',
        stops: 0,
        price: 542.00,
        cabin: 'Economy',
        seatsLeft: 4,
        rating: 4.8,
        isRefundable: true,
        hasMeal: true,
        hasWifi: true,
        hasEntertainment: true,
        aircraft: 'Boeing 777-300ER',
        amenities: ['Meal', 'Wi-Fi', 'Entertainment', 'USB Charging', '30kg Baggage'],
      ),
      FlightModel(
        id: 'FL002',
        airline: 'Qatar Airways',
        airlineCode: 'QR',
        from: from.isEmpty ? 'DOH' : from,
        fromCity: 'Doha',
        to: to.isEmpty ? 'LHR' : to,
        toCity: 'London',
        departure: '10:00',
        arrival: '16:20',
        duration: '8h 20m',
        stops: 0,
        price: 489.00,
        cabin: 'Economy',
        seatsLeft: 9,
        rating: 4.9,
        isRefundable: true,
        hasMeal: true,
        hasWifi: true,
        hasEntertainment: true,
        aircraft: 'Airbus A350-900',
        amenities: ['Meal', 'Wi-Fi', 'Entertainment', 'USB Charging', '30kg Baggage'],
      ),
      FlightModel(
        id: 'FL003',
        airline: 'British Airways',
        airlineCode: 'BA',
        from: from.isEmpty ? 'LHR' : from,
        fromCity: 'London',
        to: to.isEmpty ? 'JFK' : to,
        toCity: 'New York',
        departure: '11:45',
        arrival: '14:30',
        duration: '9h 45m',
        stops: 0,
        price: 712.00,
        cabin: 'Economy',
        seatsLeft: 2,
        rating: 4.6,
        isRefundable: false,
        hasMeal: true,
        hasWifi: true,
        hasEntertainment: true,
        aircraft: 'Boeing 787 Dreamliner',
        amenities: ['Meal', 'Wi-Fi', 'Entertainment', '23kg Baggage'],
      ),
      FlightModel(
        id: 'FL004',
        airline: 'Singapore Air',
        airlineCode: 'SQ',
        from: from.isEmpty ? 'SIN' : from,
        fromCity: 'Singapore',
        to: to.isEmpty ? 'LHR' : to,
        toCity: 'London',
        departure: '23:55',
        arrival: '06:10',
        duration: '13h 15m',
        stops: 1,
        price: 398.00,
        cabin: 'Economy',
        seatsLeft: 14,
        rating: 4.7,
        isRefundable: true,
        hasMeal: true,
        hasWifi: false,
        hasEntertainment: true,
        aircraft: 'Airbus A380',
        amenities: ['Meal', 'Entertainment', '30kg Baggage', 'Blanket & Pillow'],
      ),
      FlightModel(
        id: 'FL005',
        airline: 'Lufthansa',
        airlineCode: 'LH',
        from: from.isEmpty ? 'FRA' : from,
        fromCity: 'Frankfurt',
        to: to.isEmpty ? 'JFK' : to,
        toCity: 'New York',
        departure: '13:20',
        arrival: '16:45',
        duration: '10h 25m',
        stops: 0,
        price: 621.00,
        cabin: 'Economy',
        seatsLeft: 6,
        rating: 4.5,
        isRefundable: true,
        hasMeal: true,
        hasWifi: true,
        hasEntertainment: true,
        aircraft: 'Airbus A340-600',
        amenities: ['Meal', 'Wi-Fi', 'Entertainment', 'USB Charging', '23kg Baggage'],
      ),
    ];
  }

  static List<Map<String, dynamic>> popularDestinations = [
    {'city': 'Paris', 'country': 'France', 'code': 'CDG', 'price': 299, 'emoji': '🗼'},
    {'city': 'Tokyo', 'country': 'Japan', 'code': 'NRT', 'price': 689, 'emoji': '⛩️'},
    {'city': 'New York', 'country': 'USA', 'code': 'JFK', 'price': 412, 'emoji': '🗽'},
    {'city': 'Dubai', 'country': 'UAE', 'code': 'DXB', 'price': 189, 'emoji': '🏙️'},
    {'city': 'Bali', 'country': 'Indonesia', 'code': 'DPS', 'price': 521, 'emoji': '🌴'},
    {'city': 'London', 'country': 'UK', 'code': 'LHR', 'price': 345, 'emoji': '🎡'},
  ];
}