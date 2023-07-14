// import 'package:adobe_xd/pinned.dart';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import 'package:iot_theapp_web/globals.dart' as globals;
import 'package:iot_theapp_web/main.dart';
import 'package:iot_theapp_web/pages/device/model/device.dart';
import 'package:iot_theapp_web/pages/device/model/operation_unit.dart';
import 'package:iot_theapp_web/utils/constants.dart';


import 'package:intl/intl.dart';
import 'package:iot_theapp_web/utils/sizes_helpers.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:unique_identifier/unique_identifier.dart';

import '../../../objectbox/user.dart';

final client = MqttServerClient('broker.hivemq.com', '');

var pongCount = 0; // Pong counter

class DevicesList extends StatefulWidget {
  @override
  _DevicesListState createState() => _DevicesListState();
}

class _DevicesListState extends State<DevicesList> {

  int? userId;
  User? user;

  String g_platform_mac_address = 'Unknown';


  // List<Map<dynamic, String>> lists = [];
  // List<String> lists = [];
  List<Device> devicetheSensorLists = [];
  List<OperationUnit> devicethePumpLists = [];

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
    // TODO: implement initState
    super.initState();
    initUniqueIdentifierState(); // get theApp's device mac address

    if(objectbox.userBox.isEmpty()) {
      print('**** none user');

      print('**** then add demo one.');
      user = User();
      user?.userName = 'demo';
      user?.password = '';
      user?.isServer = false;
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

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      // do something
      print("Build Completed");
      if(user!.isServer!) {
        callMQTTSubscribe();
      }
    });

  }

  Future<void> callMQTTSubscribe() async {
    // 1) prepare theSensor device data to subscribe MQTT.
    final dbtheSensorRef = FirebaseDatabase.instance.ref();
    if(user!.userName!.isNotEmpty && user!.userName != '') {

      final theSensorsSnapshot = await dbtheSensorRef.child("users/${user!.userName}/devices")
          .get();
      List<Device> theSensorDevices = [];
      if (theSensorsSnapshot.exists) {
        theSensorDevices.clear();

        print(theSensorsSnapshot.value);
        Map<dynamic, dynamic>? values = theSensorsSnapshot.value as Map?;

        values!.forEach((key, sensorDeviceValues) {
          print('key=${key}');
          print('uid=[${sensorDeviceValues['uid']}]');

          theSensorDevices.add(Device(
            uid: sensorDeviceValues['uid'] ?? '',
            updatedWhen: values['updatedWhen'] ?? '2021-05-04 19:03:25',

          ));
        });

        // 2) use those sensor uid to subscribe after page builded.
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
              'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
          client.disconnect();
          exit(-1);
        }

        print('\n\n');
        theSensorDevices.forEach((sensorDevice) async {
          print('->uid=${sensorDevice.uid}');

          /// Ok, lets try a subscription
          print('EXAMPLE::Subscribing to the test/lol topic');
          // // const topic = 'test/lol'; // Not a wildcard topic
          // const topic = 'watersupply/gundam/pump/84:CC:A8:88:6E:07/status'; // Not a wildcard topic
          // String topic_thePump = 'watersupply/gundam/pump/84:CC:A8:88:6E:07/status'; // Not a wildcard topic
          String topic_thePump = 'watersupply/${user!.userName}/pump/${sensorDevice.uid}/status';
          print('Selected device will subscribing to the ${topic_thePump} topic');

          // client.subscribe(topic, MqttQos.atMostOnce);
          client.subscribe(topic_thePump, MqttQos.exactlyOnce);

          //String topic_theSensor = watersupply/gundam/sedimentation/84:CC:A8:88:6E:07/waterlevel/status
          String topic_theSensor = 'watersupply/${user!.userName}/sedimentation/${sensorDevice.uid}/waterlevel/status';
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

                String historyPath = "devices/${imei_uid}/${imei_uid}_history/${currentDateTimeStr}";
                print('historyPath=${historyPath}');

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

                DatabaseReference ref_thePump = FirebaseDatabase.instance.ref("devices/$imei_uid");

                await ref_thePump.update({
                  "status": relay_status,
                  // "updatedWhen": updated_status_datetime,
                  "updatedWhen": currentDateTimeStr,
                }).then((value) => () async {
                  print('');
                  print('Updated devices/$imei_uid  status: $relay_status is success.');
                  print('');



                });

                print('add new history of [${historyPath}]');
                DatabaseReference ref_thePump_History = FirebaseDatabase.instance.ref(historyPath);
                await ref_thePump_History.update({
                  "uid": currentDateTimeStr,
                  "status": relay_status,
                  "updatedWhen": currentDateTimeStr,
                }).then((value) => () {
                  print('');
                  print('Updated history [${historyPath}] status: $relay_status is success.');
                  print('');

                }).onError((error, stackTrace) => () {
                  print('');
                  print('Updated devices/$imei_uid  status: $relay_status is failed.');
                  print('');
                });
                //     .onError((error, stackTrace) => () {
                //   print('');
                //   print('Updated devices/$imei_uid  status: $relay_status is failed.');
                //   print('');
                //
                // });

              } else {
                print('No payload data...');
              }
            }
          });


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

    } // if - user
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
      if(user!.isServer!) {
        // re subscribe mqtt
        callMQTTSubscribe();
      }
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
    final dbtheSensorRef = FirebaseDatabase.instance.ref().child("users/${user!.userName}/devices");
    final dbthePumpRef = FirebaseDatabase.instance.ref().child("devices");

    return StreamBuilder(
          stream: dbtheSensorRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot_theSensors) {
            if(snapshot_theSensors.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(
                backgroundColor: Colors.amberAccent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                strokeWidth: 3,
              );
            }
            if (snapshot_theSensors.hasData && snapshot_theSensors.data!.snapshot.exists && !snapshot_theSensors.hasError) {
              devicetheSensorLists.clear();
              Map<dynamic, dynamic> values = snapshot_theSensors.data!.snapshot.value as Map;
              values.forEach((key, values) {
                // print('key=${key}');
                // print('wRangeDistance=[${values['wRangeDistance']}]');
                // print('wCapacity=[${values['wCapacity']}]');
                // print('wOffset=[${values['wOffset']}]');
                // print('temperature=[${values['temperature']}]');
                // print('parseDouble temperature=[${globals.parseDouble(values['temperature'])}]');
                //
                // print('notification=${values['notification']}');

                devicetheSensorLists.add(Device(
                  id: values['id'] ?? '',
                  uid: values['uid'] ?? '',
                  // index: int.parse(values['index'].toString() ?? '-1'),
                  index: int.parse('${values['index'] ?? "0"}'),
                  name: values['name'] ?? '',
                  mode: values['mode'] ?? Constants.MODE_AUTO,
                  localip: values['localip'] ?? '',
                  updatedWhen: values['updatedWhen'] ?? '2021-05-04 19:03:25',
                  readingInterval: values['readingInterval'] ?? 10000,
                  humidity: globals.parseDouble(values['humidity']),
                  temperature: globals.parseDouble(values['temperature'] ?? 0),
                  readVoltage: globals.parseDouble(values['readVoltage'] ?? 0),

                  notifyHumidLower: globals.parseDouble(values['notifyHumidLower'] ?? 0),
                  notifyHumidHigher: globals.parseDouble(values['notifyHumidHigher'] ?? 0),
                  notifyTempLower: globals.parseDouble(values['notifyTempLower'] ?? 0),
                  notifyTempHigher: globals.parseDouble(values['notifyTempHigher'] ?? 0),
                  notifyEmail: values['notifyEmail'] ?? '',

                  wTankType: values['wTankType'] ?? '',
                  wRangeDistance: globals.parseDouble(values['wRangeDistance'] ?? 0),
                  wCapacity: globals.parseDouble(values['wCapacity'] ?? 0),
                  wOffset: globals.parseDouble(values['wOffset'] ?? 0),
                  wFilledDepth: globals.parseDouble(values['wFilledDepth'] ?? 0),
                  wHeight: globals.parseDouble(values['wHeight'] ?? 0),
                  wWidth: globals.parseDouble(values['wWidth'] ?? 0),
                  wDiameter: globals.parseDouble(values['wDiameter'] ?? 0),
                  wSideLength: globals.parseDouble(values['wSideLength'] ?? 0),
                  wLength: globals.parseDouble(values['wLength'] ?? 0),

                ));
              });

              // print('**device lists all=${devicetheSensorLists.toString()}');

              return StreamBuilder(
                stream: dbthePumpRef.onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshotthePump) {
                  if(snapshotthePump.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(
                      backgroundColor: Colors.amberAccent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                      strokeWidth: 3,
                    );
                  }

                  if (snapshotthePump.hasData && snapshotthePump.data!.snapshot.exists && !snapshotthePump.hasError) {
                    devicethePumpLists.clear();

                    Map<dynamic, dynamic> valuesthePump = snapshotthePump.data!.snapshot.value as Map;
                    valuesthePump.forEach((key, thePumpValue) {
                      // print('key=${key}');
                      // print('uid=[${thePumpValue['uid']}]');
                      // print('name=[${thePumpValue['name']}]');
                      // print('sensor=[${thePumpValue['sensor']}]');
                      // print('status=[${thePumpValue['status']}]');
                      // print('updatedWhen=[${thePumpValue['updatedWhen']}]');
                      // print('user=[${thePumpValue['user']}]');

                      devicethePumpLists.add(OperationUnit(
                        uid: thePumpValue['uid'] ?? '',
                        name: thePumpValue['name'] ?? '',
                        sensor: thePumpValue['sensor'] ?? '',
                        status: thePumpValue['status'] ?? '',
                        updatedWhen: thePumpValue['updatedWhen'] ?? '2021-05-04 19:03:25',
                        user: thePumpValue['user'] ?? '',
                      ));
                    });

                    // print('**thePump device lists all=${devicethePumpLists.toString()}');

                    return Expanded(
                      child: ListView.builder(
                        itemCount: devicetheSensorLists.length,
                        itemBuilder: (context, index) {
                          return DeviceCard(device: devicetheSensorLists[index], pumpStatus: getPumpStatus(devicetheSensorLists[index]),);
                          // return ListTile(
                          //   title: Text('Item ${index + 1}'),
                          // );
                        },
                      ),
                    );
                  } else {
                    return Column(
                      // mainAxisSize: MainAxisSize.min,
                      // mainAxisAlignment: MainAxisAlignment.center,
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          backgroundColor: Colors.amberAccent,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                          strokeWidth: 3,
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Text('Device data not found under user \"${user!.userName}\".'),
                        Text('Please add a new device or change the user name.'),
                      ],
                    );
                  }
                }
                );
            } else {
              return Column(
                // mainAxisSize: MainAxisSize.min,
                // mainAxisAlignment: MainAxisAlignment.center,
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 16,
                  ),
                  Text('Device data not found under user \"${user!.userName}\".'),
                  Text('Please add a new device or change the user name.'),
                ],
              );
            }
            return CircularProgressIndicator();
          },
    );

  }

  /**
   * Get the latest thePump status by sensor uid.
   */
  String getPumpStatus(Device sensor) {
    String result = '';
    devicethePumpLists.forEach((element) {
      if(element.sensor == sensor.uid) {
        // result = updateConsoleStatus(element.updatedWhen, sensor);
        result = element.status;
      }
    });
    return result;
  }

  /**
   * Update console status when device status has been updated.
   */
  String updateConsoleStatus(String consoleUpdatedWhen, Device sensor) {
    String result = '...';
    String currentDateStr = DateFormat("yyyy-MM-dd").format(DateTime.now());
    String currentTimeStr = DateFormat("HH:mm:ss").format(DateTime.now());
    String currentDateTimeStr = '$currentDateStr $currentTimeStr';

    if(consoleUpdatedWhen == '2022-11-11 11:11:11') {
      return result;
    }

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
      } else if(diff.inMinutes.abs() > ((sensor.readingInterval / 60000) * 2)) { // plus double inverval for check thePump lost connect
        result = 'Lost connect!';
        // setState(() {
        //   mSensorOperationUnit.status = 'Overtime';
        // });
        return result;
      } else {
        result = 'Normal';
        return result;
      }

    }

    if(dt1.compareTo(dt2) > 0){
      // print("DT1 is after DT2");
      // result = 'Pump lost connect!';
      result = 'Normal';
      return result;
    }

    return result;
  }
}

class DeviceCard extends StatefulWidget {
  const DeviceCard({
    Key? key,
    required this.device,
    required this.pumpStatus,
  }) : super(key: key);

  final Device device;
  final String pumpStatus;

  @override
  _DeviceCardState createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  @override
  Widget build(BuildContext context) {
    final TextStyle? nameStyle = Theme.of(context).textTheme.caption;
    final TextStyle? subtitleStyle = Theme.of(context).textTheme.subtitle1;
    final TextStyle? numberStyle = Theme.of(context).textTheme.headline3;
    var numberFormat = NumberFormat('###.##', 'en_US');
    var voltageFormat = NumberFormat('###.0#', 'en_US');
    return Bounce(
      duration: Duration(milliseconds: 100),
      onPressed: () {
        print('on press ${widget.device.uid}');

        String uri = '/device/${widget.device.uid}';

        print('${uri} pressed...');
        Navigator.pushNamed(context, uri, arguments: widget.device);

      },
      child: Tooltip(
        message: '${widget.device.uid}\n${widget.device.localip}\n${widget.device.readVoltage}\n${widget.device.humidity}\n${widget.device.temperature}' ,
        child: Container(
          // width: 250,
          height: 96,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(top: 0.0, left: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0, right: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${widget.device.name}',
                            style: nameStyle,
                          ),
                          Text('${globals.getTimeCard(widget.device.updatedWhen)}',
                            style: subtitleStyle,
                          ),
                          Text('${globals.getDateCard(widget.device.updatedWhen)}',
                            style: subtitleStyle,
                          ),
                          // Text('${widget.device.wRangeDistance} mm',
                          //   style: subtitleStyle,
                          // ),
                          // Text('${widget.device.readVoltage} volt',
                          //   style: subtitleStyle,
                          // ),
                        ],
                      ),
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
                        color: const Color(0xff070707),
                        // border: Border.all(
                        //     width: 1.0, color: const Color(0xff707070)),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            // Text('${numberFormat.format(widget.device.temperature)} \u2103', style: TextStyle(fontSize: 2 * (displayHeight(context) * 0.01), color: Colors.white, fontFamily: 'Kanit', fontWeight: FontWeight.w400), textAlign: TextAlign.center,),
                            Text('Sensor read: ${numberFormat.format((widget.device.wRangeDistance > 0) ? widget.device.wRangeDistance / 10 : 0)}cm', style: TextStyle(fontSize: 2 * (displayHeight(context) * 0.01), color: Colors.white, fontFamily: 'Kanit', fontWeight: FontWeight.w400), textAlign: TextAlign.center,),
                            Divider(
                              color: Colors.cyanAccent, //.withOpacity(0.2),
                              thickness: 1,
                              // width: 10,
                              height: 1,
                              indent: 2,
                              endIndent: 2,
                            ),
                            // Text('${numberFormat.format(widget.device.humidity)} %', style: TextStyle(fontSize: 2 * (displayHeight(context) * 0.01), color: Colors.white, fontFamily: 'Kanit', fontWeight: FontWeight.w400), textAlign: TextAlign.center,),
                            // Text('${numberFormat.format(widget.device.wHeight)}cm', style: TextStyle(fontSize: 2 * (displayHeight(context) * 0.01), color: Colors.white, fontFamily: 'Kanit', fontWeight: FontWeight.w400), textAlign: TextAlign.center,),
                            Text('Pump relay: ${widget.pumpStatus}', style: TextStyle(fontSize: 2 * (displayHeight(context) * 0.01), color: updateConsoleStatusFontColor(widget.pumpStatus), fontFamily: 'Kanit', fontWeight: FontWeight.w400), textAlign: TextAlign.center,),


                            // devicethePumpLists
                          ],
                      ),
                    ),
                  ),
                  // Stack(
                  //
                  // //   fit: StackFit.passthrough,
                  // //   // clipBehavior: Clip.hardEdge,
                  //   children: [
                  //     // SizedBox.expand(
                  //     //   child: Container(
                  //     //     // padding: EdgeInsets.all(0.0),
                  //     //     // color: Colors.red,
                  //     //     width: double.infinity,
                  //     //     constraints: BoxConstraints(maxHeight: 250),
                  //     //     decoration: BoxDecoration(
                  //     //
                  //     //       borderRadius: BorderRadius.only(
                  //     //         topRight: Radius.circular(10.0),
                  //     //         bottomRight: Radius.circular(10.0),
                  //     //       ),
                  //     //       color: const Color(0xff070707),
                  //     //       // border: Border.all(
                  //     //       //     width: 1.0, color: const Color(0xff707070)),
                  //     //     ),
                  //     //
                  //     //     // child: Text('xxx'),
                  //     //   ),
                  //     // ),
                  //     // Positioned(
                  //     //   // left: 10,
                  //     //   child: Container(
                  //     //     // padding: EdgeInsets.all(0.0),
                  //     //     // color: Colors.red,
                  //     //     width: double.infinity,
                  //     //     constraints: BoxConstraints(maxHeight: 250),
                  //     //     decoration: BoxDecoration(
                  //     //
                  //     //       borderRadius: BorderRadius.only(
                  //     //         topRight: Radius.circular(10.0),
                  //     //         bottomRight: Radius.circular(10.0),
                  //     //       ),
                  //     //       color: const Color(0xff070707),
                  //     //       // border: Border.all(
                  //     //       //     width: 1.0, color: const Color(0xff707070)),
                  //     //     ),
                  //     //
                  //     //     // child: Text('xxx'),
                  //     //   ),
                  //     // ),
                  // //     // Column(
                  // //     //     crossAxisAlignment: CrossAxisAlignment.start,
                  // //     //     mainAxisAlignment: MainAxisAlignment.start,
                  // //     //     mainAxisSize: MainAxisSize.min,
                  // //     //     children: [
                  // //     //       Text('${numberFormat.format(widget.device.humidity)} \u2103', style: numberStyle, textAlign: TextAlign.center,),
                  // //     //       Text('${numberFormat.format(widget.device.temperature)} %', style: numberStyle, textAlign: TextAlign.center,),
                  // //     //     ],
                  // //     // ),
                  // //     Container(
                  // //       color: Colors.red,
                  // //
                  // //       child: Text('xxx'),
                  // //     ),
                  // //     // Container(
                  // //     //   color: Colors.black,
                  // //     //   // decoration: BoxDecoration(
                  // //     //   //   borderRadius: BorderRadius.only(
                  // //     //   //     topRight: Radius.circular(15.0),
                  // //     //   //     bottomRight: Radius.circular(15.0),
                  // //     //   //   ),
                  // //     //   //   color: const Color(0xff070707),
                  // //     //   //   // border: Border.all(
                  // //     //   //   //     width: 1.0, color: const Color(0xff707070)),
                  // //     //   // ),
                  // //     // ),
                  //   ]
                  // ),
                ],
              ),


              // ========================
              // child: Pinned.fromPins(
              //   Pin(size: 123.0, end: 35.0),
              //   Pin(size: 70.0, middle: 0.4536),
              //   child: Stack(
              //     children: <Widget>[
              //       Pinned.fromPins(
              //         Pin(start: 0.0, end: 0.0),
              //         Pin(start: 0.0, end: 0.0),
              //         child: Container(
              //           decoration: BoxDecoration(
              //             borderRadius: BorderRadius.circular(15.0),
              //             color: const Color(0xffffffff),
              //             border: Border.all(
              //                 width: 1.0, color: const Color(0xff707070)),
              //           ),
              //         ),
              //       ),
              //       Pinned.fromPins(
              //         Pin(size: 59.0, end: 0.0),
              //         Pin(start: 0.0, end: 0.0),
              //         child: Container(
              //           decoration: BoxDecoration(
              //             borderRadius: BorderRadius.only(
              //               topRight: Radius.circular(15.0),
              //               bottomRight: Radius.circular(15.0),
              //             ),
              //             color: const Color(0xff070707),
              //             border: Border.all(
              //                 width: 1.0, color: const Color(0xff707070)),
              //           ),
              //         ),
              //       ),
              //       Pinned.fromPins(
              //         Pin(size: 52.0, start: 10.0),
              //         Pin(size: 19.0, start: 5.0),
              //         child: Text(
              //           'node 02',
              //           style: TextStyle(
              //             fontFamily: 'Segoe UI',
              //             fontSize: 14,
              //             color: const Color(0xff070707),
              //             fontWeight: FontWeight.w600,
              //           ),
              //           textAlign: TextAlign.left,
              //         ),
              //       ),
              //       Pinned.fromPins(
              //         Pin(size: 28.0, start: 8.0),
              //         Pin(size: 19.0, middle: 0.6275),
              //         child: Text(
              //           '15:12',
              //           style: TextStyle(
              //             fontFamily: 'Segoe UI',
              //             fontSize: 14,
              //             color: const Color(0xff070707),
              //             fontWeight: FontWeight.w300,
              //           ),
              //           textAlign: TextAlign.left,
              //         ),
              //       ),
              //       Pinned.fromPins(
              //         Pin(size: 40.0, start: 10.0),
              //         Pin(size: 16.0, end: 4.0),
              //         child: Text(
              //           'Mon 03',
              //           style: TextStyle(
              //             fontFamily: 'Segoe UI',
              //             fontSize: 12,
              //             color: const Color(0xff070707),
              //             fontWeight: FontWeight.w300,
              //           ),
              //           textAlign: TextAlign.left,
              //         ),
              //       ),
              //       Pinned.fromPins(
              //         Pin(size: 7.0, end: 5.0),
              //         Pin(size: 16.0, middle: 0.2222),
              //         child: Text(
              //           'C',
              //           style: TextStyle(
              //             fontFamily: 'Segoe UI',
              //             fontSize: 12,
              //             color: const Color(0xffc4b3b3),
              //             fontWeight: FontWeight.w700,
              //           ),
              //           textAlign: TextAlign.left,
              //         ),
              //       ),
              //       Pinned.fromPins(
              //         Pin(size: 10.0, end: 2.0),
              //         Pin(size: 16.0, middle: 0.7963),
              //         child: Text(
              //           '%',
              //           style: TextStyle(
              //             fontFamily: 'Segoe UI',
              //             fontSize: 12,
              //             color: const Color(0xffc4b3b3),
              //             fontWeight: FontWeight.w700,
              //           ),
              //           textAlign: TextAlign.left,
              //         ),
              //       ),
              //       Pinned.fromPins(
              //         Pin(size: 36.0, end: 14.0),
              //         Pin(size: 24.0, start: 8.0),
              //         child: Text(
              //           '28.5',
              //           style: TextStyle(
              //             fontFamily: 'Segoe UI',
              //             fontSize: 18,
              //             color: const Color(0xffffffff),
              //             fontWeight: FontWeight.w700,
              //           ),
              //           textAlign: TextAlign.left,
              //         ),
              //       ),
              //       Pinned.fromPins(
              //         Pin(size: 36.0, end: 14.0),
              //         Pin(size: 24.0, end: 8.0),
              //         child: Text(
              //           '63.2',
              //           style: TextStyle(
              //             fontFamily: 'Segoe UI',
              //             fontSize: 18,
              //             color: const Color(0xffffffff),
              //             fontWeight: FontWeight.w700,
              //           ),
              //           textAlign: TextAlign.left,
              //         ),
              //       ),
              //       // Pinned.fromPins(
              //       //   Pin(size: 52.0, end: 0.0),
              //       //   Pin(size: 1.0, middle: 0.5072),
              //       //   child: SvgPicture.string(
              //       //     _svg_gxva00,
              //       //     allowDrawingOutsideViewBox: true,
              //       //     fit: BoxFit.fill,
              //       //   ),
              //       // ),
              //     ],
              //   ),
              // ),
              // ======================
            ),
          ),
        ),
      ),
    );
  }

  /**
   * Update console status background color when device status has been updated.
   */
  Color updateConsoleStatusFontColor(String pumpStatus) {
    Color result = Colors.white;

    switch(pumpStatus.toLowerCase()) {
      case Constants.CONSOLE_STATUS_LOST_CONNECT_LOWER_CASE: {
        result = Colors.red.shade500;
        break;
      }
      case Constants.SWITCH_OFF: {
        result = Colors.red.shade500;
        break;
      }
      case Constants.SWITCH_ON: {
        result = Colors.lightGreen.shade500;
        break;
      }
    }
    return result;
  }



}

class ListViewHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        Text('List 1'),
        Text('List 2'),
        Text('List 3'),
      ],
    );
  }
}