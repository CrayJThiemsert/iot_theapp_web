import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:iot_theapp_web/pages/device/model/weather_history.dart';

class LineChartLive extends StatefulWidget {
  final WeatherData weatherData;

  const LineChartLive({Key? key, required this.weatherData}) : super(key: key);

  @override
  _LineChartLiveState createState() => _LineChartLiveState(weatherData);
}

class _LineChartLiveState extends State<LineChartLive> {
  final Color sinColor = Colors.redAccent;
  final Color cosColor = Colors.blueAccent;

  final limitCount = 100;
  final temperaturePoints = <FlSpot>[];
  final humidityPoints = <FlSpot>[];

  double xValue = 0;
  double step = 0.05;

  late Timer timer;
  WeatherData weatherData;

  _LineChartLiveState(this.weatherData);

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      while (temperaturePoints.length > limitCount) {
        temperaturePoints.removeAt(0);
        humidityPoints.removeAt(0);
      }
      setState(() {
        temperaturePoints.add(FlSpot(xValue, math.sin(xValue)));
        humidityPoints.add(FlSpot(xValue, math.cos(xValue)));
      });
      xValue += step;
    });
  }

  @override
  Widget build(BuildContext context) {
    return humidityPoints.isNotEmpty
        ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'x: ${xValue.toStringAsFixed(1)}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'sin: ${temperaturePoints.last.y.toStringAsFixed(1)}',
          style: TextStyle(
            color: sinColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'cos: ${humidityPoints.last.y.toStringAsFixed(1)}',
          style: TextStyle(
            color: cosColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        SizedBox(
          width: 150,
          height: 150,
          child: LineChart(
            LineChartData(
              minY: -1,
              maxY: 1,
              minX: temperaturePoints.first.x,
              maxX: temperaturePoints.last.x,
              lineTouchData: LineTouchData(enabled: false),
              clipData: FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              lineBarsData: [
                sinLine(temperaturePoints),
                cosLine(humidityPoints),
              ],
              titlesData: FlTitlesData(
                show: false,
              ),
            ),
          ),
        )
      ],
    )
        : Container();
  }

  LineChartBarData sinLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      gradient: LinearGradient(
          colors: [sinColor.withOpacity(0), sinColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.1, 1.0]),
      barWidth: 4,
      isCurved: false,
    );
  }

  LineChartBarData cosLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      gradient: LinearGradient(
          colors: [sinColor.withOpacity(0), sinColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.1, 1.0]),
      barWidth: 4,
      isCurved: false,
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}