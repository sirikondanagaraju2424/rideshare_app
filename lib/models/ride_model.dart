// lib/models/ride_model.dart

class Ride {
  final String rideId;
  final String userId;
  final String startLocation;
  final String endLocation;
  final String createdAt;
  final String rideType;
  final String? rideDate;
  final String? rideTime;
  final String? seatsAvailable;
  final String? moreInfo;

  Ride({
    required this.rideId,
    required this.userId,
    required this.startLocation,
    required this.endLocation,
    required this.createdAt,
    required this.rideType,
    this.rideDate,
    this.rideTime,
    this.seatsAvailable,
    this.moreInfo,
  });

  // This is a 'factory constructor'. It's a special type of constructor
  // used here to create a Ride object from the JSON data you get from your API.
  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      rideId: json['rideId'] ?? 'N/A',
      userId: json['userId'] ?? 'Unknown User',
      startLocation: json['startLocation'] ?? 'Unknown',
      endLocation: json['endLocation'] ?? 'Unknown',
      createdAt: json['createdAt'] ?? '',
      rideType: json['rideType'] ?? 'AVAILABLE',
      rideDate: json['rideDate'],
      rideTime: json['rideTime'],
      seatsAvailable: json['seatsAvailable'],
      moreInfo: json['moreInfo'],
    );
  }
}