import 'package:collective_rides/models/predicted_places.dart';
import 'package:flutter/material.dart';

class SearchPlacesScreen extends StatefulWidget {
  const SearchPlacesScreen({super.key});

  @override
  State<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends State<SearchPlacesScreen> {
  List<PredictedPlaces> predictedPlacesList = [];
  findPlaceAutoCompleteSearch(String inputText) async {}
  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: darkTheme ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Icons.arrow_back,
              color: darkTheme ? Colors.black : Colors.white,
            ),
          ),
          title: Text(
            "Search & Set DropOff Location",
            style: TextStyle(
              color: darkTheme ? Colors.black : Colors.white,
            ),
          ),
          elevation: 0.0,
        ),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white54,
                    blurRadius: 8,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.adjust_sharp,
                          color: darkTheme ? Colors.black : Colors.white,
                        ),
                        const SizedBox(
                          height: 18.0,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(
                              onChanged: (value) {
                                findPlaceAutoCompleteSearch(value);
                              },
                              decoration: InputDecoration(
                                hintText: "Search location herer...",
                                fillColor:
                                    darkTheme ? Colors.black : Colors.white54,
                                filled: true,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.only(
                                  left: 11,
                                  top: 8,
                                  bottom: 8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Display place prediction result
            (predictedPlacesList.length > 0)
                ? Expanded(
                    child: ListView.separated(
                      itemCount: predictedPlacesList.length,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Container();
                      },
                      separatorBuilder: (context, index) => Container(),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
