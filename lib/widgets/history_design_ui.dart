import 'package:collective_rides/models/trips_history_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryDesignUiWidget extends StatefulWidget {
  TripsHistoryModel? tripsHistoryModel;

  HistoryDesignUiWidget({this.tripsHistoryModel, super.key});

  @override
  State<HistoryDesignUiWidget> createState() => _HistoryDesignUiWidgetState();
}

class _HistoryDesignUiWidgetState extends State<HistoryDesignUiWidget> {
  String formatDateAndTime(String dateTimeFromDB) {
    DateTime dateTime = DateTime.parse(dateTimeFromDB);

    String formattedDateTime =
        "${DateFormat.MMMd().format(dateTime)}, ${DateFormat.y().format(dateTime)} - ${DateFormat.jm().format(dateTime)}";

    return formattedDateTime;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatDateAndTime(widget.tripsHistoryModel!.time!),
        ),
      ],
    );
  }
}
