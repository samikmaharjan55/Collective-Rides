import 'dart:async';
import 'package:collective_rides/assistant/assistant_methods.dart';
import 'package:collective_rides/assistant/geofire_assistant.dart';
import 'package:collective_rides/global/global.dart';
import 'package:collective_rides/infoHandler/app_info.dart';
import 'package:collective_rides/models/active_nearby_available_riders.dart';
import 'package:collective_rides/screens/drawer_screen.dart';
import 'package:collective_rides/screens/precise_pickup_location.dart';
import 'package:collective_rides/screens/rate_rider_screen.dart';
import 'package:collective_rides/screens/search_places_screen.dart';
import 'package:collective_rides/splashScreen/splash_screen.dart';
import 'package:collective_rides/widgets/pay_fare_amount_dialog.dart';
import 'package:collective_rides/widgets/progress_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

Future<void> _makePhoneCall(String url) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url);
  } else {
    throw "Could not launch $url";
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  LatLng? pickLocation;
  loc.Location location = loc.Location();
  String? _address;

  final Completer<GoogleMapController> _controllerGoogleMap =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
  GoogleMapController? newGoogleMapController;

  double searchLocationContainerHeight = 220;
  double waitingResponseFromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;
  double suggestedRidesContainerHeight = 0;
  double searchingForRiderContainerHeight = 0;

  Position? userCurrentPosition;
  var geoLocator = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoordinatesList = [];
  Set<Polyline> polylinesSet = {};

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  String userName = "";
  String userEmail = "";

  bool openNavigationDrawer = true;
  bool activeNearByRiderKeysLoaded = false;

  BitmapDescriptor? activeNearbyIcon;

  DatabaseReference? referenceRideRequest;

  String selectedVehicleType = "";

  String riderRideStatus = "Rider is coming";
  StreamSubscription<DatabaseEvent>? tripRidesRequestInfoStreamSubscription;

  List<ActiveNearByAvailableRiders> onlineNearByAvailableRidersList = [];

  String userRideRequestStatus = "";

  bool requestPositionInfo = true;

  locateUserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;

    LatLng latLngPosition =
        LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(
      target: latLngPosition,
      zoom: 15,
    );

    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    String humanReadableAddress =
        await AssistantMethods.searchAddressForGeographicCoordinates(
            userCurrentPosition!, context);
    print("This is our address =" + humanReadableAddress);

    userName = userModelCurrentInfo!.name!;
    userEmail = userModelCurrentInfo!.email!;

    initializeGeoFireListener();

    AssistantMethods.readTripsKeysForOnlineUser(context);
  }

  initializeGeoFireListener() {
    Geofire.initialize("activeRiders");

    Geofire.queryAtLocation(
            userCurrentPosition!.latitude, userCurrentPosition!.longitude, 10)!
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map["callBack"];

        switch (callBack) {
          // whenever any driver become active/online
          case Geofire.onKeyEntered:
            GeoFireAssistant.activeNearByAvailableRidersList.clear();
            ActiveNearByAvailableRiders activeNearByAvailableRiders =
                ActiveNearByAvailableRiders();
            activeNearByAvailableRiders.locationLatitude = map["latitude"];
            activeNearByAvailableRiders.locationLongitude = map["longitude"];
            activeNearByAvailableRiders.riderId = map["key"];
            GeoFireAssistant.activeNearByAvailableRidersList
                .add(activeNearByAvailableRiders);
            if (activeNearByRiderKeysLoaded == true) {
              displayActiveRidersOnUsersMap();
            }
            break;

          // whenever any rider become non-active/online
          case Geofire.onKeyExited:
            GeoFireAssistant.deleteOfflineRiderFromList(map['key']);
            displayActiveRidersOnUsersMap();
            break;

          // whenever rider moves - update rider location
          case Geofire.onKeyMoved:
            ActiveNearByAvailableRiders activeNearByAvailableRiders =
                ActiveNearByAvailableRiders();
            activeNearByAvailableRiders.locationLatitude = map['latitude'];
            activeNearByAvailableRiders.locationLongitude = map["longitude"];
            activeNearByAvailableRiders.riderId = map["key"];
            GeoFireAssistant.updateActiveNearByAvailableRiderLocation(
                activeNearByAvailableRiders);
            displayActiveRidersOnUsersMap();
            break;

          // display those online active riders on user's map
          case Geofire.onGeoQueryReady:
            activeNearByRiderKeysLoaded = true;
            displayActiveRidersOnUsersMap();
            break;
        }
      }
      setState(() {});
    });
  }

  displayActiveRidersOnUsersMap() {
    setState(() {
      markersSet.clear();
      circlesSet.clear();

      Set<Marker> ridersMarkerSet = Set<Marker>();

      for (ActiveNearByAvailableRiders eachRider
          in GeoFireAssistant.activeNearByAvailableRidersList) {
        LatLng eachRiderActivePosition =
            LatLng(eachRider.locationLatitude!, eachRider.locationLongitude!);

        Marker marker = Marker(
          markerId: MarkerId(eachRider.riderId!),
          position: eachRiderActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );
        ridersMarkerSet.add(marker);
      }
      setState(() {
        markersSet = ridersMarkerSet;
      });
    });
  }

  createActiveNearByRiderIconMarker() {
    if (activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, "assets/images/bike.png")
          .then((value) {
        activeNearbyIcon = value;
      });
    }
  }

  Future<void> drawPolylineFromOriginToDestination(bool darkTheme) async {
    var originPosition =
        Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatLng = LatLng(
        originPosition!.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!,
        destinationPosition.locationLongitude!);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: "Please wait...",
            ));
    var directionDetailsInfo =
        await AssistantMethods.obtainOriginToDestinationDirectionDetails(
            originLatLng, destinationLatLng);
    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;
    });
    Navigator.pop(context);
    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodePolylinePointsResultList =
        pPoints.decodePolyline(directionDetailsInfo.e_points!);
    pLineCoordinatesList.clear();
    if (decodePolylinePointsResultList.isNotEmpty) {
      decodePolylinePointsResultList.forEach((PointLatLng pointLatLng) {
        pLineCoordinatesList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    polylinesSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: darkTheme ? Colors.blue : Colors.blue,
        polylineId: const PolylineId("PoluylineID"),
        jointType: JointType.round,
        points: pLineCoordinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
        width: 5,
      );
      polylinesSet.add(polyline);
    });
    LatLngBounds boundsLatLng;
    if (originLatLng.latitude > destinationLatLng.latitude &&
        originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng =
          LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    } else if (originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    } else if (originLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      boundsLatLng =
          LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }
    newGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: const MarkerId("originID"),
      infoWindow:
          InfoWindow(title: originPosition.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );
    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      infoWindow: InfoWindow(
          title: destinationPosition.locationName, snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
    setState(() {
      markersSet.add(originMarker);
      markersSet.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: const CircleId("originID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationID"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      circlesSet.add(originCircle);
      circlesSet.add(destinationCircle);
    });
  }

  void showSearchingForRidersContainer() {
    setState(() {
      searchingForRiderContainerHeight = 200;
    });
  }

  void showSuggestedRidesContainer() {
    setState(() {
      suggestedRidesContainerHeight = 400;
      bottomPaddingOfMap = 400;
    });
  }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  saveRideRequestInformation(String selectedVehicleType) {
    // 1. Save the ride request information
    referenceRideRequest =
        FirebaseDatabase.instance.ref().child("All Ride Requests").push();

    var originLocation =
        Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationLocation =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;
    Map originLocationMap = {
      // "key: value"
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),
    };

    Map destinationLocationMap = {
      // "key: value"
      "latitude": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),
    };

    Map userInformationMap = {
      "origin": originLocationMap,
      "destination": destinationLocationMap,
      "time": DateTime.now().toString(),
      "userName": userModelCurrentInfo!.name,
      "usePhone": userModelCurrentInfo!.phone,
      "originAddress": originLocation.locationName,
      "destinationAddress": destinationLocation.locationName,
      "driverId": "waiting",
    };

    referenceRideRequest!.set(userInformationMap);
    tripRidesRequestInfoStreamSubscription =
        referenceRideRequest!.onValue.listen((eventSnap) async {
      if (eventSnap.snapshot.value == null) {
        return;
      }

      if ((eventSnap.snapshot.value as Map)["vehicle_details"] != null) {
        setState(() {
          riderVehicleDetails =
              (eventSnap.snapshot.value as Map)["vehicle_details"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["riderPhone"] != null) {
        setState(() {
          riderPhone =
              (eventSnap.snapshot.value as Map)["riderPhone"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["riderName"] != null) {
        setState(() {
          riderName = (eventSnap.snapshot.value as Map)["riderName"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["ratings"] != null) {
        setState(() {
          riderRatings =
              (eventSnap.snapshot.value as Map)["ratings"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["status"] != null) {
        setState(() {
          userRideRequestStatus =
              (eventSnap.snapshot.value as Map)["status"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["riderLocation"] != null) {
        double riderCurrentPositionLat = double.parse(
            (eventSnap.snapshot.value as Map)["riderLocation"]["latitude"]
                .toString());
        double riderCurrentPositionLng = double.parse(
            (eventSnap.snapshot.value as Map)["riderLocation"]["longitude"]
                .toString());

        LatLng riderCurrentPositionLatLng =
            LatLng(riderCurrentPositionLat, riderCurrentPositionLng);

        // status = accepted
        if (userRideRequestStatus == "accepted") {
          updateArrivalTimeToUserPickUpLocation(riderCurrentPositionLatLng);
        }
        // status = arrived
        if (userRideRequestStatus == "arrived") {
          setState(() {
            riderRideStatus = "Rider has arrived";
          });
        }

        // status = onTrip
        if (userRideRequestStatus == "onTrip") {
          updateReachingTimeToUserDropOffLocation(riderCurrentPositionLatLng);
        }

        if (userRideRequestStatus == "ended") {
          if ((eventSnap.snapshot.value as Map)["fareAmount"] != null) {
            double fareAmount = double.parse(
                (eventSnap.snapshot.value as Map)["fareAmount"].toString());

            var response = await showDialog(
                context: context,
                builder: (BuildContext context) => PayFareAmountDialog(
                      fareAmount: fareAmount,
                    ));

            if (response == "Cash Paid") {
              // user can rate the driver now
              if ((eventSnap.snapshot.value as Map)["riderId"] != null) {
                String assignedRiderId =
                    (eventSnap.snapshot.value as Map)["riderId"].toString();
                (eventSnap.snapshot.value as Map)["riderId"].toString();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (c) => RateRiderScreen(
                              assignedRiderId: assignedRiderId,
                            )));

                referenceRideRequest!.onDisconnect();
                tripRidesRequestInfoStreamSubscription!.cancel();
              }
            }
          }
        }
      }
    });
    onlineNearByAvailableRidersList =
        GeoFireAssistant.activeNearByAvailableRidersList;
    searchNearestOnlineRiders(selectedVehicleType);
  }

  searchNearestOnlineRiders(selectedVehicleType) async {
    if (onlineNearByAvailableRidersList.length == 0) {
      // cancel/delete the rideRequest Information
      referenceRideRequest!.remove();
      setState(() {
        polylinesSet.clear();
        markersSet.clear();
        circlesSet.clear();
        pLineCoordinatesList.clear();
      });
      Fluttertoast.showToast(msg: "No online nearest Rider Available");
      Fluttertoast.showToast(msg: "Search Again. \n Restart App");

      Future.delayed(const Duration(milliseconds: 4000), () {
        referenceRideRequest!.remove();
        Navigator.push(
            context, MaterialPageRoute(builder: (c) => const SplashScreen()));
      });
      return;
    }
    await retrieveOnlineDriversInformation(onlineNearByAvailableRidersList);
    print("Rider List:" + ridersList.toString());
    for (int i = 0; i < ridersList.length; i++) {
      if (ridersList[i]["vehicle_details"]["type"] == selectedVehicleType) {
        AssistantMethods.sendNotificationToRiderNow(
            ridersList[i]["token"], referenceRideRequest!.key!, context);
      }
    }
    Fluttertoast.showToast(msg: "Notification sent Successfully");

    showSearchingForRidersContainer();

    await FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(referenceRideRequest!.key!)
        .child("riderId")
        .onValue
        .listen((eventRideRequestSnapchot) {
      print("EventSnapshot:${eventRideRequestSnapchot.snapshot.value}");
      if (eventRideRequestSnapchot.snapshot.value != null) {
        if (eventRideRequestSnapchot.snapshot.value != "waiting") {
          showUIForAssignedRiderInfo();
        }
      }
    });
  }

  updateArrivalTimeToUserPickUpLocation(riderCurrentPositionLatLng) async {
    if (requestPositionInfo == true) {
      requestPositionInfo = false;
      LatLng userPickUpPosition =
          LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

      var directionDetailsInfo =
          await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        riderCurrentPositionLatLng,
        userPickUpPosition,
      );

      if (directionDetailsInfo == null) {
        return;
      }
      setState(() {
        riderRideStatus =
            "Rider is coming" + directionDetailsInfo.distance_text.toString();
      });
      requestPositionInfo = true;
    }
  }

  updateReachingTimeToUserDropOffLocation(riderCurrentPositionLatLng) async {
    if (requestPositionInfo == true) {
      requestPositionInfo = false;

      var dropOffLocation =
          Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

      LatLng userDestinationPosition = LatLng(
        dropOffLocation!.locationLatitude!,
        dropOffLocation.locationLongitude!,
      );
      var directionDetailsInfo =
          await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        riderCurrentPositionLatLng,
        userDestinationPosition,
      );
      if (directionDetailsInfo == null) {
        return;
      }
      setState(() {
        riderRideStatus = "Going towards Destination:" +
            directionDetailsInfo.duration_text.toString();
      });
      requestPositionInfo = true;
    }
  }

  showUIForAssignedRiderInfo() {
    setState(() {
      waitingResponseFromDriverContainerHeight = 0;
      searchLocationContainerHeight = 0;
      assignedDriverInfoContainerHeight = 200;
      suggestedRidesContainerHeight = 0;
      bottomPaddingOfMap = 200;
    });
  }

  retrieveOnlineDriversInformation(List onlineNearestRidersList) async {
    ridersList.clear();
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("riders");

    for (int i = 0; i < onlineNearestRidersList.length; i++) {
      await ref
          .child(onlineNearestRidersList[i].riderId.toString())
          .once()
          .then((dataSnapshot) {
        var riderKeyInfo = dataSnapshot.snapshot.value;

        ridersList.add(riderKeyInfo);
        print("rider key information = " + ridersList.toString());
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkIfLocationPermissionAllowed();
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    createActiveNearByRiderIconMarker();
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: _scaffoldState,
        drawer: const DrawerScreen(),
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              initialCameraPosition: _kGooglePlex,
              polylines: polylinesSet,
              markers: markersSet,
              circles: circlesSet,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;
                if (darkTheme == true) {
                  setState(() {
                    //blackThemeGoogleMap(newGoogleMapController);
                  });
                }
                setState(() {
                  bottomPaddingOfMap = 200;
                });
                locateUserPosition();
              },
            ),

            // Custom Hamburger Button For Drawer
            Positioned(
              top: 50,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  _scaffoldState.currentState!.openDrawer();
                },
                child: CircleAvatar(
                  backgroundColor:
                      darkTheme ? Colors.amber.shade400 : Colors.white,
                  child: Icon(
                    Icons.menu,
                    color: darkTheme ? Colors.black : Colors.lightBlue,
                  ),
                ),
              ),
            ),
            // UI for searching location
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 50, 10, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: darkTheme ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: darkTheme
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        color: darkTheme
                                            ? Colors.amber.shade400
                                            : Colors.blue,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "From",
                                            style: TextStyle(
                                              color: darkTheme
                                                  ? Colors.amber.shade400
                                                  : Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            Provider.of<AppInfo>(context)
                                                        .userPickUpLocation !=
                                                    null
                                                ? "${(Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0, 24)}..."
                                                : "Not Getting Address",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 2,
                                  color: darkTheme
                                      ? Colors.amber.shade400
                                      : Colors.blue,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      var responseFromSearchScreen =
                                          await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (c) =>
                                                      const SearchPlacesScreen()));
                                      if (responseFromSearchScreen ==
                                          "obtainedDropOff") {
                                        setState(() {
                                          openNavigationDrawer = false;
                                        });
                                      }
                                      await drawPolylineFromOriginToDestination(
                                          darkTheme);
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          color: darkTheme
                                              ? Colors.amber.shade400
                                              : Colors.blue,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "To",
                                              style: TextStyle(
                                                color: darkTheme
                                                    ? Colors.amber.shade400
                                                    : Colors.blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              Provider.of<AppInfo>(context)
                                                          .userDropOffLocation !=
                                                      null
                                                  ? Provider.of<AppInfo>(
                                                          context)
                                                      .userDropOffLocation!
                                                      .locationName!
                                                  : "Where to?",
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (c) =>
                                              const PrecisePickUpScreen()));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkTheme
                                      ? Colors.amber.shade400
                                      : Colors.blue,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                child: Text(
                                  "Change Pick Up",
                                  style: TextStyle(
                                    color:
                                        darkTheme ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (Provider.of<AppInfo>(context,
                                              listen: false)
                                          .userDropOffLocation !=
                                      null) {
                                    showSuggestedRidesContainer();
                                  } else {
                                    Fluttertoast.showToast(
                                        msg:
                                            "Please select destination location");
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkTheme
                                      ? Colors.amber.shade400
                                      : Colors.blue,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                child: Text(
                                  "Show Fare",
                                  style: TextStyle(
                                    color:
                                        darkTheme ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // UI for suggested rides
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: suggestedRidesContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: darkTheme
                                  ? Colors.amber.shade400
                                  : Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Text(
                            Provider.of<AppInfo>(context).userPickUpLocation !=
                                    null
                                ? "${(Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0, 24)}..."
                                : "Not Getting Address",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Text(
                            Provider.of<AppInfo>(context).userDropOffLocation !=
                                    null
                                ? Provider.of<AppInfo>(context)
                                    .userDropOffLocation!
                                    .locationName!
                                : "Where to?",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        "SUGGESTED RIDES",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVehicleType = "Bike";
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "Bike"
                                    ? (darkTheme
                                        ? Colors.amber.shade400
                                        : Colors.blue)
                                    : (darkTheme
                                        ? Colors.black54
                                        : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(25),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      "assets/images/bike.png",
                                      scale: 15,
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      "Bike",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedVehicleType == "Bike"
                                            ? (darkTheme
                                                ? Colors.black
                                                : Colors.white)
                                            : (darkTheme
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      tripDirectionDetailsInfo != null
                                          ? "Rs. ${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 0.8) * 107).toStringAsFixed(1)}"
                                          : "null",
                                      style: TextStyle(
                                        color: selectedVehicleType == "Bike"
                                            ? (darkTheme
                                                ? Colors.black
                                                : Colors.white)
                                            : (darkTheme
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVehicleType = "Car";
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: selectedVehicleType == "Car"
                                    ? (darkTheme
                                        ? Colors.amber.shade400
                                        : Colors.blue)
                                    : (darkTheme
                                        ? Colors.black54
                                        : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(25),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      "assets/images/car.png",
                                      scale: 20,
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Text(
                                      "Car",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedVehicleType == "Car"
                                            ? (darkTheme
                                                ? Colors.black
                                                : Colors.white)
                                            : (darkTheme
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Text(
                                      tripDirectionDetailsInfo != null
                                          ? "Rs. ${((AssistantMethods.calculateFareAmountFromOriginToDestination(tripDirectionDetailsInfo!) * 2) * 107).toStringAsFixed(1)}"
                                          : "null",
                                      style: TextStyle(
                                        color: selectedVehicleType == "Car"
                                            ? (darkTheme
                                                ? Colors.black
                                                : Colors.white)
                                            : (darkTheme
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Expanded(
                          child: GestureDetector(
                        onTap: () {
                          if (selectedVehicleType != "") {
                            saveRideRequestInformation(selectedVehicleType);
                          } else {
                            Fluttertoast.showToast(
                                msg:
                                    "Please select a vehicle from \n suggested rides.");
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color:
                                darkTheme ? Colors.amber.shade400 : Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Request a Ride",
                              style: TextStyle(
                                color: darkTheme ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),

            // Requesting a Ride
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: searchingForRiderContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LinearProgressIndicator(
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Center(
                        child: Text(
                          "Searching for a rider...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      GestureDetector(
                        onTap: () {
                          referenceRideRequest!.remove();
                          setState(() {
                            searchingForRiderContainerHeight = 0;
                            suggestedRidesContainerHeight = 0;
                          });
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: darkTheme ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 25,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      const SizedBox(
                        width: double.infinity,
                        child: Text(
                          "Cancel",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // UI for displaying assigned rider information
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: assignedDriverInfoContainerHeight,
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Text(
                        riderRideStatus,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Divider(
                        thickness: 1,
                        color: darkTheme ? Colors.grey : Colors.grey[300],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: darkTheme
                                      ? Colors.amber.shade400
                                      : Colors.lightBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color:
                                      darkTheme ? Colors.black : Colors.white,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    riderName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        riderRatings,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Image.asset(
                                "assets/images/bike.png",
                                scale: 3,
                              ),
                              Text(
                                riderVehicleDetails,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Divider(
                        thickness: 1,
                        color: darkTheme ? Colors.grey : Colors.grey[300],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor:
                              darkTheme ? Colors.amber.shade400 : Colors.blue,
                        ),
                        onPressed: () {
                          _makePhoneCall("tel: ${riderPhone}");
                        },
                        label: const Text("Call Rider"),
                        icon: const Icon(Icons.phone),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
