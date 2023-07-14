import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import 'package:intl/intl.dart';
import 'package:iot_theapp_web/main.dart';
import 'package:iot_theapp_web/objectbox.g.dart';
import 'package:iot_theapp_web/objectbox/user.dart';
import 'package:iot_theapp_web/pages/device/database/device_database.dart';
import 'package:iot_theapp_web/pages/device/model/device.dart';
import 'package:iot_theapp_web/pages/device/model/notification.dart' as Notify;
import 'package:iot_theapp_web/pages/device/model/operated_log.dart';
import 'package:iot_theapp_web/pages/device/model/operation_unit.dart';
import 'package:iot_theapp_web/pages/device/model/tank.dart';
import 'package:iot_theapp_web/pages/device/model/task.dart';
import 'package:iot_theapp_web/pages/device/model/weather_history.dart';
import 'package:iot_theapp_web/pages/device/view/line_chart_live.dart';
import 'package:iot_theapp_web/pages/device/view/temp_operation_unit_list.dart';
import 'package:iot_theapp_web/pages/device/view/utils.dart';
// import 'package:iot_theapp_web/pages/user/model/user.dart';
import 'package:iot_theapp_web/utils/constants.dart';

import 'package:http/http.dart' as http;
import 'package:iot_theapp_web/globals.dart' as globals;
import 'package:iot_theapp_web/utils/sizes_helpers.dart';

import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:unique_identifier/unique_identifier.dart';

import 'package:validators/validators.dart';

import '../../../line_chart_sample10.dart';
import 'data.dart';
import 'indicator.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import  'package:intl/intl.dart';

// final client = MqttServerClient('test.mosquitto.org', '');
final client = MqttServerClient('broker.hivemq.com', '');

var pongCount = 0; // Pong counter

// const topic = 'test/lol'; // Not a wildcard topic
// String topic_thePump = 'watersupply/gundam/pump/84:CC:A8:88:6E:07/status'; // Not a wildcard topic

class ShowDevicePage extends StatefulWidget {
  final String deviceUid;
  final Device device;

  final weekDays = const ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  final List<double> yValues = const [1.3, 1, 1.8, 1.5, 2.2, 1.8, 3];

  const ShowDevicePage(
      {Key? key, required this.deviceUid, required this.device})
      : super(key: key);

  @override
  _ShowDevicePageState createState() => _ShowDevicePageState(deviceUid, device);
}

class _ShowDevicePageState extends State<ShowDevicePage>
    with AfterLayoutMixin<ShowDevicePage> {

  // final ValueNotifier<bool> isOrderSubmitted = ValueNotifier<bool>(false);
  // DatabaseReference _operationTaskRef;
  bool isInitiatedPage = false;
  int iCountdown = Constants.INTERVAL_3_MIN_IN_SECOND;
  // Timer _timer_countdown;

  String deviceUid = '';
  Device device = Device();
  Notify.Notification notification = Notify.Notification();
  Notify.Notification notificationDialog = Notify.Notification();
  static Tank tank = Tank();
  Tank tankDialog = Tank();

  static Task task = Task();
  Task taskDialog = Task();

  bool gModeVisiblity = true;
  int gRefreshPage = 0;

  var f = NumberFormat("###.##", "en_US");

  String gOperationMode = Constants.MODE_AUTO;

  static final _offsetFormKey = GlobalKey<FormState>();
  static final _capacityFormKey = GlobalKey<FormState>();
  static final _heightFormKey = GlobalKey<FormState>();
  static final _widthFormKey = GlobalKey<FormState>();
  static final _lengthFormKey = GlobalKey<FormState>();
  static final _diameterFormKey = GlobalKey<FormState>();
  static final _sideLengthFormKey = GlobalKey<FormState>();

  // User user = const User(uid: 'cray');
  int? userId;
  User? user;

  String g_platform_mac_address = 'Unknown';

  // late DeviceDatabase deviceDatabase;

  bool sec10Pressed = false;
  bool sec30Pressed = false;
  bool min1Pressed = false;
  bool min2Pressed = false;
  bool min3Pressed = false;
  bool min4Pressed = false;
  bool min5Pressed = false;
  bool min30Pressed = false;
  bool hour1Pressed = false;
  bool hour2Pressed = false;
  bool hour3Pressed = false;
  bool hour4Pressed = false;

  bool burstePressed = false;
  bool requestPressed = false;
  bool pollingPressed = false;
  bool offlinePressed = false;

  int selectedInterval = 5000; // milliseconds

  // Draw Live Line Chart
  final Color tempColor = Colors.orangeAccent;
  final Color humidColor = Colors.blueAccent;
  final Color readDistanceColor = Colors.redAccent;

  final limitCount = 100;
  final tempPoints = <FlSpot>[];
  final humidPoints = <FlSpot>[];
  final readDistancePoints = <FlSpot>[];

  List<String> dateTimeValues = <String>[];

  double xValue = 0;
  double step = 1; // original 0.05;

  late double touchedValue;

  // _ShowDevicePageState(String deviceUid, Device device) {
  //   this.deviceUid = deviceUid;
  //   this.device = device;
  // }

  // Notification Settings
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _emailFormKey = GlobalKey<FormState>();

  late TextEditingController name_controller;
  String name = '';

  // static List<String> pickerValues = ['0', '1',];
  // static List<String> pickerHTValues = [
  //   '0',
  //   '1',
  //   '2',
  //   '3',
  //   '4',
  //   '5',
  //   '6',
  //   '7',
  //   '8',
  //   '9',
  //   '10',
  //   '11',
  //   '12',
  //   '13',
  //   '14',
  //   '15',
  //   '16',
  //   '17',
  //   '18',
  //   '19',
  //   '20',
  //   '21',
  //   '22',
  //   '23',
  //   '24',
  //   '25',
  //   '26',
  //   '27',
  //   '28',
  //   '29',
  //   '30',
  //   '31',
  //   '32',
  //   '33',
  //   '34',
  //   '35',
  //   '36',
  //   '37',
  //   '38',
  //   '39',
  //   '40',
  //   '41',
  //   '42',
  //   '43',
  //   '44',
  //   '45',
  //   '46',
  //   '47',
  //   '48',
  //   '49',
  //   '50',
  //   '51',
  //   '52',
  //   '53',
  //   '54',
  //   '55',
  //   '56',
  //   '57',
  //   '58',
  //   '59',
  //   '60',
  //   '61',
  //   '62',
  //   '63',
  //   '64',
  //   '65',
  //   '66',
  //   '67',
  //   '68',
  //   '69',
  //   '70',
  //   '71',
  //   '72',
  //   '73',
  //   '74',
  //   '75',
  //   '76',
  //   '77',
  //   '78',
  //   '79',
  //   '80',
  //   '81',
  //   '82',
  //   '83',
  //   '84',
  //   '85',
  //   '86',
  //   '87',
  //   '88',
  //   '89',
  //   '90',
  //   '91',
  //   '92',
  //   '93',
  //   '94',
  //   '95',
  //   '96',
  //   '97',
  //   '98',
  //   '99',
  //   '100',
  // ];

  static String mSelectedTankType = Constants.TANK_TYPE_SIMPLE;
  bool mVisibilityHWL = false;
  bool mVisibilityLD = false;
  double mPercentage = -1;

  List<OperationUnit> operationUnitLists = [];
  List<OperationUnit> sensorOperationUnitLists = [];
  OperationUnit mSensorOperationUnit = OperationUnit(id: '',
    uid: '',
    index: 0,
    name: '',
    status: 'wait',
    user: '',
    sensor: '',
    updatedWhen: '2022-11-11 11:11:11');

  WeatherData mWeatherData = WeatherData(uid: '', temperature: 0, humidity: 0, deviceId: '', readVoltage: 0, wRangeDistance: 0, wFilledDepth: 0, wHeight: 0, wWidth: 0, wDiameter: 0, wSideLength: 0, wLength: 0, wCapacity: 0, wOffset: 0);
  // List<OperationUnit> tempOperationUnitLists = [];
  // Map<int, bool> selectedOperationUnitFlag = {};
  // bool isSelectionOperationUnitMode = false;

  // int selectedIndex = 0;

  // int selectedIndex = 0;

  // bool _checked = false;
  // Color color = Colors.black45;
  // bool isSelected = false;

  // Horizontal List Wheel
  // List<Widget> items = [
  //   Center(
  //       child: Container(
  //     width: 100,
  //     height: 50,
  //     padding: new EdgeInsets.all(10.0),
  //     child: Card(
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(15.0),
  //       ),
  //       color: Colors.red,
  //       elevation: 10,
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: <Widget>[
  //           const ListTile(
  //             leading: Icon(Icons.album, size: 60),
  //             title: Text('Sonu Nigam', style: TextStyle(fontSize: 30.0)),
  //             subtitle: Text('Best of Sonu Nigam Music.',
  //                 style: TextStyle(fontSize: 18.0)),
  //           ),
  //           ButtonBar(
  //             children: <Widget>[
  //               RaisedButton(
  //                 child: const Text('Play'),
  //                 onPressed: () {/* ... */},
  //               ),
  //               RaisedButton(
  //                 child: const Text('Pause'),
  //                 onPressed: () {/* ... */},
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   )),
  //   ListTile(
  //     leading: Icon(Icons.local_activity, size: 50),
  //     title: Text('Activity'),
  //     subtitle: Text('Description here'),
  //   ),
  //   ListTile(
  //     leading: Icon(Icons.local_airport, size: 50),
  //     title: Text('Airport'),
  //     subtitle: Text('Description here'),
  //   ),
  //   ListTile(
  //     leading: Icon(Icons.local_atm, size: 50),
  //     title: Text('ATM'),
  //     subtitle: Text('Description here'),
  //   ),
  //   ListTile(
  //     leading: Icon(Icons.local_bar, size: 50),
  //     title: Text('Bar'),
  //     subtitle: Text('Description here'),
  //   ),
  //   ListTile(
  //     leading: Icon(Icons.local_cafe, size: 50),
  //     title: Text('Cafe'),
  //     subtitle: Text('Description here'),
  //   ),
  //   ListTile(
  //     leading: Icon(Icons.local_car_wash, size: 50),
  //     title: Text('Car Wash'),
  //     subtitle: Text('Description here'),
  //   ),
  //   ListTile(
  //     leading: Icon(Icons.local_convenience_store, size: 50),
  //     title: Text('Heart Shaker'),
  //     subtitle: Text('Description here'),
  //   ),
  //   ListTile(
  //     leading: Icon(Icons.local_dining, size: 50),
  //     title: Text('Dining'),
  //     subtitle: Text('Description here'),
  //   ),
  //   ListTile(
  //     leading: Icon(Icons.local_drink, size: 50),
  //     title: Text('Drink'),
  //     subtitle: Text('Description here'),
  //   ),
  //   ListTile(
  //     leading: Icon(Icons.local_florist, size: 50),
  //     title: Text('Florist'),
  //     subtitle: Text('Description here'),
  //   ),
  //   ListTile(
  //     leading: Icon(Icons.local_gas_station, size: 50),
  //     title: Text('Gas Station'),
  //     subtitle: Text('Description here'),
  //   ),
  //   ListTile(
  //     leading: Icon(Icons.local_grocery_store, size: 50),
  //     title: Text('Grocery Store'),
  //     subtitle: Text('Description here'),
  //   ),
  // ];

  _ShowDevicePageState(this.deviceUid, this.device);

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initUniqueIdentifierState() async {
    String identifier;
    try {
      identifier = (await UniqueIdentifier.serial)!;
      print('=====identifier=${identifier}');
    } on PlatformException {
      identifier = 'Failed to get Unique Identifier';
    }

    if (!mounted) return;

    setState(() {
      g_platform_mac_address = identifier;
      print('++++++g_platform_mac_address=${g_platform_mac_address}');
    });
  }

  @override
  void initState() {
    touchedValue = -1;

    gRefreshPage = 0;

    // for (int i = 0; i < 10; i++) {
    //   data.add(Random().nextInt(100) + 1);
    // }

    // for(int i=0; i < 100;i++) {
    //   pickerValues[i] = i.toString();
    // }
    // print('pickerValues.length=${pickerValues.length}');

    super.initState();
    initUniqueIdentifierState(); // get theApp's device mac address

    notification = Notify.Notification();
    mSelectedTankType = (device.wTankType != "") ? device.wTankType : Constants.TANK_TYPE_SIMPLE;

    print('mSelectedTankType=${mSelectedTankType}');

    // --------------------
    tempPoints.add(FlSpot(xValue, 0));
    humidPoints.add(FlSpot(xValue, 0));
    readDistancePoints.add(FlSpot(xValue, 0));

    dateTimeValues.add('_');
    print('init state');
    print(
        'tempPoints[tempPoints.length-1].x=${tempPoints[tempPoints.length - 1].x}');
    print(
        'tempPoints[tempPoints.length-1].y=${tempPoints[tempPoints.length - 1].y}');
    print(
        'dateTimeValues[dateTimeValues.length-1]=${dateTimeValues[dateTimeValues.length - 1]}');
    print('tempPoints.length=${tempPoints.length}');
    print('dateTimeValues.length=${dateTimeValues.length}');
    xValue += step;
    // --------------------

    // Load necessary cloud database
    // may be not use
    // deviceDatabase = DeviceDatabase(device: device, user: user);
    // deviceDatabase.initState();

    name_controller = TextEditingController();

    if(objectbox.userBox.isEmpty()) {
      print('**** none user');

      print('**** then add demo one.');
      user = User();
      user?.userName = 'demo';
      user?.password = '';
      user?.updatedWhen = '2022-10-18 15:50:43';
      final id = objectbox.userBox.put(user!);
      userId = id;

      print('new demo user got id=${id}, which is the same as note.id=${user!.id} | userId=${userId}');
      print('re-read user: ${objectbox.userBox.get(userId!)}');


    } else {
      // print('**** user length=${objectbox.userBox.getAll().length}');

      if(objectbox.userBox.getAll().length > 0) {
        List<User> userList = objectbox.userBox.getAll();
        userId = userList[0].id;
        print('re-read user[${userId}]: ${objectbox.userBox.get(userId!)}');
        user = userList[0];

        // Test re-write user objectbox
        // user!.userName = 'cray';
        // objectbox.userBox.put(user!);
        // print('renew-read user[${userId}]: ${objectbox.userBox.get(userId!)}');
      }
    }

    // check for do once when init page
    isInitiatedPage = false;
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      // do something
      print("Build Completed");
      print('users/${user!.userName}/devices/${device.uid}/tasks');
      var _operationTaskRef = FirebaseDatabase.instance
          .ref()
          .child('users/${user!.userName}/devices/${device.uid}/tasks');
      _operationTaskRef.onValue.listen((event) {
        // Database has been updated
        DataSnapshot dataSnapshot = event.snapshot;
        // Perform your desired action here
        // Access the data using dataSnapshot.value
        if(!isInitiatedPage) {
          print('[[[[Do nothing at 1st time]]]]');
          isInitiatedPage = true;
        } else {
          print('task Database updated: ${dataSnapshot.value}');
          startTimer();

          Future.delayed(Duration(minutes: 3), () {
            // This code will execute after 3minutes
            // Republish manual order to make sure thePump can get command.
            print('<<<Task executed!: --->>>');
            callMQTTPageRePublishSubmit();

          });
        }

      });
      // callMQTTSubscribe();
      // callMQTTConnect();
    });
  }

  @override
  void dispose() {
    // Dispose database.
    name_controller.dispose();

    // _timer_countdown.cancel();

    // disconnect MQTT
    client.disconnect();
    print('EXAMPLE::Exiting normally');

    super.dispose();

    // deviceDatabase.dispose();
  }

  LineTouchData get lineTouchDataTempHumid => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              print('touchedBarSpots.length=${touchedBarSpots.length}');
              print('touchedBarSpots.toString=${touchedBarSpots.toString()}');

              return touchedBarSpots.map((barSpot) {
                print('barSpot.barIndex=${barSpot.barIndex}');
                print('barSpot.spotIndex=${barSpot.spotIndex}');
                final flSpot = barSpot;
                // if (flSpot.x == 0 || flSpot.x == 6) {
                //   return null;
                // }
                if (flSpot.x == 0) {
                  return null;
                }

                // TextAlign textAlign;
                // switch (flSpot.x.toInt()) {
                //   case 1:
                //     textAlign = TextAlign.left;
                //     break;
                //   case 5:
                //     textAlign = TextAlign.right;
                //     break;
                //   default:
                //     textAlign = TextAlign.center;
                // }
                TextAlign textAlign = TextAlign.center;
                String dateTimeString = '';
                if (barSpot.barIndex == 1) {
                  dateTimeString =
                      '${dateTimeValues[flSpot.x.toInt()].toString()}\n';
                }
                print('dateTimeString=${dateTimeString}');

                return LineTooltipItem(
                  // '${widget.weekDays[flSpot.x.toInt()]} \n',
                  // '${dateTimeString}${flSpot.y.toString()}',
                  '${dateTimeString}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: flSpot.y.toString(),
                      style: TextStyle(
                        color: Colors.grey[100],
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    // const TextSpan(
                    //   text: ' k ',
                    //   style: TextStyle(
                    //     fontStyle: FontStyle.italic,
                    //     fontWeight: FontWeight.normal,
                    //   ),
                    // ),
                    // const TextSpan(
                    //   text: 'calories',
                    //   style: TextStyle(
                    //     fontWeight: FontWeight.normal,
                    //   ),
                    // ),
                  ],
                  textAlign: textAlign,
                );
              }).toList();
            }),
        // touchCallback:
        //     (FlTouchEvent event, LineTouchResponse? lineTouch) {
        //   if (!event.isInterestedForInteractions ||
        //       lineTouch == null ||
        //       lineTouch.lineBarSpots == null) {
        //     setState(() {
        //       touchedValue = -1;
        //     });
        //     return;
        //   }
        //   final value = lineTouch.lineBarSpots![0].x;
        //
        //   if (value == 0 || value == 6) {
        //     setState(() {
        //       touchedValue = -1;
        //     });
        //     return;
        //   }
        //
        //   setState(() {
        //     touchedValue = value;
        //   });
        // }
      );

  LineTouchData get lineTouchDataReadDistance => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          print('touchedBarSpots.length=${touchedBarSpots.length}');
          print('touchedBarSpots.toString=${touchedBarSpots.toString()}');

          return touchedBarSpots.map((barSpot) {
            print('barSpot.barIndex=${barSpot.barIndex}');
            print('barSpot.spotIndex=${barSpot.spotIndex}');
            final flSpot = barSpot;
            // if (flSpot.x == 0 || flSpot.x == 6) {
            //   return null;
            // }
            if (flSpot.x == 0) {
              return null;
            }

            // TextAlign textAlign;
            // switch (flSpot.x.toInt()) {
            //   case 1:
            //     textAlign = TextAlign.left;
            //     break;
            //   case 5:
            //     textAlign = TextAlign.right;
            //     break;
            //   default:
            //     textAlign = TextAlign.center;
            // }
            TextAlign textAlign = TextAlign.center;
            String dateTimeString = '';
            if (barSpot.barIndex == 0) {
              dateTimeString =
              '${dateTimeValues[flSpot.x.toInt()].toString()}\n';
            }
            print('dateTimeString=${dateTimeString}');

            return LineTooltipItem(
              // '${widget.weekDays[flSpot.x.toInt()]} \n',
              // '${dateTimeString}${flSpot.y.toString()}',
              '${dateTimeString}',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: flSpot.y.toString(),
                  style: TextStyle(
                    color: Colors.grey[100],
                    fontWeight: FontWeight.normal,
                  ),
                ),
                // const TextSpan(
                //   text: ' k ',
                //   style: TextStyle(
                //     fontStyle: FontStyle.italic,
                //     fontWeight: FontWeight.normal,
                //   ),
                // ),
                // const TextSpan(
                //   text: 'calories',
                //   style: TextStyle(
                //     fontWeight: FontWeight.normal,
                //   ),
                // ),
              ],
              textAlign: textAlign,
            );
          }).toList();
        }),
    // touchCallback:
    //     (FlTouchEvent event, LineTouchResponse? lineTouch) {
    //   if (!event.isInterestedForInteractions ||
    //       lineTouch == null ||
    //       lineTouch.lineBarSpots == null) {
    //     setState(() {
    //       touchedValue = -1;
    //     });
    //     return;
    //   }
    //   final value = lineTouch.lineBarSpots![0].x;
    //
    //   if (value == 0 || value == 6) {
    //     setState(() {
    //       touchedValue = -1;
    //     });
    //     return;
    //   }
    //
    //   setState(() {
    //     touchedValue = value;
    //   });
    // }
  );

  double calculateFilledPercentage(String tankType, WeatherHistory weatherHistory) {
    double result = 0;
    switch(tankType) {
      // Simple Tank
      case Constants.TANK_TYPE_SIMPLE: {
        double height = _ShowDevicePageState.tank.wHeight; // cm
        double rangeDistance = weatherHistory.weatherData.wRangeDistance / 10; // convert mm to cm

        double filledDepth=height - rangeDistance;

        double percentage = (filledDepth / height) * 100;

        // print("height=$height");
        // print("rangeDistance=$rangeDistance");
        // print("Filled depth=$filledDepth");
        // print("percentage=$percentage");

        result = percentage;
        break;
      }
      // Horizontal Cylinder Tank
      case Constants.TANK_TYPE_HORIZONTAL_CYLINDER: {
        double diameter = _ShowDevicePageState.tank.wDiameter; // cm
        double rangeDistance = weatherHistory.weatherData.wRangeDistance / 10; // convert mm to cm

        double filledDepth=diameter - rangeDistance;

        double percentage = (filledDepth / diameter) * 100;

        // print("height=$diameter");
        // print("rangeDistance=$rangeDistance");
        // print("Filled depth=$filledDepth");
        // print("percentage=$percentage");

        result = percentage;
        break;
      }

      // Vertical Cylinder Tank
      // - ok
      case Constants.TANK_TYPE_VERTICAL_CYLINDER: {
        double height = _ShowDevicePageState.tank.wHeight; // cm
        double rangeDistance = weatherHistory.weatherData.wRangeDistance / 10; // convert mm to cm

        double filledDepth=height - rangeDistance;

        double percentage = (filledDepth / height) * 100;

        // print("height=$height");
        // print("rangeDistance=$rangeDistance");
        // print("Filled depth=$filledDepth");

        result = percentage;
        break;
      }

      case Constants.TANK_TYPE_RECTANGLE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = volume;
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_OVAL: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        print("Volume of the cylinder=$volume");

        result = volume;
        break;
      }

      case Constants.TANK_TYPE_VERTICAL_OVAL: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        print("Volume of the cylinder=$volume");

        result = volume;
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_CAPSULE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        print("Volume of the cylinder=$volume");

        result = volume;
        break;
      }

      case Constants.TANK_TYPE_VERTICAL_CAPSULE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        print("Volume of the cylinder=$volume");

        result = volume;
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_2_1_ELLIPTICAL: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        print("Volume of the cylinder=$volume");

        result = volume;
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_DISH_ENDS: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        print("Volume of the cylinder=$volume");

        result = volume;
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_ELLIPSE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        print("Volume of the cylinder=$volume");

        result = volume;
        break;
      }
      default: {
        break;
      }
    }



    return result;
  }

  String calculateFilledDepth(String tankType, WeatherHistory weatherHistory) {
    String result = '';

    switch(tankType) {
      // Simple Tank
      case Constants.TANK_TYPE_SIMPLE: {
        double height = _ShowDevicePageState.tank.wHeight; // cm
        double rangeDistance = weatherHistory.weatherData.wRangeDistance / 10; // convert mm to cm

        double filledDepth=height - rangeDistance;

        // print("height=$height");
        // print("rangeDistance=$rangeDistance");
        // print("Filled depth=$filledDepth");

        result = globals.formatNumber(filledDepth);
        break;
      }
      // Horizontal Cylinder Tank
      case Constants.TANK_TYPE_HORIZONTAL_CYLINDER: {
        double diameter = _ShowDevicePageState.tank.wDiameter; // height = diameter
        double radius = diameter / 2;

        double rangeDistance = weatherHistory.weatherData.wRangeDistance / 10; // convert mm to cm

        double filledHeight=diameter - rangeDistance;
        double filledDepth=(((radius - filledHeight) / radius)*(radius * radius)) - (radius - filledHeight)*sqrt((2*radius*filledHeight) - (filledHeight*filledHeight));

        // print("diameter=$diameter");
        // print("rangeDistance=$rangeDistance");
        // print("Filled depth=$filledDepth");

        result = globals.formatNumber(filledDepth);
        break;
      }

      // Vertical Cylinder Tank
      // Filled Depth = height - rangeDistance
      case Constants.TANK_TYPE_VERTICAL_CYLINDER: {
        double height = _ShowDevicePageState.tank.wHeight; // cm
        double rangeDistance = weatherHistory.weatherData.wRangeDistance / 10; // convert mm to cm

        double filledDepth=height - rangeDistance;

        // print("height=$height");
        // print("rangeDistance=$rangeDistance");
        // print("Filled depth=$filledDepth");

        result = globals.formatNumber(filledDepth);
        break;
      }

      case Constants.TANK_TYPE_RECTANGLE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = volume.toString();
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_OVAL: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = volume.toString();
        break;
      }

      case Constants.TANK_TYPE_VERTICAL_OVAL: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = volume.toString();
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_CAPSULE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = volume.toString();
        break;
      }

      case Constants.TANK_TYPE_VERTICAL_CAPSULE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = volume.toString();
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_2_1_ELLIPTICAL: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = volume.toString();
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_DISH_ENDS: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = volume.toString();
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_ELLIPSE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = volume.toString();
        break;
      }
      default: {
        break;
      }
    }
    return result;
  }

  String calculateTankVolume(String tankType) {
    String result = '';
    // dimensions default in cm

    switch(tankType) {
      // Simple Tank
      // Capacity = Volume
      case Constants.TANK_TYPE_SIMPLE: {
        double volume = _ShowDevicePageState.tank.wCapacity;
        // print("Volume of the tank=$volume");

        result = globals.formatNumber(volume);
        break;
      }

      // Horizontal Cylinder Tank
      // V(tank) = πr2l
      case Constants.TANK_TYPE_HORIZONTAL_CYLINDER: {
        double length = _ShowDevicePageState.tank.wLength;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;

        double volume=Constants.pie*(radius*radius)*length;
        volume = volume / 1000; // to centimeters
        // print("Volume of the cylinder=$volume");

        result = globals.formatNumber(volume);
        break;
      }
      // Vertical Cylinder Tank
      // V(tank) = πr2h
      // - ok
      case Constants.TANK_TYPE_VERTICAL_CYLINDER: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;

        double volume=Constants.pie*(radius*radius)*height;
        volume = volume / 1000; // to centimeters
        // print("Volume of the cylinder=$volume");

        result = globals.formatNumber(volume);
        break;
      }

      case Constants.TANK_TYPE_RECTANGLE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = globals.formatNumber(volume);
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_OVAL: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = globals.formatNumber(volume);

        break;
      }

      case Constants.TANK_TYPE_VERTICAL_OVAL: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = globals.formatNumber(volume);
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_CAPSULE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = globals.formatNumber(volume);
        break;
      }

      case Constants.TANK_TYPE_VERTICAL_CAPSULE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = globals.formatNumber(volume);
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_2_1_ELLIPTICAL: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = globals.formatNumber(volume);
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_DISH_ENDS: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = globals.formatNumber(volume);
        break;
      }

      case Constants.TANK_TYPE_HORIZONTAL_ELLIPSE: {
        double height = _ShowDevicePageState.tank.wHeight;
        double radius = _ShowDevicePageState.tank.wDiameter / 2;
        double pie=3.14285714286;
        double volume=pie*(radius*radius)*height;
        // print("Volume of the cylinder=$volume");

        result = globals.formatNumber(volume);
        break;
      }
      default: {
        break;
      }
    }
    return result;
  }

  String getPumpRelayStatusImage(String pumpRelayStatus) {
    String result = '';
    switch (pumpRelayStatus) {
      case 'On': {
        result = 'images/pump_turn_on.png';
        break;
      }
      case 'Off': {
        result = 'images/pump_turn_off.png';
        break;
      }
      case 'Overtime': {
        result = 'images/pump_turn_off.png';
        break;
      }
      default: { // 'Overtime' (Time over)
        result = 'images/pump_empty.png';
        break;
      }

    }
    return result;
  }

  String getFilledTankPercentageImage(String tankType) {
    String result = '';
    switch (tankType) {
      case Constants.TANK_TYPE_RECTANGLE:
      case Constants.TANK_TYPE_HORIZONTAL_OVAL:
      case Constants.TANK_TYPE_VERTICAL_OVAL:
      case Constants.TANK_TYPE_HORIZONTAL_ELLIPSE:
        {

          break;
        }
      // case Constants.TANK_TYPE_VERTICAL_CYLINDER:
      //   {
      //
      //     break;
      //   }
      case Constants.TANK_TYPE_HORIZONTAL_CYLINDER:
        {

          break;
        }

      case Constants.TANK_TYPE_VERTICAL_CYLINDER:
      case Constants.TANK_TYPE_SIMPLE:
        {
          if(mPercentage <= 100 && mPercentage > 75) {
            // Constants.gFilledTankPercentageImagesMap[tankType].keys!.elementAt(0)
            // _SelectedTankType = Constants.gTankTypesMap!.keys.elementAt(index);
            result = Constants.gFilledTankPercentageImagesMap[tankType]!.values.elementAt(4);
          } else  if(mPercentage <= 75 && mPercentage > 50) {
            result = Constants.gFilledTankPercentageImagesMap[tankType]!.values.elementAt(3);
          } else  if(mPercentage <= 50 && mPercentage > 25) {
            result = Constants.gFilledTankPercentageImagesMap[tankType]!.values.elementAt(2);
          } else  if(mPercentage <= 25 && mPercentage > 0) {
            result = Constants.gFilledTankPercentageImagesMap[tankType]!.values.elementAt(1);
          } else {
            result = Constants.gFilledTankPercentageImagesMap[tankType]!.values.elementAt(0);
          }
          break;
        }

      case Constants.TANK_TYPE_HORIZONTAL_CAPSULE:
      case Constants.TANK_TYPE_VERTICAL_CAPSULE:
      case Constants.TANK_TYPE_HORIZONTAL_2_1_ELLIPTICAL:
      case Constants.TANK_TYPE_HORIZONTAL_DISH_ENDS:
        {

          break;
        }
      default:
        result = result;
    }

    // Verify the latest device status
    String currentDateStr = DateFormat("yyyy-MM-dd").format(DateTime.now());
    String currentTimeStr = DateFormat("HH:mm:ss").format(DateTime.now());
    String currentDateTimeStr = '$currentDateStr $currentTimeStr';

    DateTime dt1;
    if(mWeatherData.uid == '') {
      dt1 = DateTime.parse(currentDateTimeStr);
    } else {
      dt1 = DateTime.parse(mWeatherData.uid);
    }


    DateTime dt2 = DateTime.parse(currentDateTimeStr);

    if(dt1.compareTo(dt2) < 0){
      // print("DT1 is before DT2");
      // print('mSensorOperationUnit.updatedWhen=${mWeatherData.uid}');
      // print('currentDateTimeStr=${currentDateTimeStr}');
      Duration diff = dt1.difference(dt2);
      // print('diff.inMinutes=${diff.inMinutes.abs()}');
      if(diff.inMinutes.abs() == 0) {
        return result;
      } else if(diff.inMinutes.abs() > (device.readingInterval / 60000)) {
        // result = 'Lost connect1';
        result = 'images/tanks/simple_tank_type_lost.png';
      }
    }

    return result;
  }

  String getOperationModeText(String mode) {
    String result = '';
    switch(mode) {
      case Constants.MODE_MANUAL: {
        result = 'Manual Mode';
      }
      break;
      case Constants.MODE_AUTO:{
        result = 'AUTO Mode';
      }
      break;
    }
    return result;
  }

  Future<void> callMQTTConnect() async {
    /// A websocket URL must start with ws:// or wss:// or Dart will throw an exception, consult your websocket MQTT broker
    /// for details.
    /// To use websockets add the following lines -:
    /// client.useWebSocket = true;
    /// client.port = 80;  ( or whatever your WS port is)
    /// There is also an alternate websocket implementation for specialist use, see useAlternateWebSocketImplementation
    /// Note do not set the secure flag if you are using wss, the secure flags is for TCP sockets only.
    /// You can also supply your own websocket protocol list or disable this feature using the websocketProtocols
    /// setter, read the API docs for further details here, the vast majority of brokers will support the client default
    /// list so in most cases you can ignore this.

    /// Set logging on if needed, defaults to off
    client.logging(on: true);

    /// Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    /// If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
    client.keepAlivePeriod = 20;

    /// The connection timeout period can be set if needed, the default is 5 seconds.
    client.connectTimeoutPeriod = 2000; // milliseconds

    /// Add the unsolicited disconnection callback
    client.onDisconnected = onDisconnected;

    /// Add the successful connection callback
    client.onConnected = onConnected;

    /// Set a ping received callback if needed, called whenever a ping response(pong) is received
    /// from the broker.
    client.pongCallback = pong;

    /// Create a connection message to use or use the default one. The default one sets the
    /// client identifier, any supplied username/password and clean session,
    /// an example of a specific one below.
    final connMess = MqttConnectMessage()
    // .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withClientIdentifier(g_platform_mac_address)
        .withWillTopic('willtopic') // If you set this you must set a will message
        .withWillMessage('IoT Cray Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::HiveMQTT client ${g_platform_mac_address} connecting....');
    client.connectionMessage = connMess;

    /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
    /// never send malformed messages.
    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('EXAMPLE::socket exception - $e');
      client.disconnect();
    }

    /// Check we are connected
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      print(
          'EXAMPLE::ERROR 1 Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      // exit(-1);
    }

    /// Ok, we will now sleep a while, in this gap you will see ping request/response
    /// messages being exchanged by the keep alive mechanism.
    print('EXAMPLE::Sleeping....');
    await MqttUtilities.asyncSleep(60);

    // client.disconnect();
    // print('EXAMPLE::Exiting normally');

    return;
  }

  Future<void> callMQTTPublishMonitor(String command) async {
    // Set logging on if needed, defaults to off
    client.logging(on: true);

    // Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    // If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
    client.keepAlivePeriod = 20;

    // The connection timeout period can be set if needed, the default is 5 seconds.
    client.connectTimeoutPeriod = 2000; // milliseconds

    // Add the unsolicited disconnection callback
    client.onDisconnected = onDisconnected;

    // Add the successful connection callback
    client.onConnected = onConnected;

    // Add a subscribed callback, there is also an unsubscribed callback if you need it.
    // You can add these before connection or change them dynamically after connection if
    // you wish. There is also an onSubscribeFail callback for failed subscriptions, these
    // can fail either because you have tried to subscribe to an invalid topic or the broker
    // rejects the subscribe request.
    client.onSubscribed = onSubscribed;

    // Set a ping received callback if needed, called whenever a ping response(pong) is received
    // from the broker.
    client.pongCallback = pong;

    // Create a connection message to use or use the default one. The default one sets the
    // client identifier, any supplied username/password and clean session,
    // an example of a specific one below.
    final connMess = MqttConnectMessage()
    // .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withClientIdentifier(g_platform_mac_address)
        .withWillTopic('willtopic') // If you set this you must set a will message
        .withWillMessage('IoT Cray Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::Mosquitto client ${g_platform_mac_address} connecting....');
    client.connectionMessage = connMess;

    // Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    // in some circumstances the broker will just disconnect us, see the spec about this, we however will
    // never send malformed messages.
    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('EXAMPLE::socket exception - $e');
      client.disconnect();
    }

    /// Check we are connected
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      print(
          'EXAMPLE::ERROR 2 Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      // exit(-1);
    }

    //String topic_theSensor = watersupply/gundam/sedimentation/84:CC:A8:88:6E:07/waterlevel/status
    String topic_theSensor = 'watersupply/${user!.userName}/sedimentation/${widget.device.uid}/waterlevel/status';

    // create mqtt command to switch on/off thePump
    final builder = MqttClientPayloadBuilder();

    String mqtt_command = Constants.MQTT_COMMAND_SWITCH_OFF;
    if(command == Constants.SWITCH_ON) {
      mqtt_command ='${Constants.MQTT_COMMAND_SWITCH_ON}${Constants.INTERVAL_MINUTE_5}';
    } else if(command == Constants.SWITCH_OFF) {
      mqtt_command ='${Constants.MQTT_COMMAND_SWITCH_OFF}${Constants.INTERVAL_MINUTE_5}';
    }

    builder.addString(mqtt_command);

    /// Subscribe to it
    // print('EXAMPLE::Subscribing to the Dart/Mqtt_client/testtopic topic');
    // client.subscribe(pubTopic, MqttQos.exactlyOnce);

    // Publish it
    print('EXAMPLE::Publishing our topic');
    client.publishMessage(topic_theSensor, MqttQos.exactlyOnce, builder.payload!);


    /// Ok, we will now sleep a while, in this gap you will see ping request/response
    /// messages being exchanged by the keep alive mechanism.
    print('EXAMPLE::Sleeping....');
    await MqttUtilities.asyncSleep(60);

    client.disconnect();
    print('EXAMPLE::Exiting normally');

    return;
  }

  Future<void> callMQTTPageRePublishSubmit() async {
    // Set logging on if needed, defaults to off
    client.logging(on: true);

    // Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    // If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
    client.keepAlivePeriod = 20;

    // The connection timeout period can be set if needed, the default is 2 seconds.
    client.connectTimeoutPeriod = 2000; // milliseconds

    // Add the unsolicited disconnection callback
    client.onDisconnected = onDisconnected;

    // Add the successful connection callback
    client.onConnected = onConnected;

    // Set a ping received callback if needed, called whenever a ping response(pong) is received
    // from the broker.
    client.pongCallback = pong;

    // Create a connection message to use or use the default one. The default one sets the
    // client identifier, any supplied username/password and clean session,
    // an example of a specific one below.
    final connMess = MqttConnectMessage()
    // .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withClientIdentifier(g_platform_mac_address)
        .withWillTopic('willtopic') // If you set this you must set a will message
        .withWillMessage('IoT Cray Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::HiveMQTT client ${g_platform_mac_address} connecting....');
    client.connectionMessage = connMess;

    // Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    // in some circumstances the broker will just disconnect us, see the spec about this, we however will
    // never send malformed messages.
    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('EXAMPLE::socket exception - $e');
      client.disconnect();
    }

    // Check we are connected
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      print(
          'EXAMPLE::ERROR 3 Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      // exit(-1);
    }

    // If needed you can listen for published messages that have completed the publishing
    // handshake which is Qos dependant. Any message received on this stream has completed its
    // publishing handshake with the broker.
    // client.published!.listen((MqttPublishMessage message) {
    //   print(
    //       'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
    // });

    // Lets publish to our topic
    // Use the payload builder rather than a raw buffer
    // Our known topic to publish to
    String topic_theSensor = 'watersupply/${user!.userName}/sedimentation/${device.uid}/waterlevel/status';

    // create mqtt command to switch on/off thePump
    final builder = MqttClientPayloadBuilder();
    if(task.operationMode == Constants.MODE_MANUAL) {
      String mqtt_command = Constants.MQTT_COMMAND_SWITCH_OFF;
      if(task.command == Constants.SWITCH_ON) {
        mqtt_command ='${Constants.MQTT_COMMAND_SWITCH_ON}${task.operationPeriod}';
      } else if(task.command == Constants.SWITCH_OFF) {
        mqtt_command ='${Constants.MQTT_COMMAND_SWITCH_OFF}${task.operationPeriod}';
      }

      builder.addString(mqtt_command);

      // Publish it
      print('EXAMPLE::Re-Publishing our topic');
      client.publishMessage(topic_theSensor, MqttQos.atLeastOnce, builder.payload!);
    }

    // Ok, we will now sleep a while, in this gap you will see ping request/response
    // messages being exchanged by the keep alive mechanism.
    print('RE-EXAMPLE::Sleeping....');
    await MqttUtilities.asyncSleep(60);

    // Wait for the unsubscribe message from the broker if you wish.
    // await MqttUtilities.asyncSleep(2);
    // print('EXAMPLE::Disconnecting');

    client.disconnect();
    print('RE-EXAMPLE::Exiting normally');

    return;
  }

  Future<void> callMQTTSubscribe() async {
    /// A websocket URL must start with ws:// or wss:// or Dart will throw an exception, consult your websocket MQTT broker
    /// for details.
    /// To use websockets add the following lines -:
    /// client.useWebSocket = true;
    /// client.port = 80;  ( or whatever your WS port is)
    /// There is also an alternate websocket implementation for specialist use, see useAlternateWebSocketImplementation
    /// Note do not set the secure flag if you are using wss, the secure flags is for TCP sockets only.
    /// You can also supply your own websocket protocol list or disable this feature using the websocketProtocols
    /// setter, read the API docs for further details here, the vast majority of brokers will support the client default
    /// list so in most cases you can ignore this.

    /// Set logging on if needed, defaults to off
    client.logging(on: true);

    /// Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    /// If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
    client.keepAlivePeriod = 20;

    /// The connection timeout period can be set if needed, the default is 5 seconds.
    client.connectTimeoutPeriod = 2000; // milliseconds

    /// Add the unsolicited disconnection callback
    client.onDisconnected = onDisconnected;

    /// Add the successful connection callback
    client.onConnected = onConnected;

    /// Add a subscribed callback, there is also an unsubscribed callback if you need it.
    /// You can add these before connection or change them dynamically after connection if
    /// you wish. There is also an onSubscribeFail callback for failed subscriptions, these
    /// can fail either because you have tried to subscribe to an invalid topic or the broker
    /// rejects the subscribe request.
    client.onSubscribed = onSubscribed;

    /// Set a ping received callback if needed, called whenever a ping response(pong) is received
    /// from the broker.
    client.pongCallback = pong;

    /// Create a connection message to use or use the default one. The default one sets the
    /// client identifier, any supplied username/password and clean session,
    /// an example of a specific one below.
    final connMess = MqttConnectMessage()
        // .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withClientIdentifier(g_platform_mac_address)
        .withWillTopic('willtopic') // If you set this you must set a will message
        .withWillMessage('IoT Cray Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::Mosquitto client ${g_platform_mac_address} connecting....');
    client.connectionMessage = connMess;

    /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
    /// never send malformed messages.
    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('EXAMPLE::socket exception - $e');
      client.disconnect();
    }

    /// Check we are connected
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      print(
          'EXAMPLE::ERROR 2 Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      // exit(-1);
    }

    /// Ok, lets try a subscription
    print('EXAMPLE::Subscribing to the test/lol topic');
    // // const topic = 'test/lol'; // Not a wildcard topic
    // const topic = 'watersupply/gundam/pump/84:CC:A8:88:6E:07/status'; // Not a wildcard topic
    // String topic_thePump = 'watersupply/gundam/pump/84:CC:A8:88:6E:07/status'; // Not a wildcard topic
    String topic_thePump = 'watersupply/${user!.userName}/pump/${device.uid}/status';
    print('Selected device will subscribing to the ${topic_thePump} topic');

    // client.subscribe(topic, MqttQos.atMostOnce);
    client.subscribe(topic_thePump, MqttQos.exactlyOnce);

    //String topic_theSensor = watersupply/gundam/sedimentation/84:CC:A8:88:6E:07/waterlevel/status
    String topic_theSensor = 'watersupply/${user!.userName}/sedimentation/${device.uid}/waterlevel/status';
    client.subscribe(topic_theSensor, MqttQos.exactlyOnce);

    /// The client has a change notifier object(see the Observable class) which we then listen to to get
    /// notifications of published updates to each subscribed topic.
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) async {
      final recMess = c![0].payload as MqttPublishMessage;
      final ptopic = c![0].topic;

      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if(ptopic == topic_thePump) {

        /// The above may seem a little convoluted for users only interested in the
        /// payload, some users however may be interested in the received publish message,
        /// lets not constrain ourselves yet until the package has been in the wild
        /// for a while.
        /// The payload is a byte buffer, this will be specific to the topic
        print(
            'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
        print('');

        // ais 4 g board - started - no
        // 1_861123056637646 - yes
        if (pt.length > 0 && pt.length < 23) {
          print('Process update device status...');

          // If have data
          //  On=1_, Off=0_, Overtime = 2_, Restart = 3_
          // On status = "1_2022-12-06 10:55:09_861123056637646"
          // Off status = "0_2022-12-06 10:55:28_861123056637646"
          //         example:
          //         0_2022-12-06 13:57:42_861123056637646
          String relay_status = 'Off';
          String relay_status_code = pt.substring(0, 1);
          // String updated_status_datetime = pt.substring(2, 21);
          String imei_uid = pt.substring(2);
          // String imei_uid = pt.substring(22);

          String currentDateStr = DateFormat("yyyy-MM-dd").format(DateTime.now());
          String currentTimeStr = DateFormat("HH:mm:ss").format(DateTime.now());
          String currentDateTimeStr = '$currentDateStr $currentTimeStr';

          // Off=0, On=1, Overtime = 2, Restart = 3
          switch (relay_status_code) {
            case "0":
              {
                relay_status = 'Off';
                break;
              }
            case "1":
              {
                relay_status = 'On';
                break;
              }
            case "2":
              {
                relay_status = 'Overtime';
                break;
              }
            case "3":
              {
                relay_status = 'Restart';
                break;
              }
            default:
              {
                relay_status = 'Off';
                break;
              }
          }

          DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$imei_uid");

          await ref.update({
            "status": relay_status,
            // "updatedWhen": updated_status_datetime,
            "updatedWhen": currentDateTimeStr,
          }).then((value) =>
              () {
            print('');
            print('Updated devices/$imei_uid  status: $relay_status is success.');
            print('');
          }).onError((error, stackTrace) =>
              () {
            print('');
            print('Updated devices/$imei_uid  status: $relay_status is failed.');
            print('');
          });
        } else {
          print('No payload data...');
        }
      }
    });

    /// If needed you can listen for published messages that have completed the publishing
    /// handshake which is Qos dependant. Any message received on this stream has completed its
    /// publishing handshake with the broker.
    // client.published!.listen((MqttPublishMessage message) {
    //   print(
    //       'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
    // });

    /// Lets publish to our topic
    /// Use the payload builder rather than a raw buffer
    /// Our known topic to publish to
    // const pubTopic = 'Dart/Mqtt_client/testtopic';
    // const pubTopic = 'watersupply/gundam/sedimentation/84:CC:A8:88:6E:07/waterlevel/status';
    // final builder = MqttClientPayloadBuilder();
    // builder.addString('Hello from mqtt_client');

    /// Subscribe to it
    // print('EXAMPLE::Subscribing to the Dart/Mqtt_client/testtopic topic');
    // client.subscribe(pubTopic, MqttQos.exactlyOnce);

    /// Publish it
    // print('EXAMPLE::Publishing our topic');
    // client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);

    /// Ok, we will now sleep a while, in this gap you will see ping request/response
    /// messages being exchanged by the keep alive mechanism.
    print('EXAMPLE::Sleeping....');
    await MqttUtilities.asyncSleep(60);

    // /// Finally, unsubscribe and exit gracefully
    // print('EXAMPLE::Unsubscribing');
    // client.unsubscribe(topic);
    //
    // /// Wait for the unsubscribe message from the broker if you wish.
    // await MqttUtilities.asyncSleep(2);
    // print('EXAMPLE::Disconnecting');
    // client.disconnect();
    // print('EXAMPLE::Exiting normally');


    // FirebaseDatabase database = FirebaseDatabase.instance;
    // final ref = FirebaseDatabase.instance.ref();
    // final snapshot = await ref.child('devices/861123056637646').get();
    // if (snapshot.exists) {
    //   print(snapshot.value);
    // } else {
    //   print('No data available.');
    // }
    return;
  }

  void startTimer() {
    setState(() {
      iCountdown = Constants.INTERVAL_3_MIN_IN_SECOND;
    });

    const oneSec = const Duration(seconds: 1);
    Timer.periodic(
      oneSec,
          (Timer timer) {
        setState(() {
          if (iCountdown < 1) {
            timer.cancel();
          } else {
            iCountdown -= 1;
          }
        });
      },
    );
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    } else {
      print(
          'EXAMPLE::OnDisconnected callback is unsolicited or none, this is incorrect - exiting');
      // exit(-1);
      print('MQTT disconnect!!!');
      print('Then resubscribe....');
      // re subscribe mqtt
      // callMQTTSubscribe();
    }
    if (pongCount == 3) {
      print('EXAMPLE:: Pong count is correct');
    } else {
      print('EXAMPLE:: Pong count is incorrect, expected 3. actual $pongCount');
    }
  }

  /// The successful connect callback
  void onConnected() {
    print(
        'EXAMPLE::OnConnected client callback - Client connection was successful');
  }

  /// Pong callback
  void pong() {
    print('EXAMPLE::Ping response client callback invoked');
    pongCount++;
  }

  @override
  Widget build(BuildContext context) {
    var deviceHistoryRef = FirebaseDatabase.instance
        .ref()
        .child('users/${user!.userName}/devices/${device.uid}/${device.uid}_history')
        .orderByKey()
        .limitToLast(1);
    var deviceNotificationRef = FirebaseDatabase.instance
        .ref()
        .child('users/${user!.userName}/devices/${device.uid}/notification')
        .orderByKey();

    var deviceTankRef = FirebaseDatabase.instance
        .ref()
        .child('users/${user!.userName}/devices/${device.uid}/tank')
        .orderByKey();

    var operationUnitRef = FirebaseDatabase.instance
        .ref()
        .child('devices')
        .orderByKey();

    var operationTaskRef = FirebaseDatabase.instance
        .ref()
        .child('users/${user!.userName}/devices/${device.uid}/tasks')
        .orderByKey();


    // var deviceRef = FirebaseDatabase.instance.reference().child('users/${user.uid}/devices/${device.uid}/${device.uid}_history/2021-03-31 01:32:01');
    final TextStyle? unitStyle = Theme.of(context).textTheme.headline2;
    final TextStyle? headlineStyle = Theme.of(context).textTheme.headline1;

    return StreamBuilder(
        // stream: deviceDatabase.getLatestHistory().onValue,
        stream: deviceHistoryRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapHistory) {
          if (snapHistory.hasData && snapHistory.data!.snapshot.exists && !snapHistory.hasError) {
            // print('=>${snapHistory.data!.snapshot.value.toString()}');
            var weatherHistory = WeatherHistory(
              key: '',
              id: '',
              deviceId: '',
              humidity: 0,
              temperature: 0,
              weatherData: WeatherData(
                uid: '',
                deviceId: '',
                temperature: 0,
                humidity:  0,
                readVoltage:  0,

                wRangeDistance:  0,
                wFilledDepth:  0,
                wHeight: 0,
                wWidth: 0,
                wDiameter: 0,
                wSideLength: 0,
                wLength: 0,
                wCapacity: 0,
                wOffset: 0,
              ),
              readVoltage: 0,
            );

            if (snapHistory.data!.snapshot.value != null) {
              weatherHistory = WeatherHistory.fromJson(
                  snapHistory.data!.snapshot.value as Map);
            }

            // var weatherHistory = WeatherHistory.fromSnapshot(snap.data.snapshot);

            // Prepare value to draw live line chart
            while (tempPoints.length > limitCount) {
              tempPoints.removeAt(0);
              humidPoints.removeAt(0);
            }
            // used to be setState
            // print('xValue=${xValue}, weatherHistory.temperature=${weatherHistory.weatherData.temperature}|${globals.formatNumber(weatherHistory.weatherData.temperature) ?? ''}');
            // print('xValue=${xValue}, weatherHistory.humidity=${weatherHistory.weatherData.humidity}');
            mWeatherData = weatherHistory.weatherData;
            tempPoints.add(FlSpot(xValue, weatherHistory.weatherData.temperature));
            humidPoints.add(FlSpot(xValue, weatherHistory.weatherData.humidity));
            readDistancePoints.add(FlSpot(xValue, weatherHistory.weatherData.wRangeDistance / 10 ));
            dateTimeValues.add(weatherHistory.weatherData.uid);

            // print('tempPoints[tempPoints.length-1].x=${tempPoints[tempPoints.length - 1].x}');
            // print('tempPoints[tempPoints.length-1].y=${tempPoints[tempPoints.length - 1].y}');
            // print('tempPoints.length=${tempPoints.length}');
            xValue += step;

            return StreamBuilder(
                stream: deviceTankRef.onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapTank) {
                  if (snapTank.hasData && snapTank.data!.snapshot.exists && !snapTank.hasError) {
                    // print('snapTank.hasData=${snapTank.hasData}');
                    // print('=>${snapTank.data!.snapshot.value.toString()}');
                    if (snapTank.data!.snapshot.value != null) {
                      // print('snapTank.data!.snapshot.value is not null!!');
                      var tankStream = Tank.fromJson(
                          snapTank.data!.snapshot.value as Map);
                      // Stream Tank Data from cloud
                      _ShowDevicePageState.tank.wTankType = tankStream.wTankType;
                      _ShowDevicePageState.tank.wRangeDistance = tankStream.wRangeDistance;
                      _ShowDevicePageState.tank.wFilledDepth = tankStream.wFilledDepth;
                      _ShowDevicePageState.tank.wHeight = tankStream.wHeight;
                      _ShowDevicePageState.tank.wWidth = tankStream.wWidth;
                      _ShowDevicePageState.tank.wDiameter = tankStream.wDiameter;
                      _ShowDevicePageState.tank.wSideLength = tankStream.wSideLength;
                      _ShowDevicePageState.tank.wLength = tankStream.wLength;
                      _ShowDevicePageState.tank.wCapacity = tankStream.wCapacity;
                      _ShowDevicePageState.tank.wOffset = tankStream.wOffset;

                    } else {
                      print('snapTank.data!.snapshot.value is null!!');
                    }
                    // print('_ShowDevicePageState.tank.wTankType=${_ShowDevicePageState.tank.wTankType}');
                    // print('_ShowDevicePageState.tank.wRangeDistance=${_ShowDevicePageState.tank.wRangeDistance}');
                    // print('_ShowDevicePageState.tank.wFilledDepth=${_ShowDevicePageState.tank.wFilledDepth}');
                    // print('_ShowDevicePageState.tank.wHeight=${_ShowDevicePageState.tank.wHeight}');
                    // print('_ShowDevicePageState.tank.wWidth=${_ShowDevicePageState.tank.wWidth}');
                    // print('_ShowDevicePageState.tank.wDiameter=${_ShowDevicePageState.tank.wDiameter}');
                    // print('_ShowDevicePageState.tank.wSideLength=${_ShowDevicePageState.tank.wSideLength}');
                    // print('_ShowDevicePageState.tank.wLength=${_ShowDevicePageState.tank.wLength}');
                    // print('_ShowDevicePageState.tank.wCapacity=${_ShowDevicePageState.tank.wCapacity}');
                    // print('_ShowDevicePageState.tank.wOffset=${_ShowDevicePageState.tank.wOffset}');
                    //
                    // print('_ShowDevicePageState.tankDialog.wTankType=${tankDialog.wTankType}');
                    // print('_ShowDevicePageState.tankDialog.wRangeDistance=${tankDialog.wRangeDistance}');
                    // print('_ShowDevicePageState.tankDialog.wFilledDepth=${tankDialog.wFilledDepth}');
                    // print('_ShowDevicePageState.tankDialog.wHeight=${tankDialog.wHeight}');
                    // print('_ShowDevicePageState.tankDialog.wWidth=${tankDialog.wWidth}');
                    // print('_ShowDevicePageState.tankDialog.wDiameter=${tankDialog.wDiameter}');
                    // print('_ShowDevicePageState.tankDialog.wSideLength=${tankDialog.wSideLength}');
                    // print('_ShowDevicePageState.tankDialog.wLength=${tankDialog.wLength}');
                    // print('_ShowDevicePageState.tankDialog.wCapacity=${tankDialog.wCapacity}');
                    // print('_ShowDevicePageState.tankDialog.wOffset=${tankDialog.wOffset}');
                  }

                  return StreamBuilder(
                      stream: deviceNotificationRef.onValue,
                      builder:
                          (context,
                          AsyncSnapshot<DatabaseEvent> snapNotification) {
                            if (snapNotification.hasData &&
                                snapNotification.data!.snapshot.exists &&
                                !snapNotification.hasError) {
                                  // print(
                                  //     'snapNotification.hasData=${snapNotification
                                  //         .hasData}');
                                  // print(
                                  //     '=>${snapNotification.data!.snapshot.value
                                  //         .toString()}');
                                  if (snapNotification.data!.snapshot.value != null) {
                                    // print(
                                    //     'snapNotification.data!.snapshot.value is not null!!');
                                    var notificationStream = Notify.Notification
                                        .fromJson(
                                        snapNotification.data!.snapshot.value as Map);

                                    // Stream Notification Data from cloud
                                    this.notification.notifyEmail =
                                        notificationStream.notifyEmail;

                                    this.notification.notifyTOFDistanceHigher =
                                        notificationStream.notifyTOFDistanceHigher;
                                    this.notification.notifyTOFDistanceLower =
                                        notificationStream.notifyTOFDistanceLower;

                                    this.notification.notifyTempHigher =
                                        notificationStream.notifyTempHigher;
                                    this.notification.notifyTempLower =
                                        notificationStream.notifyTempLower;
                                    this.notification.notifyHumidHigher =
                                        notificationStream.notifyHumidHigher;
                                    this.notification.notifyHumidLower =
                                        notificationStream.notifyHumidLower;
                                    this.notification.isSendNotify =
                                        notificationStream.isSendNotify;
                                  } else {
                                    print(
                                        'snapNotification.data!.snapshot.value is null!!');
                                    }

                                    // print(
                                    //     'this.notification.isSendNotify=${this
                                    //         .notification.isSendNotify}');
                                    // print(
                                    //     'this.notification.notifyEmail=${this
                                    //         .notification.notifyEmail}');
                                    // print(
                                    //     'this.notification.notifyTempHigher=${this
                                    //         .notification.notifyTempHigher}');
                                    // print(
                                    //     'this.notification.notifyTempLower=${this
                                    //         .notification.notifyTempLower}');
                                    // print(
                                    //     'this.notification.notifyHumidHigher=${this
                                    //         .notification.notifyHumidHigher}');
                                    // print(
                                    //     'this.notification.notifyHumidLower=${this
                                    //         .notification.notifyHumidLower}');
                                    //
                                    // print(
                                    //     'this.notification.notifyTOFDistanceHigher=${this
                                    //         .notification.notifyTOFDistanceHigher}');
                                    // print(
                                    //     'this.notification.notifyTOFDistanceLower=${this
                                    //         .notification.notifyTOFDistanceLower}');
                            }

                            return StreamBuilder(
                                stream: operationTaskRef.onValue,
                                builder:
                                    (context,
                                    AsyncSnapshot<DatabaseEvent> snapOperationTasks) {
                                  if (snapOperationTasks.hasData &&
                                      snapOperationTasks.data!.snapshot.exists &&
                                      !snapOperationTasks.hasError) {
                                    // print(
                                    //     'snapOperationTasks.hasData=${snapOperationTasks
                                    //         .hasData}');
                                    // print(
                                    //     '=>${snapOperationTasks.data!.snapshot.value
                                    //         .toString()}');
                                    if (snapOperationTasks.data!.snapshot.value != null) {
                                      // print(
                                      //     'snapOperationTasks.data!.snapshot.value is not null!!');
                                      var taskStream = Task
                                          .fromJson(
                                          snapOperationTasks.data!.snapshot.value as Map);

                                      // Stream Task Data from cloud
                                      _ShowDevicePageState.task.uid = taskStream.uid;
                                      _ShowDevicePageState.task.operationDeviceId = taskStream.operationDeviceId;
                                      _ShowDevicePageState.task.operationMode = taskStream.operationMode;
                                      _ShowDevicePageState.task.operationPeriod = taskStream.operationPeriod;
                                      _ShowDevicePageState.task.command = taskStream.command;
                                      _ShowDevicePageState.task.readingInterval = taskStream.readingInterval;
                                      _ShowDevicePageState.task.updatedWhen = taskStream.updatedWhen;
                                      _ShowDevicePageState.task.expectedWhen = taskStream.expectedWhen;
                                    } else {
                                      print('snapOperationTasks.data!.snapshot.value is null!!');

                                      _ShowDevicePageState.task.operationMode = Constants.MODE_AUTO;
                                      _ShowDevicePageState.task.operationPeriod = Constants.INTERVAL_MINUTE_30;
                                      _ShowDevicePageState.task.command = Constants.SWITCH_OFF;

                                    }

                                    // print('_ShowDevicePageState.task.uid=${_ShowDevicePageState.task.uid}');
                                    // print('_ShowDevicePageState.task.operationDeviceId=${_ShowDevicePageState.task.operationDeviceId}');
                                    // print('_ShowDevicePageState.task.operationMode=${_ShowDevicePageState.task.operationMode}');
                                    // print('_ShowDevicePageState.task.operationPeriod=${_ShowDevicePageState.task.operationPeriod}');
                                    // print('_ShowDevicePageState.task.command=${_ShowDevicePageState.task.command}');
                                    // print('_ShowDevicePageState.task.readingInterval=${_ShowDevicePageState.task.readingInterval}');
                                    // print('_ShowDevicePageState.task.updatedWhen=${_ShowDevicePageState.task.updatedWhen}');
                                    // print('_ShowDevicePageState.task.expectedWhen=${_ShowDevicePageState.task.expectedWhen}');

                                  } else {
                                    print('snapOperationTasks.data!.snapshot.value is null!!');
                                    _ShowDevicePageState.task.operationMode = Constants.MODE_AUTO;
                                    _ShowDevicePageState.task.operationPeriod = Constants.INTERVAL_MINUTE_30;
                                    _ShowDevicePageState.task.command = Constants.SWITCH_OFF;
                                  }

                              return StreamBuilder(
                                  stream: operationUnitRef.onValue,
                                  builder: (context, AsyncSnapshot<DatabaseEvent> snapOperationUnit) {
                                    if (snapOperationUnit.hasData && snapOperationUnit.data!.snapshot.exists && !snapOperationUnit.hasError) {
                                      if (snapOperationUnit.data!.snapshot.value != null) {
                                        // print('snapOperationUnit.data!.snapshot.value is not null!!');

                                        operationUnitLists.clear();
                                        sensorOperationUnitLists.clear();
                                        Map<dynamic, dynamic> values = snapOperationUnit.data!.snapshot.value as Map;

                                        values.forEach((key, values) {
                                          // print('key=${key}');
                                          // print('uid=[${values['uid']}]');
                                          // print('status=[${values['status']}]');
                                          // print('updatedWhen=[${values['updatedWhen']}]');
                                          // print('user=[${values['user']}]');
                                          // print('sensor=[${values['sensor']}]');

                                          var sensorVar = values['sensor'] ?? '';

                                          // Operation Unit List for input dialog
                                          operationUnitLists.add(OperationUnit(
                                            id: values['id'] ?? '',
                                            uid: values['uid'] ?? '',
                                            index: int.parse('${values['index'] ?? "0"}'),
                                            name: values['name'] ?? '',
                                            status: values['status'] ?? '',
                                            user: values['user'] ?? '',
                                            sensor: values['sensor'] ?? '',
                                            updatedWhen: values['updatedWhen'] ?? '2022-11-11 11:11:11',

                                          ));

                                          if(sensorVar != '' && sensorVar == widget.device.uid) {
                                            if(isInitiatedPage) {
                                              if(mSensorOperationUnit.status != values['status']) {
                                                iCountdown = 0;
                                              }
                                            }

                                            sensorOperationUnitLists.add(OperationUnit(
                                              id: values['id'] ?? '',
                                              uid: values['uid'] ?? '',
                                              index: int.parse('${values['index'] ?? "0"}'),
                                              name: values['name'] ?? '',
                                              status: values['status'] ?? 'wait',
                                              user: values['user'] ?? '',
                                              sensor: values['sensor'] ?? '',
                                              updatedWhen: values['updatedWhen'] ?? '2022-11-11 11:11:11',

                                            ));
                                          }
                                        });

                                      } else {
                                        print('snapOperationUnit.data!.snapshot.value is null!!');
                                      }

                                      if(sensorOperationUnitLists.length > 0) {
                                        // setState (() {
                                        mSensorOperationUnit = sensorOperationUnitLists[0];

                                        verifyPumpDeviceTimeOver();
                                      }
                                    }

                                    // Start Draw UI
                                    mPercentage = calculateFilledPercentage(mSelectedTankType, weatherHistory);

                                    return Scaffold(
                                      appBar: AppBar(
                                        title: Text(
                                            '${device.name ?? device.uid} Detail'),
                                      ),
                                      body: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            // ####  Top of the page  ####
                                            // SizedBox(
                                            //   height: 12,
                                            // ),
                                            // TempAndHumidCircularWidget(weatherHistory: weatherHistory, headlineStyle: headlineStyle, unitStyle: unitStyle),
                                            SizedBox(
                                              height: 8,
                                            ),

                                            Container(
                                              // color: Colors.black26,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  // Top Picture row
                                                  Container(
                                                    // color: Colors.deepOrange[100],
                                                    child: Row(
                                                      // mainAxisSize: MainAxisSize.min,
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      // crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets.all(8.0),
                                                          padding: EdgeInsets.all(8.0),
                                                          decoration:BoxDecoration(
                                                            borderRadius:BorderRadius.circular(8),
                                                            // color:Colors.green
                                                          ),
                                                          // child: Text("Tank",style: TextStyle(color:Colors.yellowAccent,fontSize:25),),
                                                          child: GestureDetector(
                                                            onTap: () async {
                                                              final deviceReturn =
                                                              await showTankConfigurationDialog();
                                                              if (deviceReturn == null) return;

                                                              setState(() {
                                                                this.tankDialog.wHeight =
                                                                    deviceReturn.wHeight;
                                                                this.tankDialog.wWidth =
                                                                    deviceReturn.wWidth;
                                                                this.tankDialog.wDiameter =
                                                                    deviceReturn.wDiameter;
                                                                this.tankDialog.wSideLength =
                                                                    deviceReturn.wSideLength;
                                                                this.tankDialog.wLength =
                                                                    deviceReturn.wLength;
                                                                this.tankDialog.wOffset =
                                                                    deviceReturn.wOffset;
                                                                // this.notification.isSendNotify = deviceReturn.isSendNotify;
                                                              });
                                                            },
                                                            child: Container(
                                                              // width: 180,
                                                              width: displayWidth(context) * 0.5,
                                                              height: displayWidth(context) * 0.25,
                                                              child: Card(
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(15.0),
                                                                ),
                                                                color: Colors.white,
                                                                child: Padding(
                                                                  padding: const EdgeInsets.only(top: 0.0, left: 4.0),
                                                                  child: Row(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                    // mainAxisSize: MainAxisSize.max,
                                                                    children: [
                                                                      Padding(
                                                                        padding: const EdgeInsets.only(top: 4.0, right: 6.0),
                                                                        child: Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                          mainAxisSize: MainAxisSize.min,
                                                                          children: [
                                                                            Container(
                                                                              // color: Colors.brown,
                                                                              width: displayWidth(context) * 0.3,
                                                                              child: Image(
                                                                                image: AssetImage(
                                                                                  // 'images/tanks/base_vertical_cylinder.jpg'),
                                                                                  // Constants.gTankImagesMap[mSelectedTankType]!),
                                                                                    getFilledTankPercentageImage(mSelectedTankType)),
                                                                              ),
                                                                            ),
                                                                            // Text('${(widget.operationUnit.name != '') ? widget.operationUnit.name : widget.operationUnit.uid}',
                                                                            //   style: nameStyle,
                                                                            // ),
                                                                            // Text('${globals.getTimeCard(widget.operationUnit.updatedWhen)}',
                                                                            //   style: subtitleStyle,
                                                                            // ),
                                                                            // Text('${globals.getDateCard(widget.operationUnit.updatedWhen)}',
                                                                            //   style: subtitleStyle,
                                                                            // ),
                                                                          ],
                                                                        ),
                                                                      ),

                                                                      Expanded(
                                                                        child: Container(
                                                                          // color: Colors.black,
                                                                          decoration: BoxDecoration(
                                                                            borderRadius: BorderRadius.only(
                                                                              topRight: Radius.circular(10.0),
                                                                              bottomRight: Radius.circular(10.0),
                                                                            ),
                                                                            color: const Color(0xff187a7d),
                                                                            // border: Border.all(
                                                                            //     width: 1.0, color: const Color(0xff707070)),
                                                                          ),
                                                                          child: Column(
                                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                            mainAxisSize: MainAxisSize.max,
                                                                            children: [
                                                                              Text('${globals.formatNumber(weatherHistory.weatherData.wRangeDistance / 10)}cm', style: TextStyle(fontSize: 2 * (displayHeight(context) * 0.01), color: Colors.white, fontFamily: 'Kanit', fontWeight: FontWeight.w400), textAlign: TextAlign.center,),
                                                                              Divider(
                                                                                color: const Color(0xffe30707), //.withOpacity(0.2),
                                                                                thickness: 1,
                                                                                // width: 10,
                                                                                height: 1,
                                                                                indent: 2,
                                                                                endIndent: 2,
                                                                              ),
                                                                              Text('${calculateFilledDepth(mSelectedTankType, weatherHistory)}cm', style: TextStyle(fontSize: 2 * (displayHeight(context) * 0.01), color: Colors.white, fontFamily: 'Kanit', fontWeight: FontWeight.w400), textAlign: TextAlign.center,),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          margin: EdgeInsets.all(15.0),
                                                          padding: EdgeInsets.all(8.0),
                                                          decoration:BoxDecoration(
                                                            borderRadius:BorderRadius.circular(8),
                                                            // color:Colors.green
                                                          ),
                                                          // child: Text("Pump",style: TextStyle(color:Colors.yellowAccent,fontSize:25),),
                                                          child: Bounce(
                                                            duration: Duration(milliseconds: 100),
                                                            onPressed: () async {

                                                              final operationUnitReturn =
                                                              await showOperationUnitInputDialog();
                                                              if (operationUnitReturn == null) return;

                                                              // setState(() {
                                                              //   this.notification.notifyTempLower =
                                                              //       operationUnitReturn.notifyTempLower;
                                                              //   this.notification.notifyTempHigher =
                                                              //       operationUnitReturn.notifyTempHigher;
                                                              //   this.notification.notifyHumidLower =
                                                              //       operationUnitReturn.notifyHumidLower;
                                                              //   this.notification
                                                              //       .notifyHumidHigher =
                                                              //       operationUnitReturn.notifyHumidHigher;
                                                              //   this.notification.notifyEmail =
                                                              //       operationUnitReturn.notifyEmail;
                                                              //
                                                              //   this.notification.notifyTOFDistanceLower =
                                                              //       operationUnitReturn.notifyTOFDistanceLower;
                                                              //   this.notification.notifyTOFDistanceHigher =
                                                              //       operationUnitReturn.notifyTOFDistanceHigher;
                                                              //   // this.notification.isSendNotify = deviceReturn.isSendNotify;
                                                              // });
                                                            },
                                                            child: drawPumpRelayStatusImage(),
                                                          ),
                                                        ),
                                                        // Expanded(
                                                        //   child: Container(
                                                        //     color: Colors.brown,
                                                        //     child: Text(
                                                        //       'none A.',
                                                        //       style: TextStyle(fontSize: 14, color: Colors.black45),
                                                        //     ),
                                                        //   ),
                                                        // ),
                                                        // Expanded(
                                                        //   child: Container(
                                                        //     color: Colors.lightGreenAccent[100],
                                                        //     child: Text(
                                                        //       'none B',
                                                        //       style: TextStyle(fontSize: 14, color: Colors.black45),
                                                        //     ),
                                                        //   ),
                                                        // ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Description row
                                                  Container(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        // Tank description column
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Container(
                                                              width: displayWidth(context) * 0.4,
                                                              // color: Colors.blueGrey,
                                                              color: updateConsoleStatusBgColor(Constants.CONSOLE_TYPE_DISTANCE_SENSOR, weatherHistory?.weatherData?.uid ?? 'no data'),
                                                              child: Center(
                                                                child: Text(
                                                                  updateConsoleStatus(Constants.CONSOLE_TYPE_DISTANCE_SENSOR, weatherHistory?.weatherData?.uid ?? 'no data'),
                                                                  style: TextStyle(fontSize: 14, color: Colors.white70,),
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              'When:',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),
                                                            Text(
                                                              '${weatherHistory?.weatherData?.uid ?? 'no data'}',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            ),
                                                            Text(
                                                              'Full:',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),
                                                            Text(
                                                              '${globals.formatNumber(mPercentage)}%',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            ),
                                                            Text(
                                                              'Tank Volumes:',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),
                                                            Text(
                                                              '${calculateTankVolume(mSelectedTankType)} Liters',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            ),
                                                            Text(
                                                              'Height (h):',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),
                                                            Text(
                                                              '${globals.formatNumber(device.wHeight)}cm',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            ),
                                                            Text(
                                                              'Mac Address:',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),
                                                            Text(
                                                              '${device.uid}',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            ),
                                                          ],
                                                        ),

                                                        // Pump description column
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,

                                                          children: [
                                                            Container(
                                                              width: displayWidth(context) * 0.4,
                                                              // color: Colors.blueGrey,
                                                              color: updateConsoleStatusBgColor(Constants.CONSOLE_TYPE_PUMP_RELAY, mSensorOperationUnit?.updatedWhen ?? 'no data'),
                                                              child: Center(
                                                                child: Text(
                                                                  updateConsoleStatus(Constants.CONSOLE_TYPE_PUMP_RELAY, mSensorOperationUnit?.updatedWhen ?? 'no data'),
                                                                  style: TextStyle(fontSize: 14, color: Colors.white70,),
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              'When:',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),
                                                            Text(
                                                              //'${operationUnitLists.length > 0 ? (operationUnitLists[0].updatedWhen ?? 'no data') : 'no data'}',
                                                              '${mSensorOperationUnit?.updatedWhen ?? 'no data'}',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            ),
                                                            Text(
                                                              'IMEI:',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),
                                                            Text(
                                                              '${mSensorOperationUnit.uid}',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            ),
                                                            SizedBox(height: 20,),

                                                            Bounce(
                                                              duration: Duration(milliseconds: 100),
                                                              onPressed: () async {
                                                                print('on press mode');

                                                                final deviceReturn =
                                                                    await showOperationModeInputDialog();
                                                                if (deviceReturn == null) return;

                                                                setState(() {
                                                                  if(device.mode == Constants.MODE_AUTO) {
                                                                    device.mode = Constants.MODE_MANUAL;
                                                                  } else {
                                                                    device.mode = Constants.MODE_AUTO;
                                                                  }
                                                                });
                                                              },
                                                              child: Container(
                                                                // margin: EdgeInsets.all(8.0),
                                                                padding: EdgeInsets.all(8.0),
                                                                decoration: BoxDecoration(

                                                                  border: Border.all(

                                                                      color: Colors.deepOrange,
                                                                      width: 3.0
                                                                  ),
                                                                  borderRadius: BorderRadius.all(
                                                                      Radius.circular(5.0) //                 <--- border radius here
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  getOperationModeText(task.operationMode),
                                                                  style: TextStyle(
                                                                      fontSize: 20,
                                                                      backgroundColor: Color(0xF5F5DC),
                                                                      color: Colors.deepPurple,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),

                                                            Text(
                                                              'Latest Command:',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),
                                                            Text(
                                                              '${task.command}',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            ),
                                                            Text(
                                                              'Period:',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),
                                                            Text(
                                                              '${getOperationPeriodInString(task.operationPeriod)}',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            ),
                                                            Text(
                                                              'Ordered When:',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),
                                                            Text(
                                                              '${task.updatedWhen}',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            ),
                                                            Text(
                                                              'Expected End:',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),
                                                            Text(
                                                              '${task.expectedWhen}',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            ),

                                                            Text(
                                                              'Command will active in(sec): $iCountdown',
                                                              style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w300),
                                                            ),

                                                            // ValueListenableBuilder<bool>(
                                                            //   valueListenable: isOrderSubmitted,
                                                            //   builder: (context, value, child) {
                                                            //     Future.delayed(Duration(seconds: 5), () {
                                                            //       // This code will execute after 5 seconds
                                                            //       print('<<<Task executed!: isOrderSubmitted=${isOrderSubmitted.value} value=$value>>>');
                                                            //     });
                                                            //     return Text(
                                                            //       'Variable value: $value',
                                                            //       style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w600),
                                                            //     );
                                                            //   },
                                                            // ),

                                                            // SizedBox(height: 20,),


                                                          //   Bounce(
                                                          //     duration: Duration(milliseconds: 100),
                                                          //     onPressed: () {
                                                          //       print('on press mode');
                                                          //       setState(() {
                                                          //         if(device.mode == Constants.MODE_AUTO) {
                                                          //           device.mode = Constants.MODE_MANUAL;
                                                          //         } else {
                                                          //           device.mode = Constants.MODE_AUTO;
                                                          //         }
                                                          //       });
                                                          //     },
                                                          //     child: Container(
                                                          //     decoration: BoxDecoration(
                                                          //
                                                          //       border: Border.all(
                                                          //         color: Colors.deepOrange,
                                                          //         width: 3.0
                                                          //       ),
                                                          //       borderRadius: BorderRadius.all(
                                                          //           Radius.circular(5.0) //                 <--- border radius here
                                                          //       ),
                                                          //     ),
                                                          //     child: TextButton(
                                                          //       style: TextButton.styleFrom(
                                                          //         textStyle: TextStyle(
                                                          //           fontSize: 20,
                                                          //
                                                          //         ),
                                                          //
                                                          //         backgroundColor: Color(0xF5F5DC),
                                                          //         foregroundColor: Colors.deepPurple,
                                                          //       ),
                                                          //       onPressed: () {
                                                          //         setState(() {
                                                          //           if(device.mode == Constants.MODE_AUTO) {
                                                          //             device.mode = Constants.MODE_MANUAL;
                                                          //           } else {
                                                          //             device.mode = Constants.MODE_AUTO;
                                                          //           }
                                                          //         });
                                                          //
                                                          //       },
                                                          //       child: Text(getOperationModeText(device.mode)),
                                                          //     ),
                                                          //   ),
                                                          // ),

                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // buildCustomPicker(),
                                                ],
                                              ),
                                            ),

                                            // Old tank detail part
                                            // GestureDetector(
                                            //   onTap: () async {
                                            //     final deviceReturn =
                                            //     await openTankConfigurationDialog();
                                            //     if (deviceReturn == null) return;
                                            //
                                            //     setState(() {
                                            //       this.tankDialog.wHeight =
                                            //           deviceReturn.wHeight;
                                            //       this.tankDialog.wWidth =
                                            //           deviceReturn.wWidth;
                                            //       this.tankDialog.wDiameter =
                                            //           deviceReturn.wDiameter;
                                            //       this.tankDialog.wSideLength =
                                            //           deviceReturn.wSideLength;
                                            //       this.tankDialog.wLength =
                                            //           deviceReturn.wLength;
                                            //       this.tankDialog.wOffset =
                                            //           deviceReturn.wOffset;
                                            //       // this.notification.isSendNotify = deviceReturn.isSendNotify;
                                            //     });
                                            //   },
                                            //   child: Column(
                                            //     mainAxisAlignment: MainAxisAlignment
                                            //         .center,
                                            //     crossAxisAlignment: CrossAxisAlignment
                                            //         .center,
                                            //     // mainAxisSize: MainAxisSize.max,
                                            //     children: [
                                            //       Container(child: Text('${globals.formatNumber(mPercentage)}% Full')),
                                            //       Row(
                                            //         mainAxisSize: MainAxisSize.min,
                                            //         mainAxisAlignment:
                                            //         MainAxisAlignment.spaceAround,
                                            //         crossAxisAlignment: CrossAxisAlignment
                                            //             .center,
                                            //         children: [
                                            //           Container(
                                            //             width: displayWidth(context) *
                                            //                 0.3,
                                            //             child: Image(
                                            //               image: AssetImage(
                                            //                 // 'images/tanks/base_vertical_cylinder.jpg'),
                                            //                 // Constants.gTankImagesMap[mSelectedTankType]!),
                                            //                   getFilledTankPercentageImage(mSelectedTankType)),
                                            //             ),
                                            //           ),
                                            //           Container(
                                            //               child: Column(
                                            //                 mainAxisSize: MainAxisSize
                                            //                     .min,
                                            //                 mainAxisAlignment:
                                            //                 MainAxisAlignment.spaceAround,
                                            //                 crossAxisAlignment:
                                            //                 CrossAxisAlignment.center,
                                            //                 children: [
                                            //                   Row(
                                            //                     mainAxisSize: MainAxisSize
                                            //                         .min,
                                            //                     mainAxisAlignment:
                                            //                     MainAxisAlignment
                                            //                         .spaceAround,
                                            //                     crossAxisAlignment:
                                            //                     CrossAxisAlignment.center,
                                            //                     children: [
                                            //                       Container(
                                            //                           child: Text(
                                            //                               'Tank Volumes:')),
                                            //                       Container(
                                            //                           child: Text(
                                            //                               '${calculateTankVolume(mSelectedTankType)} Liters')),
                                            //                     ],
                                            //                   ),
                                            //                   Row(
                                            //                     mainAxisSize: MainAxisSize
                                            //                         .min,
                                            //                     mainAxisAlignment:
                                            //                     MainAxisAlignment
                                            //                         .spaceAround,
                                            //                     crossAxisAlignment:
                                            //                     CrossAxisAlignment.center,
                                            //                     children: [
                                            //                       Container(
                                            //                           child:
                                            //                           Text(
                                            //                               'Range Distance:')),
                                            //                       Container(child: Text(
                                            //                           '${globals.formatNumber(weatherHistory.weatherData.wRangeDistance / 10)}cm')),
                                            //                     ],
                                            //                   ),
                                            //                   Row(
                                            //                     mainAxisSize: MainAxisSize
                                            //                         .min,
                                            //                     mainAxisAlignment:
                                            //                     MainAxisAlignment
                                            //                         .spaceAround,
                                            //                     crossAxisAlignment:
                                            //                     CrossAxisAlignment.center,
                                            //                     children: [
                                            //                       Container(
                                            //                           child:
                                            //                           Text(
                                            //                               'Filled Depth(f):')),
                                            //                       Container(child: Text(
                                            //                           '${calculateFilledDepth(mSelectedTankType, weatherHistory)}cm')),
                                            //                     ],
                                            //                   ),
                                            //                   buildTankTypeDimensionFormDisplayOnly(mSelectedTankType),
                                            //
                                            //                   Row(
                                            //                     mainAxisSize: MainAxisSize
                                            //                         .min,
                                            //                     mainAxisAlignment:
                                            //                     MainAxisAlignment
                                            //                         .spaceAround,
                                            //                     crossAxisAlignment:
                                            //                     CrossAxisAlignment.center,
                                            //                     children: [
                                            //                       Container(
                                            //                           child:
                                            //                           Text(
                                            //                               'Offset(o):')),
                                            //                       Container(child: Text(
                                            //                           '${globals.formatNumber(device.wOffset)}cm')),
                                            //                     ],
                                            //                   ),
                                            //                   // buildTankTypeDimensionColumn(
                                            //                   //     device.wTankType),
                                            //                 ],
                                            //               )),
                                            //         ],
                                            //       ),
                                            //     ],
                                            //   ),
                                            // ),

                                            // Old operation unit button part
                                            // Operation Unit
                                            // Column(
                                            //   children: [
                                            //     SizedBox(
                                            //       height: 8,
                                            //     ),
                                            //     TextButton(
                                            //       child: Text('Operation Unit'),
                                            //       style: TextButton.styleFrom(
                                            //         primary: Colors.black54,
                                            //         backgroundColor: Colors.white70,
                                            //         onSurface: Colors.grey,
                                            //         textStyle: TextStyle(
                                            //           color: Colors.black54,
                                            //           fontSize: 16,
                                            //           fontStyle: FontStyle.normal,
                                            //           fontWeight: FontWeight.w600,
                                            //         ),
                                            //         shadowColor: Colors.limeAccent,
                                            //         elevation: 5,
                                            //       ),
                                            //
                                            //       onPressed: () async {
                                            //
                                            //         final operationUnitReturn =
                                            //         await openOperationUnitInputDialog();
                                            //         if (operationUnitReturn == null) return;
                                            //
                                            //         // setState(() {
                                            //         //   this.notification.notifyTempLower =
                                            //         //       operationUnitReturn.notifyTempLower;
                                            //         //   this.notification.notifyTempHigher =
                                            //         //       operationUnitReturn.notifyTempHigher;
                                            //         //   this.notification.notifyHumidLower =
                                            //         //       operationUnitReturn.notifyHumidLower;
                                            //         //   this.notification
                                            //         //       .notifyHumidHigher =
                                            //         //       operationUnitReturn.notifyHumidHigher;
                                            //         //   this.notification.notifyEmail =
                                            //         //       operationUnitReturn.notifyEmail;
                                            //         //
                                            //         //   this.notification.notifyTOFDistanceLower =
                                            //         //       operationUnitReturn.notifyTOFDistanceLower;
                                            //         //   this.notification.notifyTOFDistanceHigher =
                                            //         //       operationUnitReturn.notifyTOFDistanceHigher;
                                            //         //   // this.notification.isSendNotify = deviceReturn.isSendNotify;
                                            //         // });
                                            //       },
                                            //     ),
                                            //     SizedBox(
                                            //       height: 8,
                                            //     ),
                                            //   ],
                                            // ),

                                            // Old Operation Unit detail display
                                            // drawOperationUnitDetail(),

                                            SizedBox(
                                              height: 16,
                                            ),

                                            // Operated chart
                                            OperatedLineChartWidget(operationDeviceId: task.operationDeviceId,),

                                            SizedBox(
                                              height: 16,
                                            ),

                                            // Read distance chart
                                            drawReadDistanceLineChart(),

                                            SizedBox(
                                              height: 16,
                                            ),

                                            // Old temp & humidity chart
                                            drawTempHumidLineChart(),

                                            //Old temp & humidity description
                                            buildDeviceDescription(weatherHistory),

                                            // Old water level sensor reading interval
                                            buildReadingIntervalCard(context),
                                            SizedBox(
                                              height: 8,
                                            ),
                                            // draw line chart

                                            // Old notification settings part
                                            // Notification setting
                                            Column(
                                              children: [
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                TextButton(
                                                  child: Text('Notification'),
                                                  style: TextButton.styleFrom(
                                                    primary: Colors.black54,
                                                    backgroundColor: Colors.white70,
                                                    onSurface: Colors.grey,
                                                    textStyle: TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 16,
                                                      fontStyle: FontStyle.normal,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    shadowColor: Colors.limeAccent,
                                                    elevation: 5,
                                                  ),

                                                  onPressed: () async {

                                                    final deviceReturn =
                                                    await showNotificationInputDialog();
                                                    if (deviceReturn == null) return;

                                                    setState(() {
                                                      this.notification.notifyTempLower =
                                                          deviceReturn.notifyTempLower;
                                                      this.notification.notifyTempHigher =
                                                          deviceReturn.notifyTempHigher;
                                                      this.notification.notifyHumidLower =
                                                          deviceReturn.notifyHumidLower;
                                                      this.notification
                                                          .notifyHumidHigher =
                                                          deviceReturn.notifyHumidHigher;
                                                      this.notification.notifyEmail =
                                                          deviceReturn.notifyEmail;

                                                      this.notification.notifyTOFDistanceLower =
                                                          deviceReturn.notifyTOFDistanceLower;
                                                      this.notification.notifyTOFDistanceHigher =
                                                          deviceReturn.notifyTOFDistanceHigher;
                                                      // this.notification.isSendNotify = deviceReturn.isSendNotify;
                                                    });
                                                  },
                                                ),
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                // Notification display
                                                drawNotificationDetail(),
                                              ],
                                            ),

                                            SizedBox(
                                              height: 8,
                                            ),

                                            // Old delete sensor node part
                                            TextButton(
                                              child: Text('Delete History'),
                                              style: TextButton.styleFrom(

                                                primary: Colors.black54,
                                                backgroundColor: Colors.white70,
                                                onSurface: Colors.grey,
                                                textStyle: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 16,
                                                  fontStyle: FontStyle.normal,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                shadowColor: Colors.limeAccent,
                                                elevation: 5,
                                              ),

                                              onPressed: () async {
                                                final deleteHistoryDialogReturn =
                                                await showDeleteHistoryConfirmDialog();
                                                if (deleteHistoryDialogReturn == null) return;

                                              },
                                            ),

                                            SizedBox(
                                              height: 16,
                                            ),

                                            // Old delete sensor node part
                                            TextButton(
                                              child: Text('Delete theSensor Node'),
                                              style: TextButton.styleFrom(
                                                primary: Colors.black54,
                                                backgroundColor: Colors.white70,
                                                onSurface: Colors.grey,
                                                textStyle: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 16,
                                                  fontStyle: FontStyle.normal,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                shadowColor: Colors.limeAccent,
                                                elevation: 5,
                                              ),

                                              onPressed: () async {
                                                final deleteNodeDialogReturn =
                                                await showDeleteDeviceNodeConfirmDialog();
                                                if (deleteNodeDialogReturn == null) return;

                                              },
                                            ),

                                            SizedBox(
                                              height: 16,
                                            ),
                                            Text('MQTT Client: ${g_platform_mac_address}'),
                                            // Row(
                                            //   children: [
                                            //     Expanded(
                                            //         child: Text(
                                            //           'Name: ',
                                            //           style: TextStyle(fontWeight: FontWeight.w600),
                                            //         ),
                                            //     ),
                                            //     const SizedBox(width: 12,),
                                            //     Text(device.notifyEmail),
                                            //   ],
                                            // )
                                          ],
                                        ),
                                      ),
                                );
                                  });
                          }); // operationTaskRef
                      });
                });
          } else {
            return Scaffold(
                appBar: AppBar(
                  title: Text('${device.name ?? device.uid} Detail'),
                ),
                body: Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.amberAccent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                    strokeWidth: 3,
                  ),
                ));
          }
        });
  }

  String getDimensionValueDisplayOnly(String dimensionType) {
    String result = '';
    switch(dimensionType) {
      case Constants.DIMENSION_TYPE_OFFSET: {
        result = !_ShowDevicePageState.tank.wOffset!.isNaN ? f.format(_ShowDevicePageState.tank.wOffset!).toString() : '';
        break;
      }

      case Constants.DIMENSION_TYPE_CAPACITY: {
        result = !_ShowDevicePageState.tank.wCapacity!.isNaN ? f.format(_ShowDevicePageState.tank.wCapacity!).toString() : '';
        break;
      }
      case Constants.DIMENSION_TYPE_LENGTH: {
        result = !_ShowDevicePageState.tank.wLength!.isNaN ? f.format(_ShowDevicePageState.tank.wLength!).toString() : '';
        break;
      }
      case Constants.DIMENSION_TYPE_DIAMETER: {
        result = !_ShowDevicePageState.tank.wDiameter!.isNaN ? f.format(_ShowDevicePageState.tank.wDiameter!).toString() : '';
        break;
      }
      case Constants.DIMENSION_TYPE_HEIGHT: {
        result = !_ShowDevicePageState.tank.wHeight!.isNaN ? f.format(_ShowDevicePageState.tank.wHeight!).toString() : '';
        break;
      }
      case Constants.DIMENSION_TYPE_WIDTH: {
        result = !_ShowDevicePageState.tank.wWidth!.isNaN ? f.format(_ShowDevicePageState.tank.wWidth!).toString() : '';
        break;
      }
      case Constants.DIMENSION_TYPE_SIDE_LENGTH: {
        result = !_ShowDevicePageState.tank.wSideLength!.isNaN ? f.format(_ShowDevicePageState.tank.wSideLength!).toString() : '';
        break;
      }
      default: {
        result = '';
      }
    }
    print('getDimensionValueDisplayOnly[${dimensionType}] _ShowDevicePageState.tank.wLength![${_ShowDevicePageState.tank.wLength!}] result=${result} ');
    return result;
  }

  Widget buildTankTypeDimensionFormDisplayOnly(String tankType) {
    List<Widget> list = <Widget>[];
    if (tankType == '') {
      tankType = Constants.TANK_TYPE_VERTICAL_CYLINDER;
    }

    Constants.gTankTypesMap[tankType]!.forEach((dimensionTypeName, symbol) {
      list.add(SizedBox(
        height: displayHeight(context) * 0.03, // MediaQuery.of(context).size.height / 2,

        child: Container(child: Row(

          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            Text('$dimensionTypeName: ', style: TextStyle(color: Colors.black87),),
            Text(getDimensionValueDisplayOnly(dimensionTypeName), style: TextStyle(color: Colors.black87),),
            // Text('_ ', style: TextStyle(color: Colors.black87),),
            // Container(
            //   width: 100,
            //   height: 40,
            //   child: Form(
            //     key: _TankDimensionConfigState.getDimensionKey(dimensionTypeName),
            //     child: TextFormField(
            //       textAlign: TextAlign.center,
            //       style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.normal, ),
            //       initialValue: getDimensionValueDisplayOnly(dimensionTypeName),
            //       keyboardType: TextInputType.number,
            //       validator: (value) {
            //         if (value == null || value.isEmpty) {
            //           // return 'Please enter a ${dimensionTypeName} tank dimension number.';
            //           return 'Re-edit here';
            //         } else {
            //           // if (!isNumeric(value!)) {
            //           //   return 'Invalid ${dimensionTypeName} tank dimension number';
            //           // }
            //           // setState(() {
            //           //   // setDimensionValue(dimensionTypeName, value);
            //           //   print('*** ${dimensionTypeName} value=${value}');
            //           // });
            //
            //           return null;
            //         }
            //       },
            //       // controller: TextEditingController(text: this.notificationDialog.notifyEmail),
            //       autofocus: false,
            //       // decoration: InputDecoration(
            //       //   label: Text(
            //       //     'Email:',
            //       //     style: TextStyle(fontSize: 16, color: Colors.black45),
            //       //   ),
            //       //   // labelText: Text('Email:'),
            //       //   hintText: 'Enter your email address',
            //       // ),
            //       // controller: name_controller,
            //       onChanged: (value) {
            //         setState(() {
            //           setDimensionValueDisplayOnly(dimensionTypeName, value);
            //           print('+++ ${dimensionTypeName} value=${value}');
            //         });
            //       },
            //       // onSubmitted: (_) => submitNotificationSettings(),
            //     ),
            //   ),
            // ),
            Text('${symbol}', style: TextStyle(color: Colors.black87),),
          ],
        )),
      ));
    });
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: list,
    );
  }

  void setDimensionValueDisplayOnly(String dimensionType, String value) {
    switch(dimensionType) {
      case Constants.DIMENSION_TYPE_OFFSET: {
        widget.device.wOffset = double.parse(value);
        tankDialog.wOffset = double.parse(value);

        print('>> widget.device.wOffset=${widget.device.wOffset}');
        print('>> _ShowDevicePageState.tankDialog.wOffset=${tankDialog.wOffset}');
        break;
      }

      case Constants.DIMENSION_TYPE_CAPACITY: {
        widget.device.wCapacity = double.parse(value);
        tankDialog.wCapacity = double.parse(value);

        print('>> widget.device.wCapacity=${widget.device.wCapacity}');
        print('>> _ShowDevicePageState.tankDialog.wCapacity=${tankDialog.wCapacity}');
        break;
      }
      case Constants.DIMENSION_TYPE_LENGTH: {
        widget.device.wLength = double.parse(value);
        tankDialog.wLength = double.parse(value);

        print('>> widget.device.wLength=${widget.device.wLength}');
        print('>> _ShowDevicePageState.tankDialog.wLength=${tankDialog.wLength}');
        break;
      }
      case Constants.DIMENSION_TYPE_DIAMETER: {
        widget.device.wDiameter = double.parse(value);
        tankDialog.wDiameter = double.parse(value);
        print('>> widget.device.wDiameter=${widget.device.wDiameter}');
        print('>> _ShowDevicePageState.tank.wDiameter=${tankDialog.wDiameter}');
        break;
      }
      case Constants.DIMENSION_TYPE_HEIGHT: {
        widget.device.wHeight = double.parse(value);
        tankDialog.wHeight = double.parse(value);
        print('>> widget.device.wHeight=${widget.device.wHeight}');
        print('>> _ShowDevicePageState.tank.wHeight=${tankDialog.wHeight}');
        break;
      }
      case Constants.DIMENSION_TYPE_WIDTH: {
        widget.device.wWidth = double.parse(value);
        tankDialog.wWidth = double.parse(value);
        print('>> widget.device.wWidth=${widget.device.wWidth}');
        print('>> _ShowDevicePageState.tank.wWidth=${tankDialog.wWidth}');
        break;
      }
      case Constants.DIMENSION_TYPE_SIDE_LENGTH: {
        widget.device.wSideLength = double.parse(value);
        tankDialog.wSideLength = double.parse(value);
        print('>> widget.device.wSideLength=${widget.device.wSideLength}');
        print('>> _ShowDevicePageState.tank.wSideLength=${tankDialog.wSideLength}');
        break;
      }
      default: {
        break;
      }
    }
  }

  List<Widget> buildTankTypesConfiguration() {
    List<Widget> results = [];
    Constants.gTankTypesMap!.forEach((name, symbol) {
      results.add(Container(
          width: displayWidth(context) * 0.8,
          child: Card(
            color: Colors.black12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: displayWidth(context) * 0.2,
                    child: Image(
                      image: AssetImage(
                          Constants.gTankImagesMap[name]!),
                          // 'images/tanks/base_vertical_cylinder.jpg'),
                    ),
                  ),
                  Text('$name'),
                ],
              ))

      )
      );
    });
    return results;
  }

  Widget buildTankTypeDimensionColumn(String tankType) {
    List<Widget> list = <Widget>[];
    if (tankType == '') {
      tankType = Constants.TANK_TYPE_VERTICAL_CYLINDER;
    }

    Constants.gTankTypesMap[tankType]!.forEach((name, symbol) {
      list.add(Container(child: Text('${name}: 200${symbol}')));
    });
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: list,
    );
  }



  Column buildDeviceDescription(WeatherHistory weatherHistory) {
    return Column(
      children: [
        // Center(
        //   child: Container(
        //     child: Row(
        //       mainAxisSize: MainAxisSize.min,
        //       mainAxisAlignment: MainAxisAlignment.end,
        //       crossAxisAlignment: CrossAxisAlignment.center,
        //       children: [
        //         Text('Device ', style: TextStyle( fontSize: 14, color: Colors.black45),),
        //         Text('${device.name ?? device.uid}', style: TextStyle( fontSize: 14, color: Colors.black87),),
        //         Text(' Detail', style: TextStyle( fontSize: 14, color: Colors.black45),),
        //       ],
        //     ),
        //   ),
        // ),
        Center(
          child: Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'latest when ',
                  style: TextStyle(fontSize: 14, color: Colors.black45),
                ),
                Text(
                  '${weatherHistory?.weatherData?.uid ?? 'no data'}',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
        // Center(
        //   child: Container(
        //     // child: Text('battery voltage ${weatherHistory?.weatherData?.readVoltage.toStringAsFixed(weatherHistory?.weatherData?.readVoltage.truncateToDouble() == weatherHistory?.weatherData?.readVoltage ? 0 : 2) ?? 'no data'} volts'),
        //     // child: Text('battery voltage ${globals.formatNumber(weatherHistory?.weatherData?.readVoltage) ?? 'no data'} volts'),
        //     child: Row(
        //       mainAxisSize: MainAxisSize.min,
        //       mainAxisAlignment: MainAxisAlignment.end,
        //       crossAxisAlignment: CrossAxisAlignment.center,
        //       children: [
        //         Text(
        //           'battery voltage ',
        //           style: TextStyle(fontSize: 14, color: Colors.black45),
        //         ),
        //         Text(
        //           '${weatherHistory?.weatherData?.readVoltage ?? 'no data'}',
        //           style: TextStyle(fontSize: 14, color: Colors.black87),
        //         ),
        //         Text(
        //           ' volts',
        //           style: TextStyle(fontSize: 14, color: Colors.black45),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ],
    );
  }

  LineChartBarData tempLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      gradient: LinearGradient(
          colors: [tempColor.withOpacity(0), tempColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.1, 1.0]),
      barWidth: 4,
      isCurved: false,
      // isStrokeCapRound: true,
    );
  }

  LineChartBarData humidLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      gradient: LinearGradient(
          colors: [humidColor.withOpacity(0), humidColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.1, 1.0]),
      barWidth: 4,
      isCurved: false,
    );
  }

  LineChartBarData readDistanceLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      gradient: LinearGradient(
          colors: [readDistanceColor.withOpacity(0), readDistanceColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.1, 1.0]),
      barWidth: 4,
      isCurved: false,
    );
  }

  Card buildWorkingModeCard(BuildContext context) {
    return Card(
      child: Row(
        children: [
          Expanded(
            child: Container(
              child: Column(
                children: [
                  IconButton(
                    color: burstePressed ? Colors.lightGreen : Colors.grey,
                    icon: const Icon(Icons.autorenew),
                    tooltip:
                        'Continue read sensor value every short time period',
                    onPressed: () {
                      setState(() {
                        burstePressed = !burstePressed;
                        requestPressed = false;
                        pollingPressed = false;
                        offlinePressed = false;
                      });
                    },
                  ),
                  Text(
                    'Burst',
                    style: burstePressed
                        ? Theme.of(context).textTheme.subtitle2
                        : Theme.of(context).textTheme.subtitle1,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              child: Column(
                children: [
                  IconButton(
                    color: requestPressed ? Colors.lightGreen : Colors.grey,
                    icon: const Icon(Icons.wifi_calling),
                    tooltip: 'Read sensor by request',
                    onPressed: () {
                      setState(() {
                        burstePressed = false;
                        requestPressed = !requestPressed;
                        pollingPressed = false;
                        offlinePressed = false;
                      });
                    },
                  ),
                  Text(
                    'Request',
                    style: requestPressed
                        ? Theme.of(context).textTheme.subtitle2
                        : Theme.of(context).textTheme.subtitle1,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              child: Column(
                children: [
                  IconButton(
                    color: pollingPressed ? Colors.lightGreen : Colors.grey,
                    icon: const Icon(Icons.battery_alert),
                    tooltip:
                        'Read sensor value every long time period to safe battery life time',
                    onPressed: () {
                      setState(() {
                        burstePressed = false;
                        requestPressed = false;
                        pollingPressed = !pollingPressed;
                        offlinePressed = false;
                      });
                    },
                  ),
                  Text(
                    'Polling',
                    style: pollingPressed
                        ? Theme.of(context).textTheme.subtitle2
                        : Theme.of(context).textTheme.subtitle1,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              child: Column(
                children: [
                  IconButton(
                    color: offlinePressed ? Colors.lightGreen : Colors.grey,
                    icon: const Icon(Icons.wifi_off),
                    tooltip:
                        'Save read sensor value in "the Node" local memory',
                    onPressed: () {
                      setState(() {
                        burstePressed = false;
                        requestPressed = false;
                        pollingPressed = false;
                        offlinePressed = !offlinePressed;
                      });
                    },
                  ),
                  Text(
                    'Offline',
                    style: offlinePressed
                        ? Theme.of(context).textTheme.subtitle2
                        : Theme.of(context).textTheme.subtitle1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Card buildReadingIntervalCard(BuildContext context) {
    // draw card
    final TextStyle? inactiveStyle = Theme.of(context).textTheme.headline5;
    final TextStyle? activeStyle = Theme.of(context).textTheme.headline6;
    return Card(
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = !sec10Pressed;
                  sec30Pressed = false;
                  min1Pressed = false;
                  min2Pressed = false;
                  min3Pressed = false;
                  min4Pressed = false;
                  min5Pressed = false;
                  min30Pressed = false;
                  hour1Pressed = false;
                  hour2Pressed = false;
                  hour3Pressed = false;
                  hour4Pressed = false;

                  selectedInterval = 10000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '10',
                      style: sec10Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'sec',
                      style: sec10Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = false;
                  sec30Pressed = !sec30Pressed;
                  min1Pressed = false;
                  min2Pressed = false;
                  min3Pressed = false;
                  min4Pressed = false;
                  min5Pressed = false;
                  min30Pressed = false;
                  hour1Pressed = false;
                  hour2Pressed = false;
                  hour3Pressed = false;
                  hour4Pressed = false;

                  selectedInterval = 30000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '30',
                      style: sec30Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'sec',
                      style: sec30Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = false;
                  sec30Pressed = false;
                  min1Pressed = !min1Pressed;
                  min2Pressed = false;
                  min3Pressed = false;
                  min4Pressed = false;
                  min5Pressed = false;
                  min30Pressed = false;
                  hour1Pressed = false;
                  hour2Pressed = false;
                  hour3Pressed = false;
                  hour4Pressed = false;

                  selectedInterval = 60000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '1',
                      style: min1Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'min',
                      style: min1Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = false;
                  sec30Pressed = false;
                  min1Pressed = false;
                  min2Pressed = !min2Pressed;
                  min3Pressed = false;
                  min4Pressed = false;
                  min5Pressed = false;
                  min30Pressed = false;
                  hour1Pressed = false;
                  hour2Pressed = false;
                  hour3Pressed = false;
                  hour4Pressed = false;

                  selectedInterval = 120000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '2',
                      style: min2Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'min',
                      style: min2Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = false;
                  sec30Pressed = false;
                  min1Pressed = false;
                  min2Pressed = false;
                  min3Pressed = !min3Pressed;
                  min4Pressed = false;
                  min5Pressed = false;
                  min30Pressed = false;
                  hour1Pressed = false;
                  hour2Pressed = false;
                  hour3Pressed = false;
                  hour4Pressed = false;

                  selectedInterval = 180000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '3',
                      style: min3Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'min',
                      style: min3Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = false;
                  sec30Pressed = false;
                  min1Pressed = false;
                  min2Pressed = false;
                  min3Pressed = false;
                  min4Pressed = !min4Pressed;
                  min5Pressed = false;
                  min30Pressed = false;
                  hour1Pressed = false;
                  hour2Pressed = false;
                  hour3Pressed = false;
                  hour4Pressed = false;

                  selectedInterval = 240000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '4',
                      style: min4Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'min',
                      style: min4Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = false;
                  sec30Pressed = false;
                  min1Pressed = false;
                  min2Pressed = false;
                  min3Pressed = false;
                  min4Pressed = false;
                  min5Pressed = !min5Pressed;
                  min30Pressed = false;
                  hour1Pressed = false;
                  hour2Pressed = false;
                  hour3Pressed = false;
                  hour4Pressed = false;

                  selectedInterval = 300000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '5',
                      style: min5Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'min',
                      style: min5Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = false;
                  sec30Pressed = false;
                  min1Pressed = false;
                  min2Pressed = false;
                  min3Pressed = false;
                  min4Pressed = false;
                  min5Pressed = false;
                  min30Pressed = !min30Pressed;
                  hour1Pressed = false;
                  hour2Pressed = false;
                  hour3Pressed = false;
                  hour4Pressed = false;

                  selectedInterval = 1800000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '30',
                      style: min30Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'min',
                      style: min30Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = false;
                  sec30Pressed = false;
                  min1Pressed = false;
                  min2Pressed = false;
                  min3Pressed = false;
                  min4Pressed = false;
                  min5Pressed = false;
                  min30Pressed = false;
                  hour1Pressed = !hour1Pressed;
                  hour2Pressed = false;
                  hour3Pressed = false;
                  hour4Pressed = false;

                  selectedInterval = 3600000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '1',
                      style: hour1Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'hour',
                      style: hour1Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = false;
                  sec30Pressed = false;
                  min1Pressed = false;
                  min2Pressed = false;
                  min3Pressed = false;
                  min4Pressed = false;
                  min5Pressed = false;
                  min30Pressed = false;
                  hour1Pressed = false;
                  hour2Pressed = !hour2Pressed;
                  hour3Pressed = false;
                  hour4Pressed = false;

                  selectedInterval = 7200000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '2',
                      style: hour2Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'hour',
                      style: hour2Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = false;
                  sec30Pressed = false;
                  min1Pressed = false;
                  min2Pressed = false;
                  min3Pressed = false;
                  min4Pressed = false;
                  min5Pressed = false;
                  min30Pressed = false;
                  hour1Pressed = false;
                  hour2Pressed = false;
                  hour3Pressed = !hour3Pressed;
                  hour4Pressed = false;

                  selectedInterval = 10800000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '3',
                      style: hour3Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'hour',
                      style: hour3Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  sec10Pressed = false;
                  sec30Pressed = false;
                  min1Pressed = false;
                  min2Pressed = false;
                  min3Pressed = false;
                  min4Pressed = false;
                  min5Pressed = false;
                  min30Pressed = false;
                  hour1Pressed = false;
                  hour2Pressed = false;
                  hour3Pressed = false;
                  hour4Pressed = !hour4Pressed;

                  selectedInterval = 14400000;
                  updateReadingInterval();
                });
              },
              child: Container(
                child: Column(
                  children: [
                    Text(
                      '4',
                      style: hour4Pressed ? activeStyle : inactiveStyle,
                    ),
                    Text(
                      'hour',
                      style: hour4Pressed
                          ? Theme.of(context).textTheme.subtitle2
                          : Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /**
   * First contact to "the Node" to pass reading interval value
   */
  // Future<http.Response> updateReadingInterval() async {
  Future<void> updateReadingInterval() async {
    // update reading interval in cloud database
    // deviceDatabase.updateDevice(device);
    print(
        'update reading interval in cloud database - users/${user!.userName}/devices/${device.uid}');
    var deviceRef = FirebaseDatabase.instance
        .ref()
        .child('users/${user!.userName}/devices/${device.uid}')
        .update({
          // 'name':  device.name,
          'readingInterval': selectedInterval,
        })
        .onError((error, stackTrace) =>
            print('updateNotificationSettings error=${error.toString()}'))
        .whenComplete(() {
          print('updated notification settings success.');
          showDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                    title: Text("Update Successfully"),
                    content: Text(
                        "Update reading interval settings is successfully."),
                    actions: [
                      CupertinoDialogAction(
                        child: Text("OK"),
                        onPressed: () {
                          // Navigator.pop(context);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
              barrierDismissible: false);
        });

  }

  Future<void> updateTankDimensionSettingSubTank() async {
    print(
        'update tank dimension settings in cloud database - users/${user!.userName}/devices/${device.uid}/tank');
    var deviceTankRef = FirebaseDatabase.instance
        .ref()
        .child('users/${user!.userName}/devices/${device.uid}/tank')
        .update({
      // 'name':  device.name,
      'wTankType': (mSelectedTankType == '')
          ? ''
          : mSelectedTankType,
      'wHeight': (tankDialog.wHeight == 0)
          ? _ShowDevicePageState.tank.wHeight
          : tankDialog.wHeight,
      'wWidth': (tankDialog.wWidth == 0)
          ? _ShowDevicePageState.tank.wWidth
          : tankDialog.wWidth,
      'wDiameter': (tankDialog.wDiameter == 0)
          ? _ShowDevicePageState.tank.wDiameter
          : tankDialog.wDiameter,
      'wSideLength': (tankDialog.wSideLength == 0)
          ? _ShowDevicePageState.tank.wSideLength
          : tankDialog.wSideLength,
      'wLength': (tankDialog.wLength == 0)
          ? _ShowDevicePageState.tank.wLength
          : tankDialog.wLength,
      'wCapacity': (tankDialog.wCapacity == 0)
          ? _ShowDevicePageState.tank.wCapacity
          : tankDialog.wCapacity,
      'wFilledDepth': (tankDialog.wFilledDepth == 0)
          ? _ShowDevicePageState.tank.wFilledDepth
          : tankDialog.wFilledDepth,
      'wOffset': (tankDialog.wOffset == 0)
          ? _ShowDevicePageState.tank.wOffset
          : tankDialog.wOffset,
    })
        .onError((error, stackTrace) {
      print('updateTankDimensionSettings error=${error.toString()}');
      showDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text("Update Error"),
            content:
            Text("Update tank dimension settings is failed."),
            actions: [
              CupertinoDialogAction(
                child: Text("OK"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          barrierDismissible: false
      );
    }
    )
        .whenComplete(() {
      print('updated tank dimension settings success.');
      showDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text("Update Successfully"),
            content:
            Text("Update tank dimension settings is successfully."),
            actions: [
              CupertinoDialogAction(
                child: Text("OK"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pop();
                  // setState(() {
                  //   device.wTankType =
                  // });
                },
              ),
            ],
          ),
          barrierDismissible: false
      );
    }
    );
  }

  /**
   * "the Node" to save tank dimension values
   */
  Future<void> updateTankDimensionSettings() async {
    // update tank dimension settings in cloud database
    print(
        'update tank dimension settings in cloud database - users/${user!.userName}/devices/${device.uid}');

    print('>>>>_ShowDevicePageState.tank.wLength=${_ShowDevicePageState.tank.wLength}');
    print('>>>>_ShowDevicePageState.tankDialog.wLength=${tankDialog.wLength}');
    var deviceRef = FirebaseDatabase.instance
        .ref()
        .child('users/${user!.userName}/devices/${device.uid}')
        .update({
      // 'name':  device.name,
      'wTankType': (mSelectedTankType == '')
          ? ''
          : mSelectedTankType,
      'wHeight': (tankDialog.wHeight == 0)
          ? _ShowDevicePageState.tank.wHeight
          : tankDialog.wHeight,
      'wWidth': (tankDialog.wWidth == 0)
          ? _ShowDevicePageState.tank.wWidth
          : tankDialog.wWidth,
      'wDiameter': (tankDialog.wDiameter == 0)
          ? _ShowDevicePageState.tank.wDiameter
          : tankDialog.wDiameter,
      'wSideLength': (tankDialog.wSideLength == 0)
          ? _ShowDevicePageState.tank.wSideLength
          : tankDialog.wSideLength,
      'wLength': (tankDialog.wLength == 0)
          ? _ShowDevicePageState.tank.wLength
          : tankDialog.wLength,
      'wCapacity': (tankDialog.wCapacity == 0)
          ? _ShowDevicePageState.tank.wCapacity
          : tankDialog.wCapacity,
      'wFilledDepth': (tankDialog.wFilledDepth == 0)
          ? _ShowDevicePageState.tank.wFilledDepth
          : tankDialog.wFilledDepth,
      'wOffset': (tankDialog.wOffset == 0)
          ? _ShowDevicePageState.tank.wOffset
          : tankDialog.wOffset,
    })
        .onError((error, stackTrace) {
            print('updateTankDimensionSettings error=${error.toString()}');
            showDialog(
                context: context,
                builder: (_) => CupertinoAlertDialog(
                  title: Text("Update Error"),
                  content:
                  Text("Update tank dimension settings is failed."),
                  actions: [
                    CupertinoDialogAction(
                      child: Text("OK"),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                barrierDismissible: false
            );
          }
        )
        .whenComplete(() {
          print('updated tank dimension settings at device root success.');
          updateTankDimensionSettingSubTank();
          // showDialog(
          //     context: context,
          //     builder: (_) => CupertinoAlertDialog(
          //       title: Text("Update Successfully"),
          //       content:
          //       Text("Update tank dimension settings is successfully."),
          //       actions: [
          //         CupertinoDialogAction(
          //           child: Text("OK"),
          //           onPressed: () {
          //             Navigator.pop(context);
          //             Navigator.of(context).pop();
          //           },
          //         ),
          //       ],
          //     ),
          //     barrierDismissible: false
          // );
        }
        );
    return;
  }

  /**
   * "the Node" to save notification values
   */
  Future<void> updateNotificationSettings() async {
    // update notification settings in cloud database
    print(
        'update notification settings in cloud database - users/${user!.userName}/devices/${device.uid}/notification');
    var deviceRef = FirebaseDatabase.instance
        .ref()
        .child('users/${user!.userName}/devices/${device.uid}/notification')
        .update({
          // 'name':  device.name,
          'notifyHumidLower': (this.notificationDialog.notifyHumidLower == 0)
              ? this.notification.notifyHumidLower
              : this.notificationDialog.notifyHumidLower,
          'notifyHumidHigher': (this.notificationDialog.notifyHumidHigher == 0)
              ? this.notification.notifyHumidHigher
              : this.notificationDialog.notifyHumidHigher,
          'notifyTempLower': (this.notificationDialog.notifyTempLower == 0)
              ? this.notification.notifyTempLower
              : this.notificationDialog.notifyTempLower,
          'notifyTempHigher': (this.notificationDialog.notifyTempHigher == 0)
              ? this.notification.notifyTempHigher
              : this.notificationDialog.notifyTempHigher,

          'notifyTOFDistanceLower': (this.notificationDialog.notifyTOFDistanceLower == 0)
              ? this.notification.notifyTOFDistanceLower
              : this.notificationDialog.notifyTOFDistanceLower,
          'notifyTOFDistanceHigher': (this.notificationDialog.notifyTOFDistanceHigher == 0)
              ? this.notification.notifyTOFDistanceHigher
              : this.notificationDialog.notifyTOFDistanceHigher,

          'notifyEmail': this.notificationDialog.notifyEmail,
          // 'isSendNotify': this.notification.isSendNotify,
          'isSendNotify': true,
        })
        .onError((error, stackTrace) =>
            print('updateNotificationSettings error=${error.toString()}'))
        .whenComplete(() {
          print('updated notification settings success.');
          showDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                    title: Text("Update Successfully"),
                    content:
                        Text("Update notification settings is successfully."),
                    actions: [
                      CupertinoDialogAction(
                        child: Text("OK"),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
              barrierDismissible: false);
        });

    return;
  }

  /*
    Delete unused user device node in the cloud database
   */
  Future<void> deleteUserDeviceHistory() async {
    print('In deleteUserDevice history, delete unused history in the cloud database.');

    var deviceRef = FirebaseDatabase.instance.ref();

    if(user!.userName!.isNotEmpty && user!.userName != '') {
      String path = 'users/${user!.userName}/devices/${device.uid}/${device.uid}_history';
      deviceRef.child('${path}')
          .remove()
          .onError((error, stackTrace) =>
          print('deleteUserDevice history error=${error.toString()}'))
          .whenComplete(() {
        print('deleteUserDevice history path[${path}] success.');
        showDialog(
            context: context,
            builder: (_) =>
                CupertinoAlertDialog(
                  title: Text("Deleted Successfully"),
                  content:
                  Text("Delete device path[${path}] is successfully."),
                  actions: [
                    CupertinoDialogAction(
                      child: Text("OK"),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).pop();

                        // Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
                      },
                    ),
                  ],
                ),
            barrierDismissible: false);
      });
    }

    return;
  }

  /*
    Delete unused user device node in the cloud database
   */
  Future<void> deleteUserDeviceNode() async {
    print('In deleteUserDeviceNode, delete unused user device node in the cloud database.');

    var deviceRef = FirebaseDatabase.instance.ref();

    if(user!.userName!.isNotEmpty && user!.userName != '') {
      String path = 'users/${user!.userName}/devices/${device.uid}';
      deviceRef.child('${path}')
          .remove()
          .onError((error, stackTrace) =>
          print('deleteUserDeviceNode error=${error.toString()}'))
          .whenComplete(() {
            print('deleteUserDeviceNode path[${path}] success.');
            showDialog(
                context: context,
                builder: (_) =>
                    CupertinoAlertDialog(
                      title: Text("Deleted Successfully"),
                      content:
                      Text("Delete device path[${path}] is successfully."),
                      actions: [
                        CupertinoDialogAction(
                          child: Text("OK"),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context).pop();

                            Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
                          },
                        ),
                      ],
                    ),
                barrierDismissible: false);
          });
    }

    return;
  }

  /**
   * "the Node" to update device sensor that pair to the pump/relay.
   */
  Future<void> updateSensorParing(List<OperationUnit> batchUpdatedLists) async {
    // update notification settings in cloud database
    print(
        'update sensor paring list in the cloud database...');

    var deviceRef = FirebaseDatabase.instance.ref();
    Map<String, Object> values = {};
    batchUpdatedLists.forEach((element) {
      // Set the value of 'sensor' paring
      // var updateSensorRef = FirebaseFirestore.instance.collection("devices").doc(element.uid);
      if(element.user == '' || element.user == user!.userName) {
        String path = "devices/" + element.uid;
        values[path] = {
          'uid': element.uid,
          'name': element.name,
          'status': element.status,
          'user': user!.userName,
          'sensor': element.sensor,
          'updatedWhen': element.updatedWhen,
        };
      }
    });
    deviceRef.update(values)
        .onError((error, stackTrace) =>
        print('updateSensorParing error=${error.toString()}'))
        .whenComplete(() {
      print('updated sensor paring success.');
      showDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: Text("Update Successfully"),
            content:
            Text("Update sensor paring is successfully."),
            actions: [
              CupertinoDialogAction(
                child: Text("OK"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          barrierDismissible: false);
    });

    // // Get a new write batch
    // final batch = FirebaseFirestore.instance.batch();
    //
    // batchUpdatedLists.forEach((element) {
    //   // Set the value of 'sensor' paring
    //   var updateSensorRef = FirebaseFirestore.instance.collection("devices").doc(element.uid);
    //   batch.set(updateSensorRef, {"sensor": element.sensor});
    // });
    //
    // // Commit the batch
    // batch.commit()
    //   .onError((error, stackTrace) =>
    //   print('updateSensorParing error=${error.toString()}'))
    //   .whenComplete(() {
    //     print('updated sensor paring success.');
    //     showDialog(
    //         context: context,
    //         builder: (_) => CupertinoAlertDialog(
    //           title: Text("Update Successfully"),
    //           content:
    //           Text("Update sensor paring is successfully."),
    //           actions: [
    //             CupertinoDialogAction(
    //               child: Text("OK"),
    //               onPressed: () {
    //                 Navigator.pop(context);
    //                 Navigator.of(context).pop();
    //               },
    //             ),
    //           ],
    //         ),
    //         barrierDismissible: false);
    //   });

    return;
  }

  Future<List<WeatherData>> getLast10Histories() async {
    final onceHistoriesSnapshot = await FirebaseDatabase.instance
        .ref()
        .child('users/${user!.userName}/devices/${device.uid}/${device.uid}_history')
        .orderByKey()
        .limitToLast(10)
        .get();

    // print(onceHistoriesSnapshot); // to debug and see if data is returned

    List<WeatherData> histories = [];

    if (onceHistoriesSnapshot.exists) {
      histories.clear();
      tempPoints.clear();
      humidPoints.clear();
      readDistancePoints.clear();
      dateTimeValues.clear();

      // print(onceHistoriesSnapshot.value);
      Map<dynamic, dynamic>? values = onceHistoriesSnapshot.value as Map?;

      values!.forEach((key, weatherValues) {
        // print('key=${key}');
        // print('temperature=[${weatherValues['temperature']}]');

        tempPoints.add(FlSpot(
            xValue, globals.parseDouble(weatherValues['temperature'] ?? 0)));
        humidPoints.add(FlSpot(
            xValue, globals.parseDouble(weatherValues['humidity'] ?? 0)));
        readDistancePoints.add(FlSpot(
            xValue, globals.parseDouble(weatherValues['wRangeDistance'] ?? 0) / 10));
        dateTimeValues.add(weatherValues['uid'] ?? '');

        xValue += step;

        histories.add(WeatherData(
          uid: weatherValues['uid'] ?? '',
          deviceId: weatherValues['deviceId'] ?? '',
          humidity: globals.parseDouble(weatherValues['humidity'] ?? 0),
          temperature: globals.parseDouble(weatherValues['temperature'] ?? 0),
          readVoltage: globals.parseDouble(weatherValues['readVoltage'] ?? 0),
          // add TOF10120(Water level) sensor data xxz
          wRangeDistance: globals.parseDouble(weatherValues['wRangeDistance'] ?? 0),

          // No data
          wFilledDepth: globals.parseDouble(weatherValues['wFilledDepth'] ?? 0),
          wCapacity: globals.parseDouble(weatherValues['wCapacity'] ?? 0),
          wOffset: globals.parseDouble(weatherValues['wOffset'] ?? 0),
          wHeight: globals.parseDouble(weatherValues['temperature'] ?? 0),
          wWidth: globals.parseDouble(weatherValues['temperature'] ?? 0),
          wDiameter: globals.parseDouble(weatherValues['temperature'] ?? 0),
          wSideLength: globals.parseDouble(weatherValues['temperature'] ?? 0),
          wLength: globals.parseDouble(weatherValues['temperature'] ?? 0),

        ));
      });

      tempPoints.sort((a, b) => a.x.compareTo(b.x));
      humidPoints.sort((a, b) => a.x.compareTo(b.x));
      readDistancePoints.sort((a, b) => a.x.compareTo(b.x));
      dateTimeValues.sort((a, b) => a.compareTo(b));
    } else {
      histories.clear();
      tempPoints.add(FlSpot(xValue, 0));
      humidPoints.add(FlSpot(xValue, 0));
      readDistancePoints.add(FlSpot(xValue, 0));
      dateTimeValues.add('_');
      print('No data available.');

      tempPoints.add(FlSpot(
          xValue, globals.parseDouble(0)));
      humidPoints.add(FlSpot(
          xValue, globals.parseDouble(0)));
      readDistancePoints.add(FlSpot(
          xValue, globals.parseDouble(0)));
      dateTimeValues.add('');

      xValue += step;

      histories.add(WeatherData(
        uid: '',
        deviceId: '',
        humidity: globals.parseDouble(0),
        temperature: globals.parseDouble(0),
        readVoltage: globals.parseDouble(0),
        // add TOF10120(Water level) sensor data xxz
        wRangeDistance: globals.parseDouble(0),

        // no data
        wFilledDepth: globals.parseDouble(0),
        wCapacity: globals.parseDouble(0),
        wOffset: globals.parseDouble(0),
        wHeight: globals.parseDouble(0),
        wWidth: globals.parseDouble(0),
        wDiameter: globals.parseDouble(0),
        wSideLength: globals.parseDouble(0),
        wLength: globals.parseDouble(0),

      ));
    }

    return histories;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    getLast10Histories();
    switch (device.readingInterval) {
      case Constants.INTERVAL_SECOND_10:
        {
          setState(() {
            sec10Pressed = true;
            sec30Pressed = false;
            min1Pressed = false;
            min2Pressed = false;
            min3Pressed = false;
            min4Pressed = false;
            min5Pressed = false;
            min30Pressed = false;
            hour1Pressed = false;
            hour2Pressed = false;
            hour3Pressed = false;
            hour4Pressed = false;
          });
        }
        break;

      case Constants.INTERVAL_SECOND_30:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = true;
            min1Pressed = false;
            min2Pressed = false;
            min3Pressed = false;
            min4Pressed = false;
            min5Pressed = false;
            min30Pressed = false;
            hour1Pressed = false;
            hour2Pressed = false;
            hour3Pressed = false;
            hour4Pressed = false;
          });
        }
        break;

      case Constants.INTERVAL_MINUTE_1:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = false;
            min1Pressed = true;
            min2Pressed = false;
            min3Pressed = false;
            min4Pressed = false;
            min5Pressed = false;
            min30Pressed = false;
            hour1Pressed = false;
            hour2Pressed = false;
            hour3Pressed = false;
            hour4Pressed = false;
          });
        }
        break;

      case Constants.INTERVAL_MINUTE_2:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = false;
            min1Pressed = false;
            min2Pressed = true;
            min3Pressed = false;
            min4Pressed = false;
            min5Pressed = false;
            min30Pressed = false;
            hour1Pressed = false;
            hour2Pressed = false;
            hour3Pressed = false;
            hour4Pressed = false;
          });
        }
        break;

      case Constants.INTERVAL_MINUTE_3:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = false;
            min1Pressed = false;
            min2Pressed = false;
            min3Pressed = true;
            min4Pressed = false;
            min5Pressed = false;
            min30Pressed = false;
            hour1Pressed = false;
            hour2Pressed = false;
            hour3Pressed = false;
            hour4Pressed = false;
          });
        }
        break;

      case Constants.INTERVAL_MINUTE_4:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = false;
            min1Pressed = false;
            min2Pressed = false;
            min3Pressed = false;
            min4Pressed = true;
            min5Pressed = false;
            min30Pressed = false;
            hour1Pressed = false;
            hour2Pressed = false;
            hour3Pressed = false;
            hour4Pressed = false;
          });
        }
        break;

      case Constants.INTERVAL_MINUTE_5:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = false;
            min1Pressed = false;
            min2Pressed = false;
            min3Pressed = false;
            min4Pressed = false;
            min5Pressed = true;
            min30Pressed = false;
            hour1Pressed = false;
            hour2Pressed = false;
            hour3Pressed = false;
            hour4Pressed = false;
          });
        }
        break;

      case Constants.INTERVAL_MINUTE_30:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = false;
            min1Pressed = false;
            min2Pressed = false;
            min3Pressed = false;
            min4Pressed = false;
            min5Pressed = false;
            min30Pressed = true;
            hour1Pressed = false;
            hour2Pressed = false;
            hour3Pressed = false;
            hour4Pressed = false;
          });
        }
        break;

      case Constants.INTERVAL_HOUR_1:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = false;
            min1Pressed = false;
            min2Pressed = false;
            min3Pressed = false;
            min4Pressed = false;
            min5Pressed = false;
            min30Pressed = false;
            hour1Pressed = true;
            hour2Pressed = false;
            hour3Pressed = false;
            hour4Pressed = false;
          });
        }
        break;

      case Constants.INTERVAL_HOUR_2:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = false;
            min1Pressed = false;
            min2Pressed = false;
            min3Pressed = false;
            min4Pressed = false;
            min5Pressed = false;
            min30Pressed = false;
            hour1Pressed = false;
            hour2Pressed = true;
            hour3Pressed = false;
            hour4Pressed = false;
          });
        }
        break;

      case Constants.INTERVAL_HOUR_3:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = false;
            min1Pressed = false;
            min2Pressed = false;
            min3Pressed = false;
            min4Pressed = false;
            min5Pressed = false;
            min30Pressed = false;
            hour1Pressed = false;
            hour2Pressed = false;
            hour3Pressed = true;
            hour4Pressed = false;
          });
        }
        break;

      case Constants.INTERVAL_HOUR_4:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = false;
            min1Pressed = false;
            min2Pressed = false;
            min3Pressed = false;
            min4Pressed = false;
            min5Pressed = false;
            min30Pressed = false;
            hour1Pressed = false;
            hour2Pressed = false;
            hour3Pressed = false;
            hour4Pressed = true;
          });
        }
        break;

      default:
        {
          setState(() {
            sec10Pressed = false;
            sec30Pressed = true;
            min1Pressed = false;
            min2Pressed = false;
            min3Pressed = false;
            min4Pressed = false;
            min5Pressed = false;
            min30Pressed = false;
            hour1Pressed = false;
            hour2Pressed = false;
            hour3Pressed = false;
            hour4Pressed = false;
          });
        }
        break;
    }
    // switch(device.mode) {
    //   case Constants.MODE_BURST: {
    //     burstePressed = true;
    //     requestPressed = false;
    //     pollingPressed = false;
    //     offlinePressed = false;
    //   }
    //   break;
    //
    //   case Constants.MODE_REQUEST: {
    //     burstePressed = false;
    //     requestPressed = true;
    //     pollingPressed = false;
    //     offlinePressed = false;
    //   }
    //   break;
    //
    //   case Constants.MODE_POLLING: {
    //     burstePressed = false;
    //     requestPressed = false;
    //     pollingPressed = true;
    //     offlinePressed = false;
    //   }
    //   break;
    //
    //   case Constants.MODE_OFFLINE: {
    //     burstePressed = false;
    //     requestPressed = false;
    //     pollingPressed = false;
    //     offlinePressed = true;
    //   }
    //   break;
    //
    //   default: {
    //     burstePressed = false;
    //     requestPressed = false;
    //     pollingPressed = false;
    //     offlinePressed = false;
    //   }
    //   break;
    //
    // }
  }

  bool verifyDimensionValue(String tankType) {
    bool result = false;
    switch (tankType) {
      case Constants.TANK_TYPE_RECTANGLE:
      case Constants.TANK_TYPE_HORIZONTAL_OVAL:
      case Constants.TANK_TYPE_VERTICAL_OVAL:
      case Constants.TANK_TYPE_HORIZONTAL_ELLIPSE:
        {
          if (_lengthFormKey.currentState!.validate() &&
              _heightFormKey.currentState!.validate() &&
              _widthFormKey.currentState!.validate()) {
            result = true;
          }
          break;
        }
      case Constants.TANK_TYPE_VERTICAL_CYLINDER:
        {
          if (_heightFormKey.currentState!.validate() &&
              _diameterFormKey.currentState!.validate()) {
            result = true;
          }
          break;
        }
      case Constants.TANK_TYPE_HORIZONTAL_CYLINDER:
        {
          if (_lengthFormKey.currentState!.validate() &&
              _diameterFormKey.currentState!.validate()) {
            result = true;
          }
          break;
        }

      case Constants.TANK_TYPE_SIMPLE:
        {
          if (_heightFormKey.currentState!.validate() &&
              _capacityFormKey.currentState!.validate() &&
              _offsetFormKey.currentState!.validate()
          )  {
            result = true;
          }
          break;
        }

      case Constants.TANK_TYPE_HORIZONTAL_CAPSULE:
      case Constants.TANK_TYPE_VERTICAL_CAPSULE:
      case Constants.TANK_TYPE_HORIZONTAL_2_1_ELLIPTICAL:
      case Constants.TANK_TYPE_HORIZONTAL_DISH_ENDS:
        {
          if (_diameterFormKey.currentState!.validate() &&
              _sideLengthFormKey.currentState!.validate()) {
            result = true;
          }
          break;
        }
      default:
        result = false;
    }

    print('verifyDimensionValue[${tankType}]] result=${result} ');
    return result;
  }

  Future<Tank?> showTankConfigurationDialog() {
    return showDialog<Tank>(
      context: context,
      builder: (context) =>
          AlertDialog(
            insetPadding: EdgeInsets.only(
              top: 2.0,
              left: 4.0,
              right: 4.0,
            ),
            title: Container(
                alignment: Alignment.topCenter,
                child: Text('Tank Configuration')),
            content: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: EdgeInsets.symmetric(),
                color: Colors.limeAccent,
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TankDimensionConfig(device: this.device, selectedTankType: mSelectedTankType,
                        tankDialog: this.tankDialog,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('CLOSE')),
              TextButton(
                // onPressed: submitNotificationSettings,
                  onPressed: () {
                    print('>>>Call verifyDimensionValue(${mSelectedTankType}');
                    if(verifyDimensionValue(mSelectedTankType)) {
                      // If the form is valid, display a snackbar. In the real world,
                      // you'd often call a server or save the information in a database.
                      updateTankDimensionSettings();

                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('Updated Data')),
                      // );

                    } else {
                      showDialog(
                          context: context,
                          builder: (_) =>
                              CupertinoAlertDialog(
                                title: Text("Invalid Tank Dimension Config Value"),
                                content: Text(
                                    "Please enter the correct number format of the tank dimension.\ And re-submit again."),
                                actions: [
                                  CupertinoDialogAction(
                                    child: Text("OK"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                          barrierDismissible: false);
                    }
                  },
                  child: Text('SUBMIT')),
            ],
          ),
    );
  }

  // Widget _buildListItem(BuildContext context, int index) {
  //   if (index == data.length)
  //     return Center(child: CircularProgressIndicator(),);
  //
  //   //horizontal
  //   return Container(
  //     width: 150,
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: <Widget>[
  //         Container(
  //           height: 200,
  //           width: 150,
  //           color: Colors.lightBlueAccent,
  //           child: Text("i:$index\n${data[index]}"),
  //         )
  //       ],
  //     ),
  //   );
  // }
  //
  // void _onItemFocus(int index) {
  //   print(index);
  //   setState(() {
  //     _focusedIndex = index;
  //   });
  // }

  Future<Task?> showOperationModeInputDialog() =>
      showDialog<Task>(
        context: context,
        builder: (context) => AlertDialog(
          insetPadding: EdgeInsets.only(
            top: 2.0,
            left: 4.0,
            right: 4.0,
          ),
          title: Container(
              alignment: Alignment.topCenter, child: Text('Operation Mode')),
          content: SingleChildScrollView(
            child: OpeartionModeDialogWidget(
              task: task,
              user: user!,
              device: this.device,
              operationDeviceId: mSensorOperationUnit.uid,
              platform_mac_address: g_platform_mac_address,
              // isOrderSubmitted: isOrderSubmitted,
            ),
          ),
          actions: [
          ],
        ),
      );

  Future<Notify.Notification?> showNotificationInputDialog() =>
      showDialog<Notify.Notification>(
        context: context,
        builder: (context) => AlertDialog(
          insetPadding: EdgeInsets.only(
            top: 2.0,
            left: 4.0,
            right: 4.0,
          ),
          title: Container(
              alignment: Alignment.topCenter, child: Text('Notification')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Visibility(
                  visible: false,
                  child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Container(
                          padding: EdgeInsets.only(left: 0.0, right: 0.0),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black26)),
                          child: CheckboxListTile(
                            title: Text(
                              'Send notification email',
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                            subtitle: Text(
                              'Enable send the notification email when it meet condition.',
                              style: TextStyle(fontSize: 12, color: Colors.black38),
                            ),
                            secondary: Icon(Icons.mail_outline),
                            controlAffinity: ListTileControlAffinity.trailing,
                            value: this.notification.isSendNotify,
                            selected: this.notification.isSendNotify,
                            // value: _checked,
                            onChanged: (bool? value) {
                              setState(() {
                                this.notification.isSendNotify = value!;
                                print('check value=${value}');
                              });
                            },
                            activeColor: Colors.lightGreen,
                            checkColor: Colors.yellow,
                          ),
                        );
                      }),
                ),


                Visibility(
                  visible: false,
                  child: Form(
                    key: _emailFormKey,
                    child: TextFormField(
                      initialValue: this.notification.notifyEmail,
                      keyboardType: TextInputType.emailAddress,
                      // validator: (val) => !isEmail(val!) ? 'Invalid Email' : null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        } else {
                          if (!isEmail(value!)) {
                            return 'Invalid Email';
                          }
                          setState(() {
                            this.notificationDialog.notifyEmail = value;
                          });

                          return null;
                        }
                      },
                      autofocus: false,
                      decoration: InputDecoration(
                        label: Text(
                          'Email:',
                          style: TextStyle(fontSize: 16, color: Colors.black45),
                        ),
                        // labelText: Text('Email:'),
                        hintText: 'Enter your email address',
                      ),
                      // controller: name_controller,
                      // onChanged: (value) {
                      //   setState(() {
                      //     this.device.notifyEmail = value;
                      //   });
                      // },
                      // onSubmitted: (_) => submitNotificationSettings(),
                    ),
                  ),
                ),
                // SizedBox(
                //   height: 8,
                // ),
                Text(
                  'when',
                  style: TextStyle(fontSize: 16, color: Colors.black45),
                ),
                // SizedBox(
                //   height: 8,
                // ),
                Visibility(
                    visible: false,
                    child: buildTemperatureNotifyDialog()),
                // SizedBox(
                //   height: 8,
                // ),
                Visibility(
                    visible: false,
                    child: buildHumidityNotifyDialog()),
                // SizedBox(
                //   height: 8,
                // ),
                buildTankFilledLevelNotifyDialog(),

                // buildCustomPicker(),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('CLOSE')),
            TextButton(
              // onPressed: submitNotificationSettings,
                onPressed: () {
                  updateNotificationSettings();


                  // // Validate returns true if the form is valid, or false otherwise.
                  // if (_emailFormKey.currentState!.validate()) {
                  //   // If the form is valid, display a snackbar. In the real world,
                  //   // you'd often call a server or save the information in a database.
                  //   updateNotificationSettings();
                  //
                  //   // ScaffoldMessenger.of(context).showSnackBar(
                  //   //   const SnackBar(content: Text('Updated Data')),
                  //   // );
                  //
                  // } else {
                  //   showDialog(
                  //       context: context,
                  //       builder: (_) => CupertinoAlertDialog(
                  //             title: Text("Invalid Email"),
                  //             content: Text(
                  //                 "Please enter the correct email format.\ And submit again."),
                  //             actions: [
                  //               CupertinoDialogAction(
                  //                 child: Text("OK"),
                  //                 onPressed: () {
                  //                   Navigator.pop(context);
                  //                 },
                  //               ),
                  //             ],
                  //           ),
                  //       barrierDismissible: false);
                  // }
                },
                child: Text('SUBMIT')),
          ],
        ),
      );

  Future<OperationUnit?>  showOperationUnitInputDialog() =>
    showDialog<OperationUnit>(
      context: context,
      builder: (context) =>
          AlertDialog(
            insetPadding: EdgeInsets.only(
              top: 2.0,
              left: 4.0,
              right: 4.0,
            ),
            title: Container(
                alignment: Alignment.topCenter, child: Text('Operation Unit')
            ),
            // content: buildOperationUnitList(),
            content: OperationUnitListWidget(
              user: user!.userName,
              sensorUid: widget.device.uid,
              operationUnitLists: operationUnitLists,),
            actions: [
              TextButton(
                  onPressed: () {

                    print('zzzzztempOperationUnitLists.length=${Provider.of<TempOperationUnitList>(context, listen: false).tempOperationUnitLists.length}');
                    // print('xxxxtempOperationUnitLists.length=${context.watch<TempOperationUnitList>().tempOperationUnitLists.length}');
                    Navigator.of(context).pop();
                  },
                  child: Text('CLOSE')),
              TextButton(
                // onPressed: submitNotificationSettings,
                  onPressed: () {
                    List<OperationUnit> batchUpdatedLists = [];

                    batchUpdatedLists = Provider.of<TempOperationUnitList>(context, listen: false).tempOperationUnitLists;

                    // Validate returns true if the form is valid, or false otherwise.
                    // print('tempOperationUnitLists.length=${context.read<_OperationUnitListWidgetState>().tempOperationUnitLists.length}');
                    if (batchUpdatedLists.length > 0) {
                      // If the form is valid, display a snackbar. In the real world,
                      // you'd often call a server or save the information in a database.
                      updateSensorParing(batchUpdatedLists);

                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('Updated Data')),
                      // );

                    } else {
                      showDialog(
                          context: context,
                          builder: (_) =>
                              CupertinoAlertDialog(
                                title: Text("The pump or relay devices list not found!"),
                                content: Text(
                                    "Please turn on and register the pump or relay device.\ And try again."),
                                actions: [
                                  CupertinoDialogAction(
                                    child: Text("OK"),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                          barrierDismissible: false);
                    }
                  },
                  child: Text('SUBMIT')),
            ],
          ),
    );

  Future<OperationUnit?>  showDeleteHistoryConfirmDialog() =>
      showDialog<OperationUnit>(
        context: context,
        builder: (context) =>
            AlertDialog(
              insetPadding: EdgeInsets.only(
                top: 2.0,
                left: 4.0,
                right: 4.0,
              ),
              title: Container(
                  alignment: Alignment.topCenter, child: Text('Delete History', style: TextStyle(color: Colors.red), )
              ),
              // content: buildOperationUnitList(),
              content: Text('Would you like to delete this history from the system? To optimize system performance.\n\nIf yes, press YES.', style: TextStyle(color: Colors.black54),),
              actions: [
                TextButton(
                    onPressed: () {
                      print('Close Delete Dialog');
                      Navigator.of(context).pop();
                    },
                    child: Text('NO')),
                TextButton(
                    onPressed: () {
                      print('Yes -> do the delete process...');

                      deleteUserDeviceHistory();
                    },
                    child: Text('YES')),
              ],
            ),
      );

  Future<OperationUnit?>  showDeleteDeviceNodeConfirmDialog() =>
      showDialog<OperationUnit>(
        context: context,
        builder: (context) =>
            AlertDialog(
              insetPadding: EdgeInsets.only(
                top: 2.0,
                left: 4.0,
                right: 4.0,
              ),
              title: Container(
                  alignment: Alignment.topCenter, child: Text('Delete Device Node', style: TextStyle(color: Colors.red), )
              ),
              // content: buildOperationUnitList(),
              content: Text('Would you like to delete this device node from the system?\n\nIf yes, press YES.', style: TextStyle(color: Colors.black54),),
              actions: [
                TextButton(
                    onPressed: () {
                      print('Close Delete Dialog');
                      Navigator.of(context).pop();
                    },
                    child: Text('NO')),
                TextButton(
                    onPressed: () {
                      print('Yes -> do the delete process...');

                      deleteUserDeviceNode();
                    },
                    child: Text('YES')),
              ],
            ),
      );


  void submitNotificationSettings() {
    // Navigator.of(context).pop(name_controller.text);
    //
    // name_controller.clear();
  }

  // Widget buildCustomPicker() => SizedBox(
  //   height: 300,
  //   child: CupertinoPicker(
  //     itemExtent: 64,
  //     diameterRatio: 0.7,
  //     looping: true,
  //     onSelectedItemChanged: (index) => setState(() => this.selectedIndex = index),
  //     // selectionOverlay: Container(),
  //     selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
  //       background: Colors.pink.withOpacity(0.12),
  //     ),
  //     children: Utils.modelBuilder<String>(
  //       pickerValues,
  //           (index, value) {
  //         final isSelected = this.selectedIndex == index;
  //         final color = isSelected ? Colors.pink : Colors.black;
  //
  //         return Center(
  //           child: Text(
  //             value,
  //             style: TextStyle(color: color, fontSize: 24),
  //           ),
  //         );
  //       },
  //     ),
  //   ),
  // );

  Widget buildTemperatureNumberPicker(int pickerType) => SizedBox(
        height: 80,
        width: 50,
        child: CupertinoPicker(
          // backgroundColor: Colors.limeAccent,
          itemExtent: 48,
          diameterRatio: 1.5,
          looping: true,
          useMagnifier: true,
          magnification: 1.2,
          scrollController: FixedExtentScrollController(
              initialItem: initNotificationScrollIndex(pickerType)),
          onSelectedItemChanged: (index) => setState(() {
            switch (pickerType) {
              case Constants.TEMP_LOWER:
                {
                  this.notificationDialog.notifyTempLower =
                      double.parse(Constants.pickerHTValues[index].toString());
                  break;
                }
              case Constants.TEMP_HIGHER:
                {
                  this.notificationDialog.notifyTempHigher =
                      double.parse(Constants.pickerHTValues[index].toString());
                  break;
                }
              default:
                {
                  this.notificationDialog.notifyTempLower =
                      double.parse(Constants.pickerHTValues[index].toString());
                  break;
                }
            }
          }),
          selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
            background: Colors.orangeAccent.withOpacity(0.10),
          ),

          children: Utils.modelBuilder<String>(Constants.pickerHTValues, (index, value) {
            // final color = isSelected ? Colors.pink : Colors.black45;
            // final isSelected = this.selectedIndex == index;
            // final color = isSelected ? Colors.pink : Colors.black;
            return Center(
              child: Text(
                value,
                style: TextStyle(color: Colors.deepOrangeAccent, fontSize: 16),
                // style: TextStyle(color: isSelected ? Colors.pink : Colors.black45, fontSize: 24),
              ),
            );
          }),
        ),
      );

  Widget buildHumidityNumberPicker(int pickerType) => SizedBox(
        height: 80,
        width: 50,
        child: CupertinoPicker(
          // backgroundColor: Colors.limeAccent,
          itemExtent: 48,
          diameterRatio: 1.5,
          looping: true,
          useMagnifier: true,
          magnification: 1.2,
          scrollController: FixedExtentScrollController(
              initialItem: initNotificationScrollIndex(pickerType)),
          // onSelectedItemChanged: (index) => setState(() => this.index = index),
          // onSelectedItemChanged: (index) => setState(() => this.selectedIndex = index),
          onSelectedItemChanged: (index) => setState(() {
            switch (pickerType) {
              case Constants.HUMID_LOWER:
                {
                  this.notificationDialog.notifyHumidLower =
                      double.parse(Constants.pickerHTValues[index].toString());
                  break;
                }
              case Constants.HUMID_HIGHER:
                {
                  this.notificationDialog.notifyHumidHigher =
                      double.parse(Constants.pickerHTValues[index].toString());
                  break;
                }
              default:
                {
                  this.notificationDialog.notifyHumidHigher =
                      double.parse(Constants.pickerHTValues[index].toString());
                  break;
                }
            }
          }),
          // onSelectedItemChanged: (int index) => setState(() {
          //   this.selectedIndex = index;
          //   print('onSelectedItemChanged this.index=${this.selectedIndex} | index=${index}');
          //   isSelected = this.selectedIndex == index;
          //   print('isSelected=${isSelected}');
          //
          // }),
          selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
            background: Colors.lightBlue.withOpacity(0.10),
          ),

          children: Utils.modelBuilder<String>(Constants.pickerHTValues, (index, value) {
            // final color = isSelected ? Colors.pink : Colors.black45;
            // final isSelected = this.selectedIndex == index;
            // final color = isSelected ? Colors.pink : Colors.black;
            return Center(
              child: Text(
                value,
                style: TextStyle(color: Colors.blue, fontSize: 16),
                // style: TextStyle(color: isSelected ? Colors.pink : Colors.black45, fontSize: 24),
              ),
            );
          }),
        ),
      );

  Widget buildTankFilledLevelNumberPicker(int pickerType) => SizedBox(
    height: 80,
    width: 50,
    child: CupertinoPicker(
      // backgroundColor: Colors.limeAccent,
      itemExtent: 48,
      diameterRatio: 1.5,
      looping: true,
      useMagnifier: true,
      magnification: 1.2,
      scrollController: FixedExtentScrollController(
          initialItem: initNotificationScrollIndex(pickerType)),
      // onSelectedItemChanged: (index) => setState(() => this.index = index),
      // onSelectedItemChanged: (index) => setState(() => this.selectedIndex = index),
      onSelectedItemChanged: (index) => setState(() {
        switch (pickerType) {
          case Constants.TANK_FILLED_LEVEL_LOWER:
            {
              this.notificationDialog.notifyTOFDistanceLower =
                  double.parse(Constants.pickerWaterLevelValues[index].toString());
              break;
            }
          case Constants.TANK_FILLED_LEVEL_HIGHER:
            {
              this.notificationDialog.notifyTOFDistanceHigher =
                  double.parse(Constants.pickerWaterLevelValues[index].toString());
              break;
            }
          default:
            {
              this.notificationDialog.notifyHumidHigher =
                  double.parse(Constants.pickerWaterLevelValues[index].toString());
              break;
            }
        }
      }),
      // onSelectedItemChanged: (int index) => setState(() {
      //   this.selectedIndex = index;
      //   print('onSelectedItemChanged this.index=${this.selectedIndex} | index=${index}');
      //   isSelected = this.selectedIndex == index;
      //   print('isSelected=${isSelected}');
      //
      // }),
      selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
        background: Colors.deepPurpleAccent.withOpacity(0.10),
      ),

      children: Utils.modelBuilder<String>(Constants.pickerWaterLevelValues, (index, value) {
        // final color = isSelected ? Colors.pink : Colors.black45;
        // final isSelected = this.selectedIndex == index;
        // final color = isSelected ? Colors.pink : Colors.black;
        return Center(
          child: Text(
            value,
            style: TextStyle(color: Colors.purple, fontSize: 16),
            // style: TextStyle(color: isSelected ? Colors.pink : Colors.black45, fontSize: 24),
          ),
        );
      }),
    ),
  );

  Widget buildTemperatureNotifyDialog() => SizedBox(
        height: 100,
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 50,
                ),
                Text(
                  'Lower than',
                  style: TextStyle(color: Colors.black45),
                ),
                SizedBox(
                  width: 20,
                ),
                Text(
                  'Higher than',
                  style: TextStyle(color: Colors.black45),
                ),
                SizedBox(
                  width: 4,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Temperature',
                  style: TextStyle(color: Colors.deepOrangeAccent, fontSize: 16),
                ),
                SizedBox(
                  width: 25,
                ),
                buildTemperatureNumberPicker(Constants.TEMP_LOWER),
                Text(
                  'or',
                  style: TextStyle(color: Colors.black45),
                ),
                buildTemperatureNumberPicker(Constants.TEMP_HIGHER),
              ],
            ),
          ],
        ),

        // child: CupertinoPicker(
        //   // backgroundColor: Colors.limeAccent,
        //   itemExtent: 48,
        //   diameterRatio: 1.5,
        //   looping: true,
        //   useMagnifier: true,
        //   magnification: 1.2,
        //   // onSelectedItemChanged: (index) => setState(() => this.index = index),
        //   onSelectedItemChanged: (index) => setState(() => this.selectedIndex = index),
        //   // onSelectedItemChanged: (int index) => setState(() {
        //   //   this.selectedIndex = index;
        //   //   print('onSelectedItemChanged this.index=${this.selectedIndex} | index=${index}');
        //   //   isSelected = this.selectedIndex == index;
        //   //   print('isSelected=${isSelected}');
        //   //
        //   // }),
        //   selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
        //     background: Colors.pink.withOpacity(0.10),
        //   ),
        //
        //   children: Utils.modelBuilder<String> (
        //       pickerValues,
        //           (index, value) {
        //         // final color = isSelected ? Colors.pink : Colors.black45;
        //         // final isSelected = this.selectedIndex == index;
        //         // final color = isSelected ? Colors.pink : Colors.black;
        //         return Center(
        //           child: Text(
        //             value,
        //             style: TextStyle(color: Colors.pink, fontSize: 16),
        //             // style: TextStyle(color: isSelected ? Colors.pink : Colors.black45, fontSize: 24),
        //           ),
        //         );
        //       }
        //   ),
        // ),
      );

  Widget buildHumidityNotifyDialog() => SizedBox(
        height: 100,
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 50,
                ),
                Text(
                  'Lower than',
                  style: TextStyle(color: Colors.black45),
                ),
                SizedBox(
                  width: 20,
                ),
                Text(
                  'Higher than',
                  style: TextStyle(color: Colors.black45),
                ),
                SizedBox(
                  width: 4,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Humidity',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
                SizedBox(
                  width: 10,
                ),
                buildHumidityNumberPicker(Constants.HUMID_LOWER),
                Text(
                  'or',
                  style: TextStyle(color: Colors.black45),
                ),
                buildHumidityNumberPicker(Constants.HUMID_HIGHER),
              ],
            ),
          ],
        ),

        // child: CupertinoPicker(
        //   // backgroundColor: Colors.limeAccent,
        //   itemExtent: 48,
        //   diameterRatio: 1.5,
        //   looping: true,
        //   useMagnifier: true,
        //   magnification: 1.2,
        //   // onSelectedItemChanged: (index) => setState(() => this.index = index),
        //   onSelectedItemChanged: (index) => setState(() => this.selectedIndex = index),
        //   // onSelectedItemChanged: (int index) => setState(() {
        //   //   this.selectedIndex = index;
        //   //   print('onSelectedItemChanged this.index=${this.selectedIndex} | index=${index}');
        //   //   isSelected = this.selectedIndex == index;
        //   //   print('isSelected=${isSelected}');
        //   //
        //   // }),
        //   selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
        //     background: Colors.pink.withOpacity(0.10),
        //   ),
        //
        //   children: Utils.modelBuilder<String> (
        //       pickerValues,
        //           (index, value) {
        //         // final color = isSelected ? Colors.pink : Colors.black45;
        //         // final isSelected = this.selectedIndex == index;
        //         // final color = isSelected ? Colors.pink : Colors.black;
        //         return Center(
        //           child: Text(
        //             value,
        //             style: TextStyle(color: Colors.pink, fontSize: 16),
        //             // style: TextStyle(color: isSelected ? Colors.pink : Colors.black45, fontSize: 24),
        //           ),
        //         );
        //       }
        //   ),
        // ),
      );

  Widget buildTankFilledLevelNotifyDialog() => SizedBox(
    height: 100,
    child: Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
            ),
            Text(
              'Lower than',
              style: TextStyle(color: Colors.black45),
            ),
            SizedBox(
              width: 20,
            ),
            Text(
              'Higher than',
              style: TextStyle(color: Colors.black45),
            ),
            SizedBox(
              width: 4,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Tank Filled Level',
              style: TextStyle(color: Colors.purple, fontSize: 16),
            ),
            SizedBox(
              width: 10,
            ),
            buildTankFilledLevelNumberPicker(Constants.TANK_FILLED_LEVEL_LOWER),
            Text(
              'or',
              style: TextStyle(color: Colors.black45),
            ),
            buildTankFilledLevelNumberPicker(Constants.TANK_FILLED_LEVEL_HIGHER),
          ],
        ),
      ],
    ),

    // child: CupertinoPicker(
    //   // backgroundColor: Colors.limeAccent,
    //   itemExtent: 48,
    //   diameterRatio: 1.5,
    //   looping: true,
    //   useMagnifier: true,
    //   magnification: 1.2,
    //   // onSelectedItemChanged: (index) => setState(() => this.index = index),
    //   onSelectedItemChanged: (index) => setState(() => this.selectedIndex = index),
    //   // onSelectedItemChanged: (int index) => setState(() {
    //   //   this.selectedIndex = index;
    //   //   print('onSelectedItemChanged this.index=${this.selectedIndex} | index=${index}');
    //   //   isSelected = this.selectedIndex == index;
    //   //   print('isSelected=${isSelected}');
    //   //
    //   // }),
    //   selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
    //     background: Colors.pink.withOpacity(0.10),
    //   ),
    //
    //   children: Utils.modelBuilder<String> (
    //       pickerValues,
    //           (index, value) {
    //         // final color = isSelected ? Colors.pink : Colors.black45;
    //         // final isSelected = this.selectedIndex == index;
    //         // final color = isSelected ? Colors.pink : Colors.black;
    //         return Center(
    //           child: Text(
    //             value,
    //             style: TextStyle(color: Colors.pink, fontSize: 16),
    //             // style: TextStyle(color: isSelected ? Colors.pink : Colors.black45, fontSize: 24),
    //           ),
    //         );
    //       }
    //   ),
    // ),
  );

  int initNotificationScrollIndex(int pickerType) {
    int index = 0;
    switch (pickerType) {
      case Constants.HUMID_LOWER:
        {
          index = this.notification.notifyHumidLower.toInt();
          break;
        }
      case Constants.HUMID_HIGHER:
        {
          index = this.notification.notifyHumidHigher.toInt();
          break;
        }
      case Constants.TEMP_LOWER:
        {
          index = this.notification.notifyTempLower.toInt();
          break;
        }
      case Constants.TEMP_HIGHER:
        {
          index = this.notification.notifyTempHigher.toInt();
          break;
        }

      case Constants.TANK_FILLED_LEVEL_LOWER:
        {
          index = this.notification.notifyTOFDistanceLower.toInt();
          break;
        }
      case Constants.TANK_FILLED_LEVEL_HIGHER:
        {
          index = this.notification.notifyTOFDistanceHigher.toInt();
          break;
        }
      default:
        {
          index = 0;
          break;
        }
    }
    return index;
  }

  Widget drawPumpRelayStatusImage() {
    if(sensorOperationUnitLists.length > 0) {
      return Bounce(
        duration: Duration(milliseconds: 100),
        onPressed: () async {

          final operationUnitReturn =
          await showOperationUnitInputDialog();
          if (operationUnitReturn == null) return;
        },
        child: Container(
          // color: Colors.brown,
          width: displayWidth(context) * 0.2,
          child: Image(

            image: AssetImage(
              // 'images/pump_turn_on.png'),
              // Constants.gTankImagesMap[mSelectedTankType]!),
                getPumpRelayStatusImage(mSensorOperationUnit.status)),
          ),
        ),
      );
      // return GridView.count(
      //   crossAxisCount: 2,
      //   crossAxisSpacing: 5.0,
      //   mainAxisSpacing: 5.0,
      //   scrollDirection: Axis.vertical,
      //   // padding: const EdgeInsets.all(10),
      //   childAspectRatio: 16 / 9,
      //   shrinkWrap: true,
      //   children: List.generate(sensorOperationUnitLists.length, (index) {
      //     return Padding(
      //       padding: const EdgeInsets.all(2.0),
      //       child: OperationUnitCard(operationUnit: sensorOperationUnitLists[index]),
      //     );
      //   },),
      // );
    } else {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'none',
              style: TextStyle(fontSize: 14, color: Colors.black45),
            ),
            // buildCustomPicker(),
          ],
        ),
      );
    }

  }

  Widget drawOperationUnitDetail() {

    var operationUnitRef = FirebaseDatabase.instance
        .ref()
        .child('devices')
        .orderByKey();
    List<OperationUnit> sensorOperationUnitLists = [];
    return StreamBuilder(
        stream: operationUnitRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapOperationUnit) {
          if (snapOperationUnit.hasData && snapOperationUnit.data!.snapshot.exists && !snapOperationUnit.hasError) {
            if (snapOperationUnit.data!.snapshot.value != null) {
              print('snapOperationUnit.data!.snapshot.value is not null!!');

              operationUnitLists.clear();
              sensorOperationUnitLists.clear();
              Map<dynamic, dynamic> values = snapOperationUnit.data!.snapshot.value as Map;

              values.forEach((key, values) {
                print('key=${key}');
                print('uid=[${values['uid']}]');
                print('status=[${values['status']}]');
                print('updatedWhen=[${values['updatedWhen']}]');
                print('user=[${values['user']}]');
                print('sensor=[${values['sensor']}]');

                var sensorVar = values['sensor'] ?? '';

                // Operation Unit List for input dialog
                operationUnitLists.add(OperationUnit(
                  id: values['id'] ?? '',
                  uid: values['uid'] ?? '',
                  index: int.parse('${values['index'] ?? "0"}'),
                  name: values['name'] ?? '',
                  status: values['status'] ?? '',
                  user: values['user'] ?? '',
                  sensor: values['sensor'] ?? '',
                  updatedWhen: values['updatedWhen'] ?? '2022-11-11 11:11:11',

                ));

                if(sensorVar != '' && sensorVar == widget.device.uid) {
                  sensorOperationUnitLists.add(OperationUnit(
                    id: values['id'] ?? '',
                    uid: values['uid'] ?? '',
                    index: int.parse('${values['index'] ?? "0"}'),
                    name: values['name'] ?? '',
                    status: values['status'] ?? 'wait',
                    user: values['user'] ?? '',
                    sensor: values['sensor'] ?? '',
                    updatedWhen: values['updatedWhen'] ?? '2022-11-11 11:11:11',

                  ));
                }
              });

            } else {
              print('snapOperationUnit.data!.snapshot.value is null!!');
            }

            if(sensorOperationUnitLists.length > 0) {
              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 5.0,
                mainAxisSpacing: 5.0,
                scrollDirection: Axis.vertical,
                // padding: const EdgeInsets.all(10),
                childAspectRatio: 16 / 9,
                shrinkWrap: true,
                children: List.generate(sensorOperationUnitLists.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: OperationUnitCard(operationUnit: sensorOperationUnitLists[index]),
                  );
                },),
              );
            } else {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'none',
                      style: TextStyle(fontSize: 14, color: Colors.black45),
                    ),
                    // buildCustomPicker(),
                  ],
                ),
              );
            }
            // return SingleChildScrollView(
            //     child: Column(
            //       mainAxisSize: MainAxisSize.min,
            //       mainAxisAlignment: MainAxisAlignment.end,
            //       crossAxisAlignment: CrossAxisAlignment.center,
            //       children: [
            //         Text(
            //           'will send to',
            //           style: TextStyle(fontSize: 14, color: Colors.black45),
            //         ),
            //         Text(
            //           this.notification.notifyEmail,
            //           style: TextStyle(fontSize: 14, color: Colors.black87),
            //         ),
            //         SizedBox(
            //           height: 16,
            //         ),
            //       ],
            //     ),
            //   );
          } else {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'none',
                    style: TextStyle(fontSize: 14, color: Colors.black45),
                  ),
                  // buildCustomPicker(),
                ],
              ),
            );
          }

        }
        );
  }

  Widget drawNotificationDetail() {
    if (this.notification.isSendNotify) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Visibility(
              visible: false,
              child: Text(

                'will send to',
                style: TextStyle(fontSize: 14, color: Colors.black45),
              ),
            ),
            Visibility(
              visible: false,
              child: Text(
                this.notification.notifyEmail,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            SizedBox(
              height: 16,
            ),
            Text(
              'when',
              style: TextStyle(fontSize: 14, color: Colors.black45),
            ),
            // SizedBox(height: 8,),
            Visibility(
              visible: false,
              child: SizedBox(
                width: displayWidth(context) * 0.9,
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Temperature is lower than ',
                              style: TextStyle(fontSize: 14, color: Colors.black45),
                            ),
                            Text(
                              '${this.notification.notifyTempLower}\u2103',
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            Text(
                              ' or higher than ',
                              style: TextStyle(fontSize: 14, color: Colors.black45),
                            ),
                            Text(
                              '${this.notification.notifyTempHigher}\u2103',
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Visibility(
              visible: false,
              child: SizedBox(
                width: displayWidth(context) * 0.9,
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Humidity is lower than ',
                              style: TextStyle(fontSize: 14, color: Colors.black45),
                            ),
                            Text(
                              '${f.format(this.notification.notifyHumidLower)}%',
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            Text(
                              ' or higher than ',
                              style: TextStyle(fontSize: 14, color: Colors.black45),
                            ),
                            Text(
                              '${f.format(this.notification.notifyHumidHigher)}%',

                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(
              height: 8,
            ),
            SizedBox(
              width: displayWidth(context) * 0.9,
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Tank filled level is lower than ',
                            style: TextStyle(fontSize: 14, color: Colors.black45),
                          ),
                          Text(
                            '${f.format(this.notification.notifyTOFDistanceLower)}cm',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          Text(
                            ' or higher than ',
                            style: TextStyle(fontSize: 14, color: Colors.black45),
                          ),
                          Text(
                            '${f.format(this.notification.notifyTOFDistanceHigher)}cm',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // buildCustomPicker(),
          ],
        ),
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'none',
              style: TextStyle(fontSize: 14, color: Colors.black45),
            ),
            // buildCustomPicker(),
          ],
        ),
      );
    }
  }



  Widget drawReadDistanceLineChart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 2,
            right: 2,
          ),
          // child: LineChartSample10(),
          child: SizedBox(
            width: displayWidth(context) * 0.6,
            height: 150,
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(
                    show: true,
                    border:
                    Border.all(color: const Color(0xff37434d), width: 1)),
                minY: 0,
                maxY: 200,
                minX: readDistancePoints.first.x,
                maxX: readDistancePoints.last.x,
                // lineTouchData: LineTouchData(enabled: true),
                lineTouchData: lineTouchDataReadDistance,
                clipData: FlClipData.all(),
                // gridData: FlGridData(
                //   show: true,
                //   drawVerticalLine: false,
                // ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  horizontalInterval: 10,
                  verticalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xffb9c4c9),
                      strokeWidth: 0.5,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: const Color(0xffb9c4c9),
                      strokeWidth: 0.5,
                    );
                  },
                ),
                lineBarsData: [
                  readDistanceLine(readDistancePoints),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      // reservedSize: 38,
                    ),
                  ),
                  bottomTitles: AxisTitles(

                    sideTitles: SideTitles(
                      showTitles: false,

                      // reservedSize: 38,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Indicator(
              color: Colors.redAccent,
              text: 'Read distance',
              isSquare: true,
            ),
            SizedBox(
              height: 18,
            ),
          ],
        ),
      ],
    );
  }

  Widget drawTempHumidLineChart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 2,
            right: 2,
          ),
          // child: LineChartSample10(),
          child: SizedBox(
            width: displayWidth(context) * 0.6,
            height: 150,
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(
                    show: true,
                    border:
                        Border.all(color: const Color(0xff37434d), width: 1)),
                minY: 0,
                maxY: 100,
                minX: tempPoints.first.x,
                maxX: tempPoints.last.x,
                // lineTouchData: LineTouchData(enabled: true),
                lineTouchData: lineTouchDataTempHumid,
                clipData: FlClipData.all(),
                // gridData: FlGridData(
                //   show: true,
                //   drawVerticalLine: false,
                // ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  horizontalInterval: 10,
                  verticalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xffb9c4c9),
                      strokeWidth: 0.5,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: const Color(0xffb9c4c9),
                      strokeWidth: 0.5,
                    );
                  },
                ),
                lineBarsData: [
                  tempLine(tempPoints),
                  humidLine(humidPoints),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      // reservedSize: 38,
                    ),
                  ),
                  bottomTitles: AxisTitles(

                    sideTitles: SideTitles(
                      showTitles: false,

                      // reservedSize: 38,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Indicator(
              color: Colors.orangeAccent,
              text: 'Temperature',
              isSquare: true,
            ),
            SizedBox(
              height: 4,
            ),
            Indicator(
              color: Colors.blueAccent,
              text: 'Humidity',
              isSquare: true,
            ),
            SizedBox(
              height: 18,
            ),
          ],
        ),
      ],
    );
  }

  int getLifePulseMonitoring() {
    int result = Constants.INTERVAL_MINUTE_15;

    if(device.mode == Constants.MODE_AUTO) {
      result = Constants.INTERVAL_MINUTE_15;
    } else {
      result = Constants.INTERVAL_HOUR_6;
    }

    return result;
  }

  /**
   * Update console status when device status has been updated.
   */
  String updateConsoleStatus(String consoleType, consoleUpdatedWhen) {
    String result = '...';
    String currentDateStr = DateFormat("yyyy-MM-dd").format(DateTime.now());
    String currentTimeStr = DateFormat("HH:mm:ss").format(DateTime.now());
    String currentDateTimeStr = '$currentDateStr $currentTimeStr';

    if(consoleUpdatedWhen == '2022-11-11 11:11:11') {
      return result;
    }

    switch(consoleType) {
      case Constants.CONSOLE_TYPE_DISTANCE_SENSOR:
        {
          DateTime dt1;
          if(consoleUpdatedWhen == '') {
            dt1 = DateTime.parse(currentDateTimeStr);
          } else {
            dt1 = DateTime.parse(consoleUpdatedWhen);
          }

          DateTime dt2 = DateTime.parse(currentDateTimeStr);
          if(dt1.compareTo(dt2) == 0){
            print("Both date time are at same moment.");
            result = 'Normal';
            return result;
          }

          if(dt1.compareTo(dt2) < 0){
            // print("DT1 is before DT2");
            // print('consoleUpdatedWhen=${consoleUpdatedWhen}');
            // print('currentDateTimeStr=${currentDateTimeStr}');
            Duration diff = dt1.difference(dt2);
            // print('diff.inMinutes=${diff.inMinutes.abs()}');
            if(diff.inMinutes.abs() == 0) {
              result = 'Normal';
              return result;
            } else if(diff.inMinutes.abs() > (device.readingInterval / 60000)) {
              result = 'Sensor lost connect!';
              return result;
            } else {
              result = 'Normal';
              return result;
            }

          }

          if(dt1.compareTo(dt2) > 0){
            // print("DT1 is after DT2");
            result = 'Error';
            return result;
          }

          break;
        }
      case Constants.CONSOLE_TYPE_PUMP_RELAY:
        {
          gRefreshPage = gRefreshPage + 1;

          DateTime dt1 = DateTime.parse(consoleUpdatedWhen);
          DateTime dt2 = DateTime.parse(currentDateTimeStr);
          if(dt1.compareTo(dt2) == 0){
            // print("Both date time are at same moment.");
            result = 'Normal';
            return result;
          }

          if(dt1.compareTo(dt2) < 0){
            // print("DT1 is before DT2");
            // print('consoleUpdatedWhen=${consoleUpdatedWhen}');
            // print('currentDateTimeStr=${currentDateTimeStr}');
            Duration diff = dt1.difference(dt2);
            // print('diff.inMinutes=${diff.inMinutes.abs()}');

            if(diff.inMinutes.abs() == 0) {
              result = 'Normal';
              return result;
            // } else if(diff.inMinutes.abs() > (device.readingInterval / 60000)) {
            } else if(diff.inMinutes.abs() > (getLifePulseMonitoring() / 60000)) {
              result = 'Pump lost connect!';
              if(gRefreshPage == 2) {
                // to make sure, then send MQTT manual_0_180000 to test pump life's pulse.
                // Not used at the moment, to check publish false.
                // callMQTTPublishMonitor(Constants.SWITCH_OFF);
                gRefreshPage = 0;
              }
              return result;
            } else {
              result = 'Normal';
              return result;
            }

          }

          if(dt1.compareTo(dt2) > 0){
            // print("DT1 is after DT2");

            result = 'Normal';
            return result;
          }

          break;
        }
    }
    return result;
  }

  /**
   * Update console status background color when device status has been updated.
   */
  Color updateConsoleStatusBgColor(String consoleType, consoleUpdatedWhen) {
    Color result = Colors.blueGrey;
    String currentDateStr = DateFormat("yyyy-MM-dd").format(DateTime.now());
    String currentTimeStr = DateFormat("HH:mm:ss").format(DateTime.now());
    String currentDateTimeStr = '$currentDateStr $currentTimeStr';

    if(consoleUpdatedWhen == '2022-11-11 11:11:11') {
      return result;
    }

    switch(consoleType) {
      case Constants.CONSOLE_TYPE_DISTANCE_SENSOR:
        {
          DateTime dt1;
          if(consoleUpdatedWhen == '') {
            dt1 = DateTime.parse(currentDateTimeStr);
          } else {
            dt1 = DateTime.parse(consoleUpdatedWhen);
          }

          DateTime dt2 = DateTime.parse(currentDateTimeStr);
          if(dt1.compareTo(dt2) == 0){
            print("Both date time are at same moment.");
            // result = 'Normal';
            return result;
          }

          if(dt1.compareTo(dt2) < 0){
            // print("DT1 is before DT2");
            // print('consoleUpdatedWhen=${consoleUpdatedWhen}');
            // print('currentDateTimeStr=${currentDateTimeStr}');
            Duration diff = dt1.difference(dt2);
            // print('diff.inMinutes=${diff.inMinutes.abs()}');
            if(diff.inMinutes.abs() == 0) {
              // result = 'Normal';
              return result;
            } else if(diff.inMinutes.abs() > (device.readingInterval / 60000)) {
              result = Colors.red.shade500;
              return result;
            } else {
              // result = 'Normal';
              return result;
            }

          }

          if(dt1.compareTo(dt2) > 0){
            // print("DT1 is after DT2");
            // result = 'Error';
            result = Colors.red.shade500;
            return result;
          }

          break;
        }
      case Constants.CONSOLE_TYPE_PUMP_RELAY:
        {
          DateTime dt1 = DateTime.parse(consoleUpdatedWhen);
          DateTime dt2 = DateTime.parse(currentDateTimeStr);
          if(dt1.compareTo(dt2) == 0){
            // print("Both date time are at same moment.");
            // result = 'Normal';
            return result;
          }

          if(dt1.compareTo(dt2) < 0){
            // print("DT1 is before DT2");
            // print('consoleUpdatedWhen=${consoleUpdatedWhen}');
            // print('currentDateTimeStr=${currentDateTimeStr}');
            Duration diff = dt1.difference(dt2);
            // print('diff.inMinutes=${diff.inMinutes.abs()}');
            if(diff.inMinutes.abs() == 0) {
              // result = 'Normal';
              return result;
            // } else if(diff.inMinutes.abs() > (device.readingInterval / 60000)) {
            } else if(diff.inMinutes.abs() > (getLifePulseMonitoring() / 60000)) {

              result = Colors.red.shade500;
              return result;
            } else {
              // result = 'Normal';
              return result;
            }

          }

          if(dt1.compareTo(dt2) > 0){
            // print("DT1 is after DT2");
            // result = 'Normal';
            return result;
          }

          break;
        }
    }
    return result;
  }

  Future<void> verifyPumpDeviceTimeOver() async {
    String currentDateStr = DateFormat("yyyy-MM-dd").format(DateTime.now());
    String currentTimeStr = DateFormat("HH:mm:ss").format(DateTime.now());
    String currentDateTimeStr = '$currentDateStr $currentTimeStr';

    DateTime dt1 = DateTime.parse(mSensorOperationUnit.updatedWhen);
    DateTime dt2 = DateTime.parse(currentDateTimeStr);

    if(dt1.compareTo(dt2) < 0){
      // print("DT1 is before DT2");
      // print('mSensorOperationUnit.updatedWhen=${mSensorOperationUnit.updatedWhen}');
      // print('currentDateTimeStr=${currentDateTimeStr}');
      Duration diff = dt1.difference(dt2);
      // print('diff.inMinutes=${diff.inMinutes.abs()}');

      String pumpRelayStatus = 'Off';

      if(diff.inMinutes.abs() == 0) {
        // result = 'Normal';
        print('Normal situation - do nothing');
      } else if(diff.inMinutes.abs() > (getLifePulseMonitoring() / 60000)) {
        // result = 'Lost connect1';
        mSensorOperationUnit.status = 'Overtime';
        pumpRelayStatus = 'Overtime';

        DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$mSensorOperationUnit.uid");

        await ref.update({
          "status": pumpRelayStatus,
          // "updatedWhen": updated_status_datetime,
        }).then((value) => () {
          print('');
          print('Updated devices/$mSensorOperationUnit.uid  status: $mSensorOperationUnit.status is success.');
          print('');
        }).onError((error, stackTrace) => () {
          print('');
          print('Updated devices/$mSensorOperationUnit.uid  status: $mSensorOperationUnit.status is failed.');
          print('');
        });


      } else {
        pumpRelayStatus = mSensorOperationUnit.status;
        DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$mSensorOperationUnit.uid");

        await ref.update({
          "status": pumpRelayStatus,
          "updatedWhen": currentDateTimeStr,
        }).then((value) => () {
          print('');
          print('Updated devices/$mSensorOperationUnit.uid  status: $mSensorOperationUnit.status is success.');
          print('');
        }).onError((error, stackTrace) => () {
          print('');
          print('Updated devices/$mSensorOperationUnit.uid  status: $mSensorOperationUnit.status is failed.');
          print('');
        });
      }


    }
  }

  String getOperationPeriodInString(int operationPeriod) {
    String result = '';
    switch (operationPeriod) {
      case Constants.INTERVAL_MINUTE_30:
        {
          result = '30 min';
          break;
        }
      case Constants.INTERVAL_HOUR_1:
        {
          result = '1 hour';
          break;
        }
      case Constants.INTERVAL_HOUR_2:
        {
          result = '2 hours';
          break;
        }
      case Constants.INTERVAL_HOUR_3:
        {
          result = '3 hours';
          break;
        }

      case Constants.INTERVAL_HOUR_4:
        {
          result = '4 hours';
          break;
        }
      case Constants.INTERVAL_HOUR_5:
        {
          result = '5 hours';
          break;
        }
      case Constants.INTERVAL_HOUR_6:
        {
          result = '6 hours';
          break;
        }
      case Constants.INTERVAL_HOUR_12:
        {
          result = '12 hours';
          break;
        }
      case Constants.INTERVAL_HOUR_24:
        {
          result = '24 hours';
          break;
        }
      default:
        {
          result = '-';
          break;
        }
    }
    return result;
  }
}

class TempAndHumidCircularWidget extends StatelessWidget {
  const TempAndHumidCircularWidget({
    Key? key,
    required this.weatherHistory,
    required this.headlineStyle,
    required this.unitStyle,
  }) : super(key: key);

  final WeatherHistory weatherHistory;
  final TextStyle? headlineStyle;
  final TextStyle? unitStyle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: new BoxDecoration(
          color: Colors.lightGreen.shade800,
          border: Border.all(color: Colors.green.shade400, width: 8.0),
          borderRadius: new BorderRadius.all(Radius.circular(150.0)),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 50,
                  ),
                  Container(
                    child: Text(
                      '${globals.formatNumber(weatherHistory.weatherData.temperature) ?? ''}',
                      // '${globals.formatNumber(weatherHistory?.weatherData?.temperature is double ? weatherHistory?.weatherData?.temperature : 0)}',
                      style: headlineStyle,
                      // style: TextStyle(
                      //   color: Colors.white,
                      //   fontFamily: 'Kanit',
                      //   fontWeight: FontWeight.w300,
                      //   fontSize: 36.0,
                      // ),
                    ),
                  ),
                  Container(
                    child: Text(
                      'Temperature (\u2103)',
                      style: unitStyle,
                    ),
                  ),
                ],
              ),
              VerticalDivider(
                color: Colors.grey.withOpacity(0.2),
                thickness: 2,
                // width: 10,
                indent: 10,
                endIndent: 10,
              ),
              Column(
                children: [
                  SizedBox(
                    height: 50,
                  ),
                  Container(
                    child: Text(
                      '${globals.formatNumber(weatherHistory.weatherData.humidity) ?? ''}',
                      style: headlineStyle,
                      // style: TextStyle(
                      //   color: Colors.white,
                      //   fontFamily: 'Kanit',
                      //   fontWeight: FontWeight.w300,
                      //   fontSize: 36.0,
                      // ),
                    ),
                  ),
                  Container(
                    child: Text(
                      'Humidity (%)',
                      style: unitStyle,
                      // style: TextStyle(
                      //   color: Colors.white,
                      //   fontFamily: 'Kanit',
                      //   fontWeight: FontWeight.w300,
                      //   fontSize: 12.0,
                      // ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TankDimensionConfig extends StatefulWidget {
  final Device device;
  final String selectedTankType;
  final Tank tankDialog;



  const TankDimensionConfig({Key? key,
    required this.device,
    required this.selectedTankType,
    required this.tankDialog,

  }) : super(key: key);

  @override
  State<TankDimensionConfig> createState() => _TankDimensionConfigState();
}

class _TankDimensionConfigState extends State<TankDimensionConfig> {
  String _SelectedTankType = Constants.TANK_TYPE_VERTICAL_CYLINDER;
  bool _VisibilityHWL = true;
  bool _VisibilityLD = false;
  int _InitScrollIndex = 0;
  var f = NumberFormat("###.##", "en_US");

  @override
  void initState() {
    int index = 0;
    print('widget.selectedTankType=${widget.selectedTankType}');
    print('widget.device.wTankType=${widget.device.wTankType}');
    Constants.gTankTypesMap.keys.forEach((String key) {
      if(key == widget.device.wTankType) {
        _InitScrollIndex = index;
      }
      index++;
    });
    _SelectedTankType = widget.device.wTankType;
    print('_InitScrollIndex=${_InitScrollIndex}');
    if(_InitScrollIndex == 0) {
      _SelectedTankType = Constants.gTankTypesMap!.keys.elementAt(0);
    }
    print('_SelectedTankType=${_SelectedTankType}');
  }

  static Key getDimensionKey(String dimensionType) {
    switch(dimensionType) {
      case Constants.DIMENSION_TYPE_OFFSET: {
        return _ShowDevicePageState._offsetFormKey;
      }

      case Constants.DIMENSION_TYPE_LENGTH: {
        return _ShowDevicePageState._lengthFormKey;
      }
      case Constants.DIMENSION_TYPE_DIAMETER: {
        return _ShowDevicePageState._diameterFormKey;
      }
      case Constants.DIMENSION_TYPE_HEIGHT: {
        return _ShowDevicePageState._heightFormKey;
      }
      case Constants.DIMENSION_TYPE_CAPACITY: {
        return _ShowDevicePageState._capacityFormKey;
      }
      case Constants.DIMENSION_TYPE_WIDTH: {
        return _ShowDevicePageState._widthFormKey;
      }
      case Constants.DIMENSION_TYPE_SIDE_LENGTH: {
        return _ShowDevicePageState._sideLengthFormKey;
      }
      default: {
        return _ShowDevicePageState._lengthFormKey;
      }
    }
  }

  String getDimensionValue(String dimensionType) {
    String result = '';
    switch(dimensionType) {
      case Constants.DIMENSION_TYPE_OFFSET: {
        result = !_ShowDevicePageState.tank.wOffset!.isNaN ? f.format(_ShowDevicePageState.tank.wOffset!).toString() : '';
        break;
      }
      case Constants.DIMENSION_TYPE_CAPACITY: {
        result = !_ShowDevicePageState.tank.wCapacity!.isNaN ? f.format(_ShowDevicePageState.tank.wCapacity!).toString() : '';
        break;
      }
      case Constants.DIMENSION_TYPE_LENGTH: {
        result = !_ShowDevicePageState.tank.wLength!.isNaN ? f.format(_ShowDevicePageState.tank.wLength!).toString() : '';
        break;
      }
      case Constants.DIMENSION_TYPE_DIAMETER: {
        result = !_ShowDevicePageState.tank.wDiameter!.isNaN ? f.format(_ShowDevicePageState.tank.wDiameter!).toString() : '';
        break;
      }
      case Constants.DIMENSION_TYPE_HEIGHT: {
        result = !_ShowDevicePageState.tank.wHeight!.isNaN ? f.format(_ShowDevicePageState.tank.wHeight!).toString() : '';
        break;
      }
      case Constants.DIMENSION_TYPE_WIDTH: {
        result = !_ShowDevicePageState.tank.wWidth!.isNaN ? f.format(_ShowDevicePageState.tank.wWidth!).toString() : '';
        break;
      }
      case Constants.DIMENSION_TYPE_SIDE_LENGTH: {
        result = !_ShowDevicePageState.tank.wSideLength!.isNaN ? f.format(_ShowDevicePageState.tank.wSideLength!).toString() : '';
        break;
      }
      default: {
        result = '';
      }
    }
    print('getDimensionValue[${dimensionType}] _ShowDevicePageState.tank.wLength![${_ShowDevicePageState.tank.wLength!}] result=${result} ');
    print('getDimensionValue[${dimensionType}] widget.tankDialog.wHeight![${widget.tankDialog.wHeight!}] result=${result} ');
    return result;
  }

  void setDimensionValue(String dimensionType, String value) {
    if(value != '') {
      switch (dimensionType) {
        case Constants.DIMENSION_TYPE_OFFSET:
          {
            widget.device.wOffset = double.parse(value);
            widget.tankDialog.wOffset = double.parse(value);

            print('>> widget.device.wOffset=${widget.device.wOffset}');
            print(
                '>> widget.tankDialog.wOffset=${widget
                    .tankDialog.wOffset}');
            break;
          }
        case Constants.DIMENSION_TYPE_CAPACITY:
          {
            widget.device.wCapacity = double.parse(value);
            widget.tankDialog.wCapacity = double.parse(value);

            print('>> widget.device.wCapacity=${widget.device.wCapacity}');
            print(
                '>> widget.tankDialog.wCapacity=${widget
                    .tankDialog.wCapacity}');
            break;
          }
        case Constants.DIMENSION_TYPE_LENGTH:
          {
            widget.device.wLength = double.parse(value);
            widget.tankDialog.wLength = double.parse(value);

            print('>> widget.device.wLength=${widget.device.wLength}');
            print(
                '>> widget.tankDialog.wLength=${widget
                    .tankDialog.wLength}');
            break;
          }
        case Constants.DIMENSION_TYPE_DIAMETER:
          {
            widget.device.wDiameter = double.parse(value);
            widget.tankDialog.wDiameter = double.parse(value);
            print('>> widget.device.wDiameter=${widget.device.wDiameter}');
            print('>> widget.tank.wDiameter=${widget
                .tankDialog.wDiameter}');
            break;
          }
        case Constants.DIMENSION_TYPE_HEIGHT:
          {
            widget.device.wHeight = double.parse(value);
            widget.tankDialog.wHeight = double.parse(value);
            print('>> widget.device.wHeight=${widget.device.wHeight}');
            print('>> widget.tank.wHeight=${widget
                .tankDialog.wHeight}');
            break;
          }
        case Constants.DIMENSION_TYPE_WIDTH:
          {
            widget.device.wWidth = double.parse(value);
            widget.tankDialog.wWidth = double.parse(value);
            print('>> widget.device.wWidth=${widget.device.wWidth}');
            print('>> widget.tank.wWidth=${widget
                .tankDialog.wWidth}');
            break;
          }
        case Constants.DIMENSION_TYPE_SIDE_LENGTH:
          {
            widget.device.wSideLength = double.parse(value);
            widget.tankDialog.wSideLength = double.parse(value);
            print('>> widget.device.wSideLength=${widget.device.wSideLength}');
            print(
                '>> widget.tank.wSideLength=${widget
                    .tankDialog.wSideLength}');
            break;
          }
        default:
          {
            break;
          }
      }
    }
  }

  Widget buildTankTypeDimensionForm(String tankType) {
    List<Widget> list = <Widget>[];
    if (tankType == '') {
      tankType = Constants.TANK_TYPE_VERTICAL_CYLINDER;
    }

    Constants.gTankTypesMap[tankType]!.forEach((dimensionTypeName, symbol) {
      list.add(SizedBox(
        height: displayHeight(context) * 0.08, // MediaQuery.of(context).size.height / 2,

        child: Container(child: Row(

          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,

          children: [
            Text('$dimensionTypeName: ', style: TextStyle(color: Colors.black87),),
            // Text('_ ', style: TextStyle(color: Colors.black87),),
            Container(
              width: 100,
              height: 40,
              child: Form(
                key: getDimensionKey(dimensionTypeName),
                child: TextFormField(
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.normal, ),
                  initialValue: getDimensionValue(dimensionTypeName),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      // return 'Please enter a ${dimensionTypeName} tank dimension number.';
                      return 'Re-edit here';
                    } else {
                      // if (!isNumeric(value!)) {
                      //   return 'Invalid ${dimensionTypeName} tank dimension number';
                      // }
                      // setState(() {
                      //   // setDimensionValue(dimensionTypeName, value);
                      //   print('*** ${dimensionTypeName} value=${value}');
                      // });

                      return null;
                    }
                  },
                  // controller: TextEditingController(text: this.notificationDialog.notifyEmail),
                  autofocus: false,
                  // decoration: InputDecoration(
                  //   label: Text(
                  //     'Email:',
                  //     style: TextStyle(fontSize: 16, color: Colors.black45),
                  //   ),
                  //   // labelText: Text('Email:'),
                  //   hintText: 'Enter your email address',
                  // ),
                  // controller: name_controller,
                  onChanged: (value) {
                      setState(() {
                        setDimensionValue(dimensionTypeName, value);
                        print('+++ ${dimensionTypeName} value=${value}');
                      });
                  },
                  // onSubmitted: (_) => submitNotificationSettings(),
                ),
              ),
            ),
            Text('${symbol}', style: TextStyle(color: Colors.black87),),
          ],
        )),
      ));
    });

    list.add(SizedBox(
      height: displayHeight(context) * 0.08, // MediaQuery.of(context).size.height / 2,

      child: Container(child: Row(

        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,

        children: [
          Text('Offset (o): ', style: TextStyle(color: Colors.black87),),
          // Text('_ ', style: TextStyle(color: Colors.black87),),
          Container(
            width: 100,
            height: 40,
            child: Form(
              key: getDimensionKey(Constants.DIMENSION_TYPE_OFFSET),
              child: TextFormField(
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.normal, ),
                initialValue: getDimensionValue(Constants.DIMENSION_TYPE_OFFSET),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    // return 'Please enter a ${dimensionTypeName} tank dimension number.';
                    return 'Re-edit here';
                  } else {
                    // if (!isNumeric(value!)) {
                    //   return 'Invalid ${dimensionTypeName} tank dimension number';
                    // }
                    // setState(() {
                    //   // setDimensionValue(dimensionTypeName, value);
                    //   print('*** ${dimensionTypeName} value=${value}');
                    // });

                    return null;
                  }
                },
                // controller: TextEditingController(text: this.notificationDialog.notifyEmail),
                autofocus: false,
                // decoration: InputDecoration(
                //   label: Text(
                //     'Email:',
                //     style: TextStyle(fontSize: 16, color: Colors.black45),
                //   ),
                //   // labelText: Text('Email:'),
                //   hintText: 'Enter your email address',
                // ),
                // controller: name_controller,
                onChanged: (value) {
                  setState(() {
                    setDimensionValue(Constants.DIMENSION_TYPE_OFFSET, value);
                    print('+++ ${Constants.DIMENSION_TYPE_OFFSET} value=${value}');
                  });
                },
                // onSubmitted: (_) => submitNotificationSettings(),
              ),
            ),
          ),
          Text('cm', style: TextStyle(color: Colors.black87),),
        ],
      )),
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: list,
    );
  }

  List<Widget> buildTankTypesConfiguration() {
    List<Widget> results = [];
    Constants.gTankTypesMap!.forEach((name, symbol) {
      results.add(Container(
          height: 300,//displayHeight(context) * 0.4, // MediaQuery.of(context).size.height / 2,
          width: displayWidth(context) * 0.6,
          color: Colors.deepOrangeAccent,
          child: Card(
              color: Colors.black12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    // width: displayWidth(context) * 0.2,
                    height: displayHeight(context) * 0.15,
                    child: Image(
                      image: AssetImage(
                          Constants.gTankImagesMap[name]!),
                      // 'images/tanks/base_vertical_cylinder.jpg'),
                    ),
                  ),
                  // Text('$name'),
                ],
              ))

      )
      );
    });
    return results;
  }

  void changeVisibility() {
    setState(() {
      _VisibilityHWL = !_VisibilityHWL;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(child: Text('${_SelectedTankType}', style: TextStyle(color: Colors.black87, fontSize: 18)),),
          SizedBox(
            height: displayHeight(context) * 0.4, // MediaQuery.of(context).size.height / 2,
            width: displayWidth(context) * 0.6,
            child: ListWheelScrollView(
              controller: FixedExtentScrollController(initialItem: _InitScrollIndex),
              itemExtent: displayWidth(context) * 0.35,
              // itemExtent: 100,
              children: buildTankTypesConfiguration(),
              // children: items,
              // value between 0 --> 0.01
              perspective: 0.009,
              diameterRatio: 1.5,
              // default 2.0
              // useMagnifier: true,
              magnification: 1.1,
              physics: FixedExtentScrollPhysics(),

              onSelectedItemChanged: (index) {
                print('index====$index');
                setState(() {
                  _SelectedTankType =
                      Constants.gTankTypesMap!.keys.elementAt(index);
                  _ShowDevicePageState.mSelectedTankType = _SelectedTankType;
                  switch (_SelectedTankType) {
                    case Constants.TANK_TYPE_SIMPLE: {
                      break;
                    }
                    case Constants.TANK_TYPE_RECTANGLE:
                    case Constants.TANK_TYPE_HORIZONTAL_OVAL:
                    case Constants.TANK_TYPE_VERTICAL_OVAL:
                    case Constants.TANK_TYPE_HORIZONTAL_ELLIPSE:
                      {
                        _VisibilityHWL = true;
                        _VisibilityLD = false;
                        break;
                      }
                    case Constants.TANK_TYPE_VERTICAL_CYLINDER:
                    case Constants.TANK_TYPE_HORIZONTAL_CYLINDER:
                    case Constants.TANK_TYPE_HORIZONTAL_CAPSULE:
                    case Constants.TANK_TYPE_VERTICAL_CAPSULE:
                    case Constants
                        .TANK_TYPE_HORIZONTAL_2_1_ELLIPTICAL:
                    case Constants.TANK_TYPE_HORIZONTAL_DISH_ENDS:
                      {
                        _VisibilityHWL = false;
                        _VisibilityLD = true;
                        break;
                      }
                  }

                  // toast('index====$index | mTankType=$mSelectedTankType | mVisibilityHWL=$mVisibilityHWL');
                });
              },
            ),
          ),
          Container(child: buildTankTypeDimensionForm(_SelectedTankType)),
        ],
      ),
    );
  }
}



