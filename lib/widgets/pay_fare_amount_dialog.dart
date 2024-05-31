import 'package:collective_rides/splashScreen/splash_screen.dart';
import 'package:flutter/material.dart';

class PayFareAmountDialog extends StatefulWidget {
  double? fareAmount;
  PayFareAmountDialog({this.fareAmount, super.key});

  @override
  State<PayFareAmountDialog> createState() => _PayFareAmountDialogState();
}

class _PayFareAmountDialogState extends State<PayFareAmountDialog> {
  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: darkTheme ? Colors.black : Colors.blue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Text(
              "Fare Amount".toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.amber.shade400 : Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Divider(
              thickness: 2,
              color: darkTheme ? Colors.amber.shade400 : Colors.white,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "Rs. " + widget.fareAmount.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkTheme ? Colors.amber.shade400 : Colors.white,
                fontSize: 50,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                "This is the total trip fare amount. Please pay it to the driver.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkTheme ? Colors.amber.shade400 : Colors.white,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor:
                      darkTheme ? Colors.amber.shade400 : Colors.white,
                ),
                onPressed: () {
                  Future.delayed(const Duration(milliseconds: 10000), () {
                    Navigator.pop(context, "Cash Paid");
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (c) => const SplashScreen()));
                  });
                },
                child: Row(
                  children: [
                    Text(
                      "Pay Cash",
                      style: TextStyle(
                        fontSize: 20,
                        color: darkTheme ? Colors.black : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Rs." + widget.fareAmount.toString(),
                      style: TextStyle(
                        fontSize: 20,
                        color: darkTheme ? Colors.black : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
