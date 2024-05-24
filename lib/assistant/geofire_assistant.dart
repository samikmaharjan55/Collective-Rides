import 'package:collective_rides/models/active_nearby_available_riders.dart';

class GeoFireAssistant {
  static List<ActiveNearByAvailableRiders> activeNearByAvailableRidersList = [];

  static void deleteOfflineRiderFromList(String riderId) {
    int indexNumber = activeNearByAvailableRidersList
        .indexWhere((element) => element.riderId == riderId);

    activeNearByAvailableRidersList.removeAt(indexNumber);
  }

  static void updateActiveNearByAvailableRiderLocation(
      ActiveNearByAvailableRiders riderWhoMove) {
    int indexNumber = activeNearByAvailableRidersList
        .indexWhere((element) => element.riderId == riderWhoMove.riderId);

    activeNearByAvailableRidersList[indexNumber].locationLatitude =
        riderWhoMove.locationLatitude;
    activeNearByAvailableRidersList[indexNumber].locationLongitude =
        riderWhoMove.locationLongitude;
  }
}
