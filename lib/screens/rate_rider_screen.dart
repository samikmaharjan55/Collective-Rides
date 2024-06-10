import 'package:collective_rides/global/global.dart';
import 'package:collective_rides/splashScreen/splash_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';

class RateRiderScreen extends StatefulWidget {
  String? assignedRiderId;
  RateRiderScreen({this.assignedRiderId, super.key});

  @override
  State<RateRiderScreen> createState() => _RateRiderScreenState();
}

class _RateRiderScreenState extends State<RateRiderScreen> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
          color: darkTheme ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 22,
            ),
            Text(
              "Rate Trip Experience",
              style: TextStyle(
                fontSize: 22,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Divider(
              thickness: 2,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
            ),
            const SizedBox(
              height: 20,
            ),
            SmoothStarRating(
              rating: countRatingStars,
              allowHalfRating: false,
              starCount: 5,
              color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              borderColor: darkTheme ? Colors.amber.shade400 : Colors.grey,
              size: 46,
              onRatingChanged: (valueOfStarsChoosed) {
                countRatingStars = valueOfStarsChoosed;
                if (countRatingStars == 1) {
                  setState(() {
                    titleStarsRating = "Very Bad";
                  });
                }
                if (countRatingStars == 2) {
                  setState(() {
                    titleStarsRating = "Bad";
                  });
                }
                if (countRatingStars == 3) {
                  setState(() {
                    titleStarsRating = "Good";
                  });
                }
                if (countRatingStars == 4) {
                  setState(() {
                    titleStarsRating = "Very Good";
                  });
                }
                if (countRatingStars == 5) {
                  setState(() {
                    titleStarsRating = "Excellent";
                  });
                }
              },
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              titleStarsRating,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor:
                    darkTheme ? Colors.amber.shade400 : Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 70),
              ),
              onPressed: () {
                DatabaseReference rateRiderRef = FirebaseDatabase.instance
                    .ref()
                    .child("riders")
                    .child(widget.assignedRiderId!)
                    .child("ratings");

                rateRiderRef.once().then((snap) {
                  if (snap.snapshot.value == null) {
                    rateRiderRef.set(countRatingStars.toString());

                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (c) => const SplashScreen()));
                  } else {
                    double pastRatings =
                        double.parse(snap.snapshot.value.toString());
                    double newAverageRatings =
                        (pastRatings + countRatingStars) / 2;
                    rateRiderRef.set(newAverageRatings.toString());

                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (c) => const SplashScreen()));
                  }
                  Fluttertoast.showToast(msg: "Restarting the app now");
                });
              },
              child: Text(
                "Submit",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkTheme ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
