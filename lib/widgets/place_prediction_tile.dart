import 'package:collective_rides/models/predicted_places.dart';
import 'package:flutter/material.dart';

class PlacePredictionTile extends StatefulWidget {
  final PredictedPlaces? predictedPlaces;
  const PlacePredictionTile({super.key, this.predictedPlaces});

  @override
  State<PlacePredictionTile> createState() => _PlacePredictionTileState();
}

class _PlacePredictionTileState extends State<PlacePredictionTile> {
  getPlaceDirectionDetails() {}
  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          foregroundColor: darkTheme ? Colors.black : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(
                Icons.add_location,
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.predictedPlaces!.main_text!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),
                    ),
                    Text(
                      widget.predictedPlaces!.secondary_text!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
