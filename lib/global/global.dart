import 'package:collective_rides/models/direction_details_info.dart';
import 'package:collective_rides/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
User? currentUser;

UserModel? userModelCurrentInfo;

String cloudMessagingServerToken = "key=adasdasdsad";

List ridersList = [];
DirectionDetailsInfo? tripDirectionDetailsInfo;
String userDropOffAddress = "";
String riderVehicleDetails = "";
String riderName = "";
String riderPhone = "";
String riderRatings = "";

double countRatingStars = 0.0;
String titleStarsRating = "";