class OpeartionModeDialogWidget extends StatefulWidget {
  const OpeartionModeDialogWidget({Key? key,
    required this.task,
    required this.user,
    required this.device,
    required this.operationDeviceId,
    required this.platform_mac_address,
    // required this.isOrderSubmitted
  }) : super(key: key);

  final Task task;
  final User user;
  final Device device;
  final String operationDeviceId;
  final String platform_mac_address;
  // final ValueNotifier<bool> isOrderSubmitted;

  @override
  State<OpeartionModeDialogWidget> createState() => _OpeartionModeDialogWidgetState();
}

class _OpeartionModeDialogWidgetState extends State<OpeartionModeDialogWidget> {
  Task taskDialog = Task();
  bool gModeVisiblity = true;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if(widget.task.operationMode == Constants.MODE_AUTO) {
      gModeVisiblity = false;
    } else {
      gModeVisiblity = true;
    }
  }

  Future<OperationUnit?>  showManualSubmitConfirmDialog() =>
      showDialog<OperationUnit>(
        context: context,
        builder: (context) =>
            AlertDialog(
              insetPadding: EdgeInsets.only(
                top: 2.0,
                left: 4.0,
                right: 4.0,
              ),
              title: Container(
                  alignment: Alignment.topCenter, child: Text('Submit Manual Command', style: TextStyle(color: Colors.redAccent, fontSize: 24), )
              ),
              // content: buildOperationUnitList(),
              content: Text('Would you like to submit this command to the system? To order the Pump operation.\n\nIf yes, press YES.',
                style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    ),),
              actions: [
                TextButton(
                    onPressed: () {
                      print('Close Submit Manual Confirm Dialog');
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text('NO')),
                TextButton(
                    onPressed: () {
                      print('Yes -> do the submit manual process...');

                      updateOperationTaskSettings();
                    },
                    child: Text('YES')),
              ],
            ),
      );

  @override
  Widget build(BuildContext context) {

    // return const Placeholder();
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Visibility(
          visible: false,
          child: Text(
            'Mode:',
            style: TextStyle(fontSize: 16, color: Colors.black45),
          ),
        ),
        // Here, default theme colors are used for activeBgColor, activeFgColor, inactiveBgColor and inactiveFgColor
        Visibility(
          visible: false,
          child: ToggleSwitch(
            initialLabelIndex: (widget.task.operationMode != Constants.MODE_AUTO) ? 1 : 0,
            customWidths: [90, 90],
            fontSize: 16.0,
            activeBgColor: [Colors.cyan],
            activeFgColor: Colors.white,
            inactiveBgColor: Colors.grey,
            inactiveFgColor: Colors.blueGrey,
            totalSwitches: 2,
            labels: [Constants.MODE_AUTO, Constants.MODE_MANUAL],
            onToggle: (index) {

              setState(() {
                taskDialog.operationMode = (index == 0) ? Constants.MODE_AUTO : Constants.MODE_MANUAL;
                widget.task.operationMode = taskDialog.operationMode;
                gModeVisiblity = !gModeVisiblity;
              });

            },
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Visibility(
          visible: gModeVisiblity,

          child: Text(
            'Pump Switch:',
            style: TextStyle(fontSize: 16, color: Colors.black45),
          ),
        ),
        Visibility(
          visible: gModeVisiblity,
          child: ToggleSwitch(
            initialLabelIndex: (widget.task.command != Constants.SWITCH_ON) ? 1 : 0,
            customWidths: [90, 90],
            fontSize: 16.0,
            activeBgColor: [Colors.deepOrangeAccent],
            activeFgColor: Colors.white,
            inactiveBgColor: Colors.grey,
            inactiveFgColor: Colors.blueGrey,
            totalSwitches: 2,
            labels: [Constants.SWITCH_ON, Constants.SWITCH_OFF],
            onToggle: (index) {
              print('switched to: $index');
              taskDialog.command = (index == 0) ? Constants.SWITCH_ON : Constants.SWITCH_OFF;
            },
          ),
        ),

        SizedBox(
          height: 8,
        ),
        Visibility(
          visible: gModeVisiblity,
          child: Text(
            'Working Period',
            style: TextStyle(fontSize: 16, color: Colors.black45),
          ),
        ),

        Visibility(
          visible: gModeVisiblity,
          child: buildOperationPeriodDialog()
        ),

        SizedBox(
          height: 8,
        ),

        Row(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Bounce(
              duration: Duration(milliseconds: 100),
              onPressed: () async {
                print('on press close');

                Navigator.of(context).pop();
              },
              child: Container(
                padding: EdgeInsets.all(8.0),
                child: Text('CLOSE',
                  style: TextStyle(
                    color: Colors.cyan[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // TextButton(
            //     onPressed: () {
            //       Navigator.of(context).pop();
            //     },
            //     child: Text('CLOSE')),
            SizedBox(
              width: 32,
            ),

            Bounce(
              duration: Duration(milliseconds: 100),
              onPressed: () async {
                print('on press submit');

                final manualSubmitDialogReturn =
                await showManualSubmitConfirmDialog();
                if (manualSubmitDialogReturn == null) return;


              },
              child: Container(
                padding: EdgeInsets.all(8.0),
                child: Text('SUBMIT',
                  style: TextStyle(
                    color: Colors.cyan[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),


          ],
        ),
      ],
    );
  }

  Future<void> callMQTTDialogPublishSubmit() async {
    // Set logging on if needed, defaults to off
    client.logging(on: true);

    // Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    // If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
    client.keepAlivePeriod = 20;

    // The connection timeout period can be set if needed, the default is 2 seconds.
    client.connectTimeoutPeriod = 2000; // milliseconds

    // Add the unsolicited disconnection callback
    client.onDisconnected = onDisconnected;

    // Add the successful connection callback
    client.onConnected = onConnected;

    // Set a ping received callback if needed, called whenever a ping response(pong) is received
    // from the broker.
    client.pongCallback = pong;

    // Create a connection message to use or use the default one. The default one sets the
    // client identifier, any supplied username/password and clean session,
    // an example of a specific one below.
    final connMess = MqttConnectMessage()
    // .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withClientIdentifier(widget.platform_mac_address)
        .withWillTopic('willtopic') // If you set this you must set a will message
        .withWillMessage('IoT Cray Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    print('EXAMPLE::HiveMQTT client ${widget.platform_mac_address} connecting....');
    client.connectionMessage = connMess;

    // Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    // in some circumstances the broker will just disconnect us, see the spec about this, we however will
    // never send malformed messages.
    try {
      await client.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      print('EXAMPLE::client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('EXAMPLE::socket exception - $e');
      client.disconnect();
    }

    // Check we are connected
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      print(
          'EXAMPLE::ERROR 3 Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      // exit(-1);
    }

    // If needed you can listen for published messages that have completed the publishing
    // handshake which is Qos dependant. Any message received on this stream has completed its
    // publishing handshake with the broker.
    // client.published!.listen((MqttPublishMessage message) {
    //   print(
    //       'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
    // });

    // Lets publish to our topic
    // Use the payload builder rather than a raw buffer
    // Our known topic to publish to
    String topic_theSensor = 'watersupply/${widget.user!.userName}/sedimentation/${widget.device.uid}/waterlevel/status';

    // create mqtt command to switch on/off thePump
    final builder = MqttClientPayloadBuilder();
    if(this.taskDialog.operationMode == Constants.MODE_MANUAL) {
      String mqtt_command = Constants.MQTT_COMMAND_SWITCH_OFF;
      if(this.taskDialog.command == Constants.SWITCH_ON) {
        mqtt_command ='${Constants.MQTT_COMMAND_SWITCH_ON}${this.taskDialog.operationPeriod}';
      } else if(this.taskDialog.command == Constants.SWITCH_OFF) {
        mqtt_command ='${Constants.MQTT_COMMAND_SWITCH_OFF}${this.taskDialog.operationPeriod}';
      }

      builder.addString(mqtt_command);

      // Publish it
      print('EXAMPLE::Publishing our topic');
      client.publishMessage(topic_theSensor, MqttQos.atLeastOnce, builder.payload!);
    }

    // Ok, we will now sleep a while, in this gap you will see ping request/response
    // messages being exchanged by the keep alive mechanism.
    print('EXAMPLE::Sleeping....');
    await MqttUtilities.asyncSleep(60);

    // Wait for the unsubscribe message from the broker if you wish.
    // await MqttUtilities.asyncSleep(2);
    // print('EXAMPLE::Disconnecting');

    client.disconnect();
    print('EXAMPLE::Exiting normally');

    return;
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
  }



  /// The unsolicited disconnect callback
  void onDisconnected() {
    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus!.disconnectionOrigin ==
        MqttDisconnectionOrigin.solicited) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    } else {
      print(
          'EXAMPLE::OnDisconnected callback is unsolicited or none, this is incorrect - exiting');
      // exit(-1);
      print('MQTT disconnect!!!');
      print('Then resubscribe....');
      // re subscribe mqtt
      // callMQTTSubscribe();
    }
    if (pongCount == 3) {
      print('EXAMPLE:: Pong count is correct');
    } else {
      print('EXAMPLE:: Pong count is incorrect, expected 3. actual $pongCount');
    }
  }

  /// The successful connect callback
  void onConnected() {
    print(
        'EXAMPLE::OnConnected client callback - Client connection was successful');
  }

  /// Pong callback
  void pong() {
    print('EXAMPLE::Ping response client callback invoked');
    pongCount++;
  }

  /**
   * "the Node" to save the selected task values
   */
  Future<void> updateOperationTaskSettings() async {
    // update operation tasks settings in cloud database
    print(
        'update operation task settings in cloud database - users/${widget.user!.userName}/devices/${widget.device.uid}/tasks');

    DateTime currentDateTime = DateTime.now();
    String currentDateStr = DateFormat("yyyy-MM-dd").format(currentDateTime);
    String currentTimeStr = DateFormat("HH:mm:ss").format(currentDateTime);
    String currentDateTimeStr = '$currentDateStr $currentTimeStr';

    // verify values
    if(this.taskDialog.operationMode == '') {
      this.taskDialog.operationMode = widget.task.operationMode;
    }

    if(this.taskDialog.operationPeriod == 0) {
      this.taskDialog.operationPeriod = widget.task.operationPeriod;
    }

    if(this.taskDialog.command == '') {
      this.taskDialog.command = widget.task.command;
    }

    Duration customDuration = Duration(milliseconds: this.taskDialog.operationPeriod); // Custom time to add
    DateTime expectedDateTime = currentDateTime.add(customDuration);
    String expectedDateStr = DateFormat("yyyy-MM-dd").format(expectedDateTime);
    String expectedTimeStr = DateFormat("HH:mm:ss").format(expectedDateTime);
    String expectedDateTimeStr = '$expectedDateStr $expectedTimeStr';

    var deviceRef = FirebaseDatabase.instance
        .ref()
        .child('users/${widget.user!.userName}/devices/${widget.device.uid}/tasks')
        .update({

      'operationDeviceId': widget.operationDeviceId,

      // 'operationMode': (this.taskDialog.operationMode == '') ? widget.task.operationMode : this.taskDialog.operationMode,
      'operationMode': this.taskDialog.operationMode,
      // 'operationPeriod': (this.taskDialog.operationPeriod == 0) ? widget.task.operationPeriod : this.taskDialog.operationPeriod,
      'operationPeriod': this.taskDialog.operationPeriod,
      // 'command': (this.taskDialog.command == '') ? widget.task.command : this.taskDialog.command,
      'command': this.taskDialog.command,
      'readingInterval': widget.device.readingInterval,
      'updatedWhen': currentDateTimeStr,
      'expectedWhen': expectedDateTimeStr,
    })
        .onError((error, stackTrace) =>
        print('update Operation Task Settings error=${error.toString()}'))
        .whenComplete(() {
          print('updated operation task settings success.');
          // call publish command
          callMQTTDialogPublishSubmit();

          // trigger update submit ordered
          // widget.isOrderSubmitted.value = !widget.isOrderSubmitted.value;

          showDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: Text("Update Successfully"),
                content:
                Text("Update operation task settings is successfully."),
                actions: [
                  CupertinoDialogAction(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              barrierDismissible: false);

        });

    return;
  }

  int getOperationPeriodInSecond(int periodIndex) {
    int secondResult = 0;
    switch (periodIndex) {
      case 0:
        {
          secondResult = Constants.INTERVAL_MINUTE_30;
          break;
        }
      case 1:
        {
          secondResult = Constants.INTERVAL_HOUR_1;
          break;
        }
      case 2:
        {
          secondResult = Constants.INTERVAL_HOUR_2;
          break;
        }
      case 3:
        {
          secondResult = Constants.INTERVAL_HOUR_3;
          break;
        }

      case 4:
        {
          secondResult = Constants.INTERVAL_HOUR_4;
          break;
        }
      case 5:
        {
          secondResult = Constants.INTERVAL_HOUR_5;
          break;
        }
      case 6:
        {
          secondResult = Constants.INTERVAL_HOUR_6;
          break;
        }
      case 7:
        {
          secondResult = Constants.INTERVAL_HOUR_12;
          break;
        }
      case 8:
        {
          secondResult = Constants.INTERVAL_HOUR_24;
          break;
        }
      default:
        {
          secondResult = 0;
          break;
        }
    }
    taskDialog.operationPeriod = secondResult;

    return secondResult;
  }

  int initOperationPeriodScrollIndex(int periodInSecond) {
    int index = 0;
    switch (periodInSecond) {
      case Constants.INTERVAL_MINUTE_30:
        {
          index = 0;
          break;
        }
      case Constants.INTERVAL_HOUR_1:
        {
          index = 1;
          break;
        }
      case Constants.INTERVAL_HOUR_2:
        {
          index = 2;
          break;
        }
      case Constants.INTERVAL_HOUR_3:
        {
          index = 3;
          break;
        }

      case Constants.INTERVAL_HOUR_4:
        {
          index = 4;
          break;
        }
      case Constants.INTERVAL_HOUR_5:
        {
          index = 5;
          break;
        }
      case Constants.INTERVAL_HOUR_6:
        {
          index = 6;
          break;
        }
      case Constants.INTERVAL_HOUR_12:
        {
          index = 7;
          break;
        }
      case Constants.INTERVAL_HOUR_24:
        {
          index = 8;
          break;
        }
      default:
        {
          index = 0;
          break;
        }
    }
    return index;
  }

  Widget buildOperationPeriodPicker() => SizedBox(
    height: 80,
    width: 200,
    child: CupertinoPicker(
      // backgroundColor: Colors.limeAccent,
      itemExtent: 48,
      diameterRatio: 1.5,
      looping: true,
      useMagnifier: true,
      magnification: 1.2,
      scrollController: FixedExtentScrollController(
          initialItem: initOperationPeriodScrollIndex(widget.task.operationPeriod)),
      // onSelectedItemChanged: (index) => setState(() => this.index = index),
      // onSelectedItemChanged: (index) => setState(() => this.selectedIndex = index),
      // onSelectedItemChanged: (index) => setState(() {
      //   taskDialog.operationPeriod = getOperationPeriodInSecond(index);
      // }),
      onSelectedItemChanged: (index) => taskDialog.operationPeriod = getOperationPeriodInSecond(index),
      // onSelectedItemChanged: (int index) => setState(() {
      //   this.selectedIndex = index;
      //   print('onSelectedItemChanged this.index=${this.selectedIndex} | index=${index}');
      //   isSelected = this.selectedIndex == index;
      //   print('isSelected=${isSelected}');
      //
      // }),
      selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
        background: Colors.deepPurpleAccent.withOpacity(0.10),
      ),

      children: Utils.modelBuilder<String>(Constants.pickerOperationPeriodValues, (index, value) {
        // final color = isSelected ? Colors.pink : Colors.black45;
        // final isSelected = this.selectedIndex == index;
        // final color = isSelected ? Colors.pink : Colors.black;
        return Center(
          child: Text(
            value,
            style: TextStyle(color: Colors.purple, fontSize: 16),
            // style: TextStyle(color: isSelected ? Colors.pink : Colors.black45, fontSize: 24),
          ),
        );
      }),
    ),
  );

  Widget buildOperationPeriodDialog() => SizedBox(
    height: 100,
    child: Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildOperationPeriodPicker(),
          ],
        ),
      ],
    ),

    // child: CupertinoPicker(
    //   // backgroundColor: Colors.limeAccent,
    //   itemExtent: 48,
    //   diameterRatio: 1.5,
    //   looping: true,
    //   useMagnifier: true,
    //   magnification: 1.2,
    //   // onSelectedItemChanged: (index) => setState(() => this.index = index),
    //   onSelectedItemChanged: (index) => setState(() => this.selectedIndex = index),
    //   // onSelectedItemChanged: (int index) => setState(() {
    //   //   this.selectedIndex = index;
    //   //   print('onSelectedItemChanged this.index=${this.selectedIndex} | index=${index}');
    //   //   isSelected = this.selectedIndex == index;
    //   //   print('isSelected=${isSelected}');
    //   //
    //   // }),
    //   selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
    //     background: Colors.pink.withOpacity(0.10),
    //   ),
    //
    //   children: Utils.modelBuilder<String> (
    //       pickerValues,
    //           (index, value) {
    //         // final color = isSelected ? Colors.pink : Colors.black45;
    //         // final isSelected = this.selectedIndex == index;
    //         // final color = isSelected ? Colors.pink : Colors.black;
    //         return Center(
    //           child: Text(
    //             value,
    //             style: TextStyle(color: Colors.pink, fontSize: 16),
    //             // style: TextStyle(color: isSelected ? Colors.pink : Colors.black45, fontSize: 24),
    //           ),
    //         );
    //       }
    //   ),
    // ),
  );
}

class OperationUnitCard extends StatefulWidget {
  const OperationUnitCard({
    Key? key,
    required this.operationUnit,
  }) : super(key: key);

  final OperationUnit operationUnit;

  @override
  _OperationUnitCardState createState() => _OperationUnitCardState();
}

class _OperationUnitCardState extends State<OperationUnitCard> {
  @override
  Widget build(BuildContext context) {
    final TextStyle? nameStyle = Theme.of(context).textTheme.caption;
    final TextStyle? subtitleStyle = Theme.of(context).textTheme.subtitle1;
    var numberFormat = NumberFormat('###.##', 'en_US');

    return Bounce(
      duration: Duration(milliseconds: 100),
      onPressed: () {
        print('on press ${widget.operationUnit.uid}');

        // String uri = '/device/${widget.operationUnit.uid}';
        //
        // print('${uri} pressed...');
        // Navigator.pushNamed(context, uri, arguments: widget.operationUnit);

      },
      child: Tooltip(
        message: '${widget.operationUnit.uid}\n${widget.operationUnit.status}' ,
        child: Container(
          width: 250,
          height: 280,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0, left: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, right: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${(widget.operationUnit.name != '') ? widget.operationUnit.name : widget.operationUnit.uid}',
                          style: nameStyle,
                        ),
                        Text('${globals.getTimeCard(widget.operationUnit.updatedWhen)}',
                          style: subtitleStyle,
                        ),
                        Text('${globals.getDateCard(widget.operationUnit.updatedWhen)}',
                          style: subtitleStyle,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Container(
                      // color: Colors.black,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10.0),
                          bottomRight: Radius.circular(10.0),
                        ), 
                        color: const Color(0xff187a7d),
                        // border: Border.all(
                        //     width: 1.0, color: const Color(0xff707070)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text('System: ${calculateActiveStatus(widget.operationUnit.updatedWhen, 5)}', style: TextStyle(fontSize: 2 * (displayHeight(context) * 0.01), color: Colors.white, fontFamily: 'Kanit', fontWeight: FontWeight.w400), textAlign: TextAlign.center,),
                          Divider(
                            color: const Color(0xffe30707), //.withOpacity(0.2),
                            thickness: 1,
                            // width: 10,
                            height: 1,
                            indent: 2,
                            endIndent: 2,
                          ),
                          Text('Relay: ${widget.operationUnit.status}', style: TextStyle(fontSize: 2 * (displayHeight(context) * 0.01), color: Colors.white, fontFamily: 'Kanit', fontWeight: FontWeight.w400), textAlign: TextAlign.center,),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String calculateActiveStatus(String updatedWhen, int pulseLimit) {
  String result = 'offline';

  if(updatedWhen != '') {
    var dtNow = DateTime.now();
    var dtUpdatedWhen = DateTime.parse(updatedWhen);
    Duration diff = dtNow.difference(dtUpdatedWhen);
    if(diff.inMinutes >= pulseLimit) {
      result = 'offline';
    } else {
      result = 'online';
    }
  }

  return result;
}

class OperationUnitListWidget extends StatefulWidget {
  const OperationUnitListWidget({
    Key? key,
    required this.user,
    required this.sensorUid,
    required this.operationUnitLists,

  }) : super(key: key);

  final String? user;
  final String sensorUid;
  final List<OperationUnit> operationUnitLists;

  @override
  _OperationUnitListWidgetState createState() => _OperationUnitListWidgetState();


}
class _OperationUnitListWidgetState extends State<OperationUnitListWidget> {
  List<OperationUnit> tempOperationUnitLists = [];

  bool isSelectionMode = false;
  List<Map> staticData = MyData.data;
  Map<int, bool> selectedFlag = {};

  @override
  void initState() {
    context.read<TempOperationUnitList>().copy(widget.operationUnitLists);

    //--------------------------

    tempOperationUnitLists.clear();

    widget.operationUnitLists.forEach((values) {
      // Display only none user and user owned device list
      if(values.user == '' || values.user == widget.user) {
        tempOperationUnitLists.add(OperationUnit(
          id: values.id ?? '',
          uid: values.uid ?? '',
          index: int.parse('${values.index ?? "0"}'),
          name: values.name ?? '',
          status: values.status ?? '',
          user: values.user ?? '',
          sensor: values.sensor ?? '',
          updatedWhen: values.updatedWhen ?? '2022-10-11 14:43:00',
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    // tempOperationUnitLists = []..addAll(widget.operationUnitLists);

    return Container(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemBuilder: (builder, index) {
          Map data = staticData[index];

          selectedFlag[index] = selectedFlag[index] ?? false;
          bool? isSelected = selectedFlag[index];
          return ListTile(
            // onLongPress: () => onLongPress(isSelected!, index),
            // onTap: () => onTap(isSelected!, index),
            // onTap: () => onTap(tempOperationUnitLists[index].sensor != '' ?? false, index),
              onTap: () => onTap((tempOperationUnitLists[index].sensor != '') && (tempOperationUnitLists[index].sensor == widget.sensorUid) ?? false, index),

            title: Text("${tempOperationUnitLists[index].uid}"),
            subtitle: Text("${tempOperationUnitLists[index].name}|${tempOperationUnitLists[index].sensor}|${(tempOperationUnitLists[index].sensor != '') && (tempOperationUnitLists[index].sensor == widget.sensorUid)}"),
            // leading: _buildSelectIcon(isSelected!, data),
            // leading: _buildSelectIcon(isSelected!, widget.operationUnitLists[index].uid),
            // leading: _buildSelectIcon(tempOperationUnitLists[index].sensor != '' ?? false, tempOperationUnitLists[index].uid),
            leading: _buildSelectIcon((tempOperationUnitLists[index].sensor != '') && (tempOperationUnitLists[index].sensor == widget.sensorUid) ?? false, tempOperationUnitLists[index].uid),
          );
        },
        // itemCount: staticData.length,
        itemCount: tempOperationUnitLists.length,
      ),
    );
  }
  void onTap(bool isSelected, int index) {
    // if (isSelectionMode) {
      setState(() {
        selectedFlag[index] = !isSelected;
        isSelectionMode = selectedFlag.containsValue(true);
        if(!isSelected) {
          tempOperationUnitLists[index].sensor = widget.sensorUid;

          // Provider.of<TempOperationUnitList>(context, listen: false).updateSensor(index, widget.sensorUid);
          context.read<TempOperationUnitList>().updateSensor(index, widget.sensorUid);
        } else {
          tempOperationUnitLists[index].sensor = '';
          context.read<TempOperationUnitList>().updateSensor(index, '');

        }
      });
    // } else {
    //   // Open Detail Page
    // }
  }
  void onLongPress(bool isSelected, int index) {
    setState(() {
      selectedFlag[index] = !isSelected;
      isSelectionMode = selectedFlag.containsValue(true);
    });
  }
  // Widget _buildSelectIcon(bool isSelected, Map data) {
  Widget _buildSelectIcon(bool isSelected, String data) {
    // if (isSelectionMode) {
      return Icon(
        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
        color: Theme.of(context).primaryColor,
      );
    // } else {
    //   return CircleAvatar(
    //     child: Text('$data}'),
    //   );
    // }
  }
  Widget? _buildSelectAllButton() {
    bool isFalseAvailable = selectedFlag.containsValue(false);
    if (isSelectionMode) {
      return FloatingActionButton(
        onPressed: _selectAll,
        child: Icon(
          isFalseAvailable ? Icons.done_all : Icons.remove_done,
        ),
      );
    } else {
      return null;
    }
  }
  void _selectAll() {
    bool isFalseAvailable = selectedFlag.containsValue(false);
    // If false will be available then it will select all the checkbox
    // If there will be no false then it will de-select all
    selectedFlag.updateAll((key, value) => isFalseAvailable);
    setState(() {
      isSelectionMode = selectedFlag.containsValue(true);
    });
  }
}

class TestListChecked extends StatefulWidget {
  @override
  _TestListCheckedState createState() => _TestListCheckedState();
}
class _TestListCheckedState extends State<TestListChecked> {
  bool isSelectionMode = false;
  List<Map> staticData = MyData.data;
  Map<int, bool> selectedFlag = {};
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemBuilder: (builder, index) {
          Map data = staticData[index];
          selectedFlag[index] = selectedFlag[index] ?? false;
          bool? isSelected = selectedFlag[index];
          return ListTile(
            onLongPress: () => onLongPress(isSelected!, index),
            onTap: () => onTap(isSelected!, index),
            title: Text("${data['name']}"),
            subtitle: Text("${data['email']}"),
            leading: _buildSelectIcon(isSelected!, data),
          );
        },
        itemCount: staticData.length,
      ),
    );
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text('Select Item'),
    //   ),
    //   body: ListView.builder(
    //     itemBuilder: (builder, index) {
    //       Map data = staticData[index];
    //       selectedFlag[index] = selectedFlag[index] ?? false;
    //       bool? isSelected = selectedFlag[index];
    //       return ListTile(
    //         onLongPress: () => onLongPress(isSelected!, index),
    //         onTap: () => onTap(isSelected!, index),
    //         title: Text("${data['name']}"),
    //         subtitle: Text("${data['email']}"),
    //         leading: _buildSelectIcon(isSelected!, data),
    //       );
    //     },
    //     itemCount: staticData.length,
    //   ),
    //   floatingActionButton: _buildSelectAllButton(),
    // );
  }
  void onTap(bool isSelected, int index) {
    if (isSelectionMode) {
      setState(() {
        selectedFlag[index] = !isSelected;
        isSelectionMode = selectedFlag.containsValue(true);
      });
    } else {
      // Open Detail Page
    }
  }
  void onLongPress(bool isSelected, int index) {
    setState(() {
      selectedFlag[index] = !isSelected;
      isSelectionMode = selectedFlag.containsValue(true);
    });
  }
  Widget _buildSelectIcon(bool isSelected, Map data) {
    if (isSelectionMode) {
      return Icon(
        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
        color: Theme.of(context).primaryColor,
      );
    } else {
      return CircleAvatar(
        child: Text('${data['id']}'),
      );
    }
  }
  Widget? _buildSelectAllButton() {
    bool isFalseAvailable = selectedFlag.containsValue(false);
    if (isSelectionMode) {
      return FloatingActionButton(
        onPressed: _selectAll,
        child: Icon(
          isFalseAvailable ? Icons.done_all : Icons.remove_done,
        ),
      );
    } else {
      return null;
    }
  }
  void _selectAll() {
    bool isFalseAvailable = selectedFlag.containsValue(false);
    // If false will be available then it will select all the checkbox
    // If there will be no false then it will de-select all
    selectedFlag.updateAll((key, value) => isFalseAvailable);
    setState(() {
      isSelectionMode = selectedFlag.containsValue(true);
    });
  }
}

class OperatedLineChartWidget extends StatefulWidget {
  const OperatedLineChartWidget({Key? key,
    required this.operationDeviceId
  }) : super(key: key);

  final String operationDeviceId;

  @override
  State<OperatedLineChartWidget> createState() => _OperatedLineChartWidgetState();
}

class _OperatedLineChartWidgetState extends State<OperatedLineChartWidget> {

  final operatedPoints = <FlSpot>[];

  List<OperatedLog> operatedLogs = [];
  List<String> dateTimeValues = <String>[];

  double xValue = 0;
  double step = 1; // original 0.05;
  final Color readOperatedLogColor = Colors.deepOrangeAccent;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    operatedPoints.add(FlSpot(xValue, 0));
    dateTimeValues.add('_');

    xValue += step;

    // getLast10OperatedLogs();
  }

  // @override
  // void afterFirstLayout(BuildContext context) {
  //   getLast10OperatedLogs();
  // }

  @override
  Widget build(BuildContext context) {
    var operatedLogsRef = FirebaseDatabase.instance
        .ref()
        .child('logs/${widget.operationDeviceId}')
        // .orderByKey()
        // .orderByChild('updatedWhen')
        .limitToLast(50); // monitor previous 12hours
        // .get();
    // return drawOperatedLineChart();
    return StreamBuilder(
        stream: operatedLogsRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapOperatedLog) {
          if (snapOperatedLog.hasData && snapOperatedLog.data!.snapshot.exists && !snapOperatedLog.hasError) {
            if (snapOperatedLog.data!.snapshot.value != null) {
              // print('snapOperatedLog.data!.snapshot.value is not null!!');

              operatedPoints.clear();
              operatedLogs.clear();
              dateTimeValues.clear();

              xValue = 0;

              Map<dynamic, dynamic> values = snapOperatedLog.data!.snapshot.value as Map;
              // print('snapOperatedLog size=${values.length}');

              values!.forEach((key, operatedLogValues) {
                // print('\nkey=${key}');
                // print('mqttMsg=[${operatedLogValues['mqttMsg']}]');
                // print('substring(0, 1)=${operatedLogValues['mqttMsg'].toString().substring(0, 1)}');
                // print('parseDouble=${globals.parseDouble(operatedLogValues['mqttMsg'].toString().substring(0, 1) ?? 0)}');
                // print('parse Double=${double.parse(operatedLogValues['mqttMsg'].toString().substring(0, 1))}');

                operatedLogs.add(OperatedLog(
                  uid: operatedLogValues['uid'] ?? '',

                  mqttMsg: operatedLogValues['mqttMsg'] ?? '',
                  updatedWhen: operatedLogValues['updatedWhen'] ?? '2022-11-11 11:11:11',
                ));
              });

              // Sort the list based on the 'name' property in ascending order
              operatedLogs.sort((a, b) => a.updatedWhen.compareTo(b.updatedWhen));

              // Access the sorted list
              for (var operatedLog in operatedLogs) {
                // print('${operatedLog.updatedWhen} (${operatedLog.updatedWhen})');

                String rawNumberString = operatedLog.mqttMsg.substring(0, 1);
                double y_number = 0.0;
                try {
                  y_number = double.parse(rawNumberString);
                  // print(y_number);
                } catch (e) {
                  print("Invalid number format");
                }

                // operatedPoints.add(FlSpot(xValue, globals.parseDouble(operatedLogValues['mqttMsg'].toString().substring(0, 1) ?? 0)));
                operatedPoints.add(FlSpot(xValue, y_number));
                dateTimeValues.add(operatedLog.updatedWhen ?? '');

                xValue += step;

              }

              // operatedPoints.sort((a, b) => a.x.compareTo(b.x));
              // dateTimeValues.sort((a, b) => a.compareTo(b));

            } else {
              operatedLogs.clear();
              operatedPoints.add(FlSpot(xValue, 0));
              dateTimeValues.add('_');
              print('snapOperatedLog.data!.snapshot.value is null!!');
            }
          } else {
            operatedLogs.clear();
            operatedPoints.add(FlSpot(xValue, 0));
            dateTimeValues.add('_');
            print('No data available.');
          }

          // Start Draw UI
          return drawOperatedLineChart();
        });

  }

  Widget drawOperatedLineChart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 2,
            right: 2,
          ),
          // child: LineChartSample10(),
          child: SizedBox(
            width: displayWidth(context) * 0.6,
            height: 150,
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(
                    show: true,
                    border:
                    Border.all(color: const Color(0xff37434d), width: 1)),
                minY: 0, // min x
                maxY: 10, // max y
                minX: operatedPoints.first.x,
                maxX: operatedPoints.last.x,
                // lineTouchData: LineTouchData(enabled: true),
                lineTouchData: lineTouchDataOperatedLog,
                clipData: FlClipData.all(),
                // gridData: FlGridData(
                //   show: true,
                //   drawVerticalLine: false,
                // ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xffb9c4c9),
                      strokeWidth: 0.5,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: const Color(0xffb9c4c9),
                      strokeWidth: 0.5,
                    );
                  },
                ),
                lineBarsData: [
                  readOperatedLogLine(operatedPoints),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      // reservedSize: 38,
                    ),
                  ),
                  bottomTitles: AxisTitles(

                    sideTitles: SideTitles(
                      showTitles: false,

                      // reservedSize: 38,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Indicator(
              color: Colors.deepOrangeAccent,
              text: 'Operated',
              isSquare: true,
            ),
            SizedBox(
              height: 18,
            ),
          ],
        ),
      ],
    );
  }

  String getStatusToDisplay(double statusCode) {
    String result = 'Off';
    switch(statusCode) {
      case 0: {
        result = 'Off';
        break;
      }
      case 1: {
        result = 'On';
        break;
      }
      case 7: {
        result = 'Reboot continue on';
        break;
      }
      case 8: {
        result = 'Reboot continue off';
        break;
      }
    }
    return result;
  }

  LineTouchData get lineTouchDataOperatedLog => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
          // print('touchedBarSpots.length=${touchedBarSpots.length}');
          // print('touchedBarSpots.toString=${touchedBarSpots.toString()}');

          return touchedBarSpots.map((barSpot) {
            print('barSpot.barIndex=${barSpot.barIndex}');
            print('barSpot.spotIndex=${barSpot.spotIndex}');
            final flSpot = barSpot;
            // if (flSpot.x == 0 || flSpot.x == 6) {
            //   return null;
            // }
            if (flSpot.x == 0) {
              return null;
            }

            // TextAlign textAlign;
            // switch (flSpot.x.toInt()) {
            //   case 1:
            //     textAlign = TextAlign.left;
            //     break;
            //   case 5:
            //     textAlign = TextAlign.right;
            //     break;
            //   default:
            //     textAlign = TextAlign.center;
            // }
            TextAlign textAlign = TextAlign.center;
            String dateTimeString = '';
            if (barSpot.barIndex == 0) {
              dateTimeString = '${dateTimeValues[flSpot.x.toInt()].toString()}\n';
            }
            // print('dateTimeString=${dateTimeString}');

            return LineTooltipItem(
              // '${widget.weekDays[flSpot.x.toInt()]} \n',
              // '${dateTimeString}${flSpot.y.toString()}',
              '${dateTimeString}',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: getStatusToDisplay(flSpot.y),
                  style: TextStyle(
                    color: Colors.grey[100],
                    fontWeight: FontWeight.normal,
                  ),
                ),
                // const TextSpan(
                //   text: ' k ',
                //   style: TextStyle(
                //     fontStyle: FontStyle.italic,
                //     fontWeight: FontWeight.normal,
                //   ),
                // ),
                // const TextSpan(
                //   text: 'calories',
                //   style: TextStyle(
                //     fontWeight: FontWeight.normal,
                //   ),
                // ),
              ],
              textAlign: textAlign,
            );
          }).toList();
        }),
    // touchCallback:
    //     (FlTouchEvent event, LineTouchResponse? lineTouch) {
    //   if (!event.isInterestedForInteractions ||
    //       lineTouch == null ||
    //       lineTouch.lineBarSpots == null) {
    //     setState(() {
    //       touchedValue = -1;
    //     });
    //     return;
    //   }
    //   final value = lineTouch.lineBarSpots![0].x;
    //
    //   if (value == 0 || value == 6) {
    //     setState(() {
    //       touchedValue = -1;
    //     });
    //     return;
    //   }
    //
    //   setState(() {
    //     touchedValue = value;
    //   });
    // }
  );

  Future<List<OperatedLog>> getLast10OperatedLogs() async {
    final operatedLogsSnapshot = await FirebaseDatabase.instance
        .ref()
        .child('logs/${widget.operationDeviceId}')
        .orderByKey()
        .limitToLast(10)
        .get();

    print(operatedLogsSnapshot); // to debug and see if data is returned

    List<OperatedLog> operatedLogs = [];

    if (operatedLogsSnapshot.exists) {
      operatedLogs.clear();
      dateTimeValues.clear();

      print(operatedLogsSnapshot.value);
      Map<dynamic, dynamic>? values = operatedLogsSnapshot.value as Map?;

      values!.forEach((key, operatedLogValues) {
        print('\nkey=${key}');
        print('mqttMsg=[${operatedLogValues['mqttMsg']}]');
        print('substring(0, 1)=${operatedLogValues['mqttMsg'].toString().substring(0, 1)}');

        operatedPoints.add(FlSpot(
            xValue, globals.parseDouble(operatedLogValues['mqttMsg'].toString().substring(0, 1) ?? 0)));
        dateTimeValues.add(operatedLogValues['uid'] ?? '');

        xValue += step;

        operatedLogs.add(OperatedLog(
          uid: operatedLogValues['uid'] ?? '',

          mqttMsg: operatedLogValues['mqttMsg'] ?? '',
          updatedWhen: values['updatedWhen'] ?? '2022-11-11 11:11:11',
        ));
      });

      operatedPoints.sort((a, b) => a.x.compareTo(b.x));
      dateTimeValues.sort((a, b) => a.compareTo(b));
    } else {
      operatedLogs.clear();
      operatedPoints.add(FlSpot(xValue, 0));
      dateTimeValues.add('_');
      print('No data available.');


      xValue += step;

      operatedLogs.add(OperatedLog(
        // no data
        uid: '',
        mqttMsg: '',
        updatedWhen: '',
      ));
    }

    return operatedLogs;
  }

  LineChartBarData readOperatedLogLine(List<FlSpot> points) {
    return LineChartBarData(
      spots: points,
      dotData: FlDotData(
        show: false,
      ),
      gradient: LinearGradient(
          colors: [readOperatedLogColor.withOpacity(0), readOperatedLogColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.1, 1.0]),
      barWidth: 4,
      isCurved: false,
    );
  }
}
