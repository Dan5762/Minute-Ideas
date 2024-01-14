import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:MinuteIdeas/models/feed.dart';

class Profile extends StatelessWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [CategoriesRadarChart()])));
  }
}

class CategoriesRadarChart extends StatefulWidget {
  const CategoriesRadarChart({Key? key}) : super(key: key);

  @override
  State<CategoriesRadarChart> createState() => _CategoriesRadarChartState();
}

class _CategoriesRadarChartState extends State<CategoriesRadarChart> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 300,
        child: Consumer<FeedModel>(builder:
            (BuildContext context, FeedModel feedModel, Widget? child) {
          Map<String, double> categorySimilarities =
              feedModel.getCategorySimilarities();
          return RadarChart(
            RadarChartData(
                titleTextStyle: const TextStyle(color: Colors.white),
                dataSets: [
                  RadarDataSet(
                      fillColor: Colors.white,
                      borderColor: Colors.white,
                      dataEntries: categorySimilarities.entries
                          .map((entry) => RadarEntry(value: entry.value))
                          .toList())
                ],
                getTitle: (index, angle) => RadarChartTitle(
                    text: categorySimilarities.keys.toList()[index])),
            swapAnimationDuration:
                const Duration(milliseconds: 150), // Optional
            swapAnimationCurve: Curves.linear, // Optional
          );
        }));
  }
}
