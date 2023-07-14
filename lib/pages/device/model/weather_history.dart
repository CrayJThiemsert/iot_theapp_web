import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meta/meta.dart';
import 'package:validators/validators.dart';

class WeatherHistory extends Equatable {
  final String key;
  final String id;
  final String deviceId;
  final double humidity;
  final double temperature;
  final WeatherData weatherData;
  final double readVoltage;

  factory WeatherHistory.fromJson(Map<dynamic, dynamic> json) {
    if(json != null) {
      var key = json.keys.first.toString();
      print('WeatherHistory.fromJson key=${key}');
      print('WeatherHistory.fromJson json[key]=${json[key]}');
      WeatherData data = WeatherData.fromJson(json[key]);
      print('data.humidity=${data.humidity}');
      return WeatherHistory(
        key: key,
        id: '',
        deviceId: '',
        humidity: 0,
        temperature: 0,
        weatherData: WeatherData.fromJson(json[key]),
        readVoltage: 0,
      );
    } else {
      print('json.isEmpty=${json?.isEmpty ?? true}');
      WeatherData data = WeatherData(
          //
        humidity: 0,
          uid: '',
          deviceId: '',
          // temperature: double.nan,
          // readVoltage: double.nan,
        temperature: 0,
        readVoltage: 0,

          wRangeDistance: double.nan,
          wFilledDepth: double.nan,
          wHeight: double.nan,
          wWidth: double.nan,
          wDiameter: double.nan,
          wSideLength: double.nan,
          wLength: double.nan,
          wCapacity: double.nan,
          wOffset: double.nan,
      );
      return WeatherHistory(
        key: '',
        id: '',
        deviceId: '',
        humidity: 0,
        temperature: 0,
        weatherData: data,
        readVoltage: 0,
      );
    }
  }

  factory WeatherHistory.fromSnapshot(DataSnapshot snap) {
    print('fromSnapshot snap.value=${snap.value}');
    WeatherData data = WeatherData(
        humidity: double.nan,
        uid: '',
        deviceId: '',
        temperature: double.nan,
        readVoltage: double.nan,

        wRangeDistance: double.nan,
        wFilledDepth: double.nan,
        wHeight: double.nan,
        wWidth: double.nan,
        wDiameter: double.nan,
        wSideLength: double.nan,
        wLength: double.nan,
        wCapacity: double.nan,
        wOffset: double.nan,
    );
    return WeatherHistory(
      key: snap.key ?? '',
      id: '',
      deviceId: '',
      humidity: 0,
      temperature: 0,
      weatherData: data,
      readVoltage: 0,

      // weatherData: WeatherData.fromSnapshot(snap),
      // weatherData: WeatherData.fromJson(snap.value),
      // id: snap.value['id'] ?? '',
      //
      // deviceId: snap.value['uid'] ?? '',
      // humidity: double.parse(snap.value['humidity']) ?? '-1',
      // temperature: double.parse(snap.value['temperature']) ?? '-1',
    );
  }

  const WeatherHistory(
      {required this.key, required this.id, required this.deviceId, required this.humidity, required this.temperature, required this.weatherData, required this.readVoltage});

  @override
  List<Object> get props => [id, key, deviceId, humidity, temperature, weatherData, readVoltage];

  // static const empty = WeatherHistory(
  //     id: '', key: '', deviceId: '', humidity: double.nan, temperature: double.nan, readVoltage: double.nan);

  @override
  String toString() {
    return 'User{id: $id, uid: $key, deviceId: $deviceId, humidity: $humidity, temperature: $temperature, readVoltage: $readVoltage}';
  }
}

class WeatherData {
  WeatherData({
    required this.uid,
    required this.temperature,
    required this.humidity,
    required this.deviceId,
    required this.readVoltage,
    required this.wRangeDistance,
    required this.wFilledDepth,
    required this.wHeight,
    required this.wWidth,
    required this.wDiameter,
    required this.wSideLength,
    required this.wLength,
    required this.wCapacity,
    required this.wOffset,
  });

