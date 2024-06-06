import 'package:firebase_database/firebase_database.dart';

class TripsHistoryModel {
  String? time;
  String? originAddress;
  String? destinationAddress;
  String? status;
  String? fareAmount;
  String? vehicleDetails;
  String? riderName;
  String? ratings;

  TripsHistoryModel({
    this.time,
    this.originAddress,
    this.destinationAddress,
    this.status,
    this.fareAmount,
    this.vehicleDetails,
    this.riderName,
    this.ratings,
  });

  TripsHistoryModel.fromSnapshot(DataSnapshot dataSnapshot) {
    time = (dataSnapshot.value as Map)["time"];
    originAddress = (dataSnapshot.value as Map)["originAddress"];
    destinationAddress = (dataSnapshot.value as Map)["destinationAddress"];
    status = (dataSnapshot.value as Map)["status"];
    fareAmount = (dataSnapshot.value as Map)["fareAmount"];
    vehicleDetails = (dataSnapshot.value as Map)["vehicleDetails"];
    riderName = (dataSnapshot.value as Map)["riderName"];
    ratings = (dataSnapshot.value as Map)["ratings"];
  }
}