  String uid;
  String deviceId;
  double temperature = double.nan;
  double humidity = double.nan;
  double readVoltage = double.nan;

  double wRangeDistance = double.nan;
  double wFilledDepth = double.nan;
  double wHeight = double.nan;
  double wWidth = double.nan;
  double wDiameter = double.nan;
  double wSideLength = double.nan;
  double wLength = double.nan;
  double wCapacity = double.nan;
  double wOffset = double.nan;


  factory WeatherData.fromJson(Map<dynamic, dynamic> json) {
    print('WeatherData.fromJson json= ${json}');
    return WeatherData(
      uid: json['uid'] ?? '',
      deviceId: json['deviceId'] ?? '',
      temperature: (json['temperature'] ?? 0).toDouble() ?? 0,
      humidity: (json['humidity'] ?? 0).toDouble() ?? 0,
      readVoltage: (json['readVoltage'] ?? 0).toDouble() ?? 0,

      wRangeDistance: (json['wRangeDistance'] ?? 0).toDouble() ?? 0,
      wFilledDepth: (json['wFilledDepth'] ?? 0).toDouble() ?? 0,
      wHeight: (json['wHeight'] ?? 0).toDouble() ?? 0,
      wWidth: (json['wWidth'] ?? 0).toDouble() ?? 0,
      wDiameter: (json['wDiameter'] ?? 0).toDouble() ?? 0,
      wSideLength: (json['wSideLength'] ?? 0).toDouble() ?? 0,
      wLength: (json['wLength'] ?? 0).toDouble() ?? 0,
      wCapacity: (json['wCapacity'] ?? 0).toDouble() ?? 0,
      wOffset: (json['wOffset'] ?? 0).toDouble() ?? 0,
    );
  }

  // factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
  //   uid: json["uid"],
  //   temperature: json["temperature"].toDouble(),
  //   deviceId: json["deviceId"],
  //   humidity: json["humidity"].toDouble(),
  // );

  // factory WeatherData.fromSnapshot(DataSnapshot snap) {
  //   print('WeatherData.fromSnapshot=>${snap.value.toString()}');
  //   print('snap deviceId=${snap.value['deviceId']}');
  //   print('snap humidity=${snap.value['humidity']}');
  //   return WeatherData(
  //     uid: snap.value['uid'] ?? '',
  //     deviceId: snap.value['deviceId'] ?? '',
  //     humidity: double.parse(snap.value['humidity'].toString()),
  //     temperature: double.parse(snap.value['temperature'].toString()),
  //     readVoltage: double.parse(snap.value['readVoltage'].toString()),
  //   );
  // }

  Map<String, dynamic> toJson() => {
    "uid": uid,
    "temperature": temperature,
    "humidity": humidity,
    "deviceId": deviceId,
    "readVoltage": readVoltage,

    "wRangeDistance": wRangeDistance,
    "wFilledDepth": wFilledDepth,
    "wHeight": wHeight,
    "wWidth": wWidth,
    "wDiameter": wDiameter,
    "wSideLength": wSideLength,
    "wLength": wLength,
    "wCapacity": wCapacity,
    "wOffset": wOffset,
  };

  @override
  String toString() {
    return 'User{uid: $uid, '
        'deviceId: $deviceId, '
        'humidity: $humidity, '
        'temperature: $temperature, '
        'readVoltage: $readVoltage, '
        'wRangeDistance: $wRangeDistance, '
        'wFilledDepth: $wFilledDepth, '
        'wHeight: $wHeight, '
        'wWidth: $wWidth, '
        'wDiameter: $wDiameter, '
        'wSideLength: $wSideLength, '
        'wLength: $wLength, '
        'wCapacity: $wCapacity, '
        'wOffset: $wOffset';
  }
}