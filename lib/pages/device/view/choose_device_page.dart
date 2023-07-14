import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:iot_theapp_web/main.dart';
import 'package:iot_theapp_web/objectbox/user.dart';
import 'package:iot_theapp_web/pages/network/entity/scenario_entity.dart';

import 'package:iot_theapp_web/utils/constants.dart';
// import 'package:wifi/wifi.dart';
// import 'package:wifi_configuration_2/wifi_configuration_2.dart';
import 'package:android_flutter_wifi/android_flutter_wifi.dart';

import 'package:iot_theapp_web/globals.dart' as globals;

import 'package:http/http.dart' as http;

import 'package:open_settings/open_settings.dart';

String _ssid = '';  // Wifi name
String _bssid = 'AA:CC:A8:88:5B:AC'; // Dummy WiFi BSSID
String _password = '';  // Wifi password
String _deviceName = '';  // Device name

// WifiConfiguration wifiConfiguration = WifiConfiguration();

class ChooseDevicePage extends StatefulWidget {
  const ChooseDevicePage({
    Key? key,
    required this.scenario,
  }) : super(key: key);

  // late Socket channel;
  final Scenario scenario;



  @override
  _ChooseDevicePageState createState() => new _ChooseDevicePageState();
}

class _ChooseDevicePageState extends State<ChooseDevicePage> with AfterLayoutMixin<ChooseDevicePage> {
  int? userId;
  User? user;

  String _wifiName = 'click button to get wifi ssid.';
  int level = 0;
  String _ip = 'click button to get ip.';
  List<WifiNetwork> theNodeSSIDList = <WifiNetwork>[];
  String ssid = '', password = '';
  String deviceName = '';

  var _ssidController = TextEditingController();
  var _deviceNameController = TextEditingController();
  var _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

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

    // wifiConfiguration = WifiConfiguration();
    print('ChooseDevicePage<-');



    // wifiConfiguration.checkConnection().then((value){
    //   print('Value: ${value.toString()}');
    // });

    checkConnection();


    // getWifiList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('${Constants.of(context).DEFAULT_THE_NODE_IP} Internet Wifi Network'),
        title: Text('Connect Device'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: itemSSID(0),
        // child: ListView.builder(
        //   padding: EdgeInsets.all(8.0),
        //   itemCount: theNodeSSIDList.length + 1,
        //   itemBuilder: (BuildContext context, int index) {
        //     return itemSSID(index);
        //   },
        // ),
      ),
    );
  }

  Widget itemSSID(index) {
    final TextStyle? captionStyle = Theme.of(context).textTheme.headline4;
    if (index == 0) {
      return Column(
        children: [
          // Row(
          //   children: <Widget>[
          //     ElevatedButton(
          //       child: Text('ssid'),
          //       onPressed: _getWifiName,
          //     ),
          //     Offstage(
          //       offstage: level == 0,
          //       child: Image.asset(level == 0 ? 'images/wifi1.png' : 'images/wifi$level.png', width: 28, height: 21),
          //     ),
          //     Text(_wifiName,
          //       textAlign: TextAlign.left,
          //     ),
          //   ],
          // ),
          // Row(
          //   children: <Widget>[
          //     ElevatedButton(
          //       child: Text('ip'),
          //       onPressed: _getIP,
          //     ),
          //     Text(_ip,
          //       textAlign: TextAlign.left,
          //     ),
          //   ],
          // ),
          TextField(
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              filled: true,
              icon: Icon(Icons.network_check),
              hintText: 'Your selected device network',
              labelText: 'selected device network',
            ),
            style: captionStyle,
            enabled: false,
            controller: _ssidController,
            onChanged: (value) {
              ssid = value;
            },
          ),
          TextField(
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              filled: true,
              icon: Icon(Icons.title),
              hintText: 'Your device name',
              labelText: 'device name',
            ),
            style: captionStyle,
            keyboardType: TextInputType.text,
            controller: _deviceNameController,
            onTap: () {
              if(globals.g_device_name.isEmpty) {
                _deviceNameController.text = 'node-';
                globals.g_device_name = _deviceNameController.text;
              }
            },
            onChanged: (value) {
              deviceName = value;
              _deviceName = deviceName;
              globals.g_device_name = _deviceName;
            },
          ),
          // TextField(
          //   decoration: InputDecoration(
          //     border: UnderlineInputBorder(),
          //     filled: true,
          //     icon: Icon(Icons.lock_outline),
          //     hintText: 'Your wifi password',
          //     labelText: 'password',
          //   ),
          //   keyboardType: TextInputType.text,
          //   controller: _passwordController,
          //   onChanged: (value) {
          //     password = value;
          //     _password = password;
          //     globals.g_internet_password = _password;
          //   },
          // ),
          ElevatedButton(
            child: Text('Choose a device...'),
            onPressed: () {
              AppSettings.openWIFISettings(asAnotherTask: true).then((value) => checkConnection() );
            },
            // onPressed: executeEsptouch, // too complicated to use, because we don't know how to verify/handle response.
          ),
          ElevatedButton(
            child: Text('connect'),
            onPressed: gotoHomePage,
            // onPressed: executeEsptouch, // too complicated to use, because we don't know how to verify/handle response.
          ),
        ],
      );
    } else {
      return Column(children: <Widget>[
        ListTile(
          leading: Image.asset('images/wifi${theNodeSSIDList[index - 1].level}.png', width: 28, height: 21),
          title: Text(
            "${theNodeSSIDList[index - 1].ssid} " ,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16.0,
            ),
          ),
          onTap: () {
            setState(() {
              _tapTheNodeSSID("${theNodeSSIDList[index - 1].ssid}");
            });
          },

          dense: true,
        ),
        Divider(),
      ]);
    }
  }

  @override
  void dispose() {
    // widget.channel.close();
    super.dispose();
    _ssidController.dispose();
    _deviceNameController.dispose();
    _passwordController.dispose();
  }

  // void getWifiList() async {
  //   Wifi.list('').then((list) {
  //     setState(() {
  //       theNodeSSIDList = filterTheNode(list);
  //     });
  //   });
  // }
  void getWifiList() async {
    theNodeSSIDList = await AndroidFlutterWifi.getWifiScanResult();
    if (theNodeSSIDList.isNotEmpty) {
      // WifiNetwork wifiNetwork = ssidList[0];
      // print('Name: ${wifiNetwork.ssid}');
      print('Network list length: ${theNodeSSIDList.length.toString()}');
    }
    // theNodeSSIDList = await wifiConfiguration.getWifiList() as List<WifiNetwork>;
    // print('Network list length: ${theNodeSSIDList.length.toString()}');
    setState(() {});
  }

  // List<WifiResult> filterTheNode(List<WifiResult> rawList)  {
  //   List<WifiResult> resultList = [];
  //   for (int i = 0; i < rawList.length; i++) {
  //     if(rawList[i].ssid.contains("theNode_")) {
  //       resultList.add(WifiResult(rawList[i].ssid, rawList[i].level));
  //     }
  //   }
  //   return resultList;
  // }

  List<WifiNetwork> filterTheNode(List<WifiNetwork> rawList)  {
    List<WifiNetwork> resultList = [];
    for (int i = 0; i < rawList.length; i++) {
      if(rawList[i].ssid!.contains("theNode_")) {
        resultList.add(WifiNetwork(
            ssid: rawList[i].ssid,
            level: rawList[i].level));
      }
    }
    return resultList;
  }

  // Future<Null> _getCurrentWifiSSID() async {
  //   int l = await Wifi.level;
  //   String wifiName = await Wifi.ssid;
  //   setState(() {
  //     level = l;
  //     _wifiName = "${wifiName}";
  //     _ssid = _wifiName;
  //     _ssidController.text = _ssid;
  //     if(_ssid.contains("theNode_")) {
  //       _passwordController.text = "Device Matched";
  //       _ssidController.text = "Device Matched";
  //     } else {
  //       _passwordController.text = "Device Not Matched";
  //       _ssidController.text = "Device Not Matched";
  //     }
  //   });
  // }

  // Future<Null> _getIP() async {
  //   String ip = await Wifi.ip;
  //   setState(() {
  //     _ip = ip;
  //   });
  // }

  void dataHandler(data){
    print(new String.fromCharCodes(data).trim());
  }

  void errorHandler(error, StackTrace trace){
    print(error);
  }

  void doneHandler(){
    // widget.channel.destroy();
  }

  void gotoNextPage() {
    // Navigate to add new device page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChooseDevicePage(scenario: widget.scenario,)),
    );
  }

  void gotoDeviceDetailPage() {
    Navigator.pushNamedAndRemoveUntil(context, "/DetailDevicePage", (route) => false);
  }

  void gotoHomePage() {
    pushInternetWifiAccessData();
    showDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text("Add New Device Finished"),
          content: Text("Please select back to your internet wifi ssid.\ The App will restart."),
          actions: [
            CupertinoDialogAction(
              child: Text("OK"),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
              },
            ),
          ],
        ),
        barrierDismissible: false
    );

  }


  ///  First contact to "the Node" to pass internet wifi ssid and password
  Future<http.Response> pushInternetWifiAccessData() async {

    String mode = "setup";
    var url =
    // Uri.https('www.googleapis.com', '/books/v1/volumes', {'q': '{http}'});
    Uri.http(Constants.of(context)!.DEFAULT_THE_NODE_IP, '/setting', {'ssid': globals.g_internet_ssid, 'pass': globals.g_internet_password, 'mode': mode, 'name': globals.g_device_name, 'useruid': user!.userName});

    // Await the http get response, then decode the json-formatted response.
    final response = await http.get(url);
    print("status code =${response.statusCode}");
    if (response.statusCode == 200) {
      print('Device[${_ssid}] - setting is ok!!');
      _passwordController.text = "Device[${_ssid}] - setting is ok!!";
      // var jsonResponse = convert.jsonDecode(response.body);
      // var itemCount = jsonResponse['totalItems'];
      // print('Number of books about http: $itemCount.');
    } else {
      print('Device[${_ssid}] - setting is not ok!!');
      _passwordController.text = "Device[${_ssid}] - setting is not ok!!";
      // print('Request failed with status: ${response.statusCode}.');
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to do wifi settings');
    }

    return response;
    // print("_ip=${_ip}");
    // widget.channel = await Socket.connect('192.168.1.144', 80).then((Socket sock) {
    //   widget.channel = sock;
    //   widget.channel.listen(dataHandler,
    //       onError: errorHandler,
    //       onDone: doneHandler,
    //       cancelOnError: false);
    // }).catchError((Object e) {
    //   print("Unable to connect: $e");
    // });

    // print("ssid=${ssid} password=${password}");
    // Wifi.connection(ssid, password).then((v) async {
    //   print(v);
    //
    // });


  }

  @override
  void afterFirstLayout(BuildContext context) {
    // Get the global ssid and password
    // _ssidController.text = globals.g_internet_ssid;
    // _passwordController.text = globals.g_internet_password;


    print("open wifi settings...");
    AppSettings.openWIFISettings(asAnotherTask: true).then((value) => scanMatchedTheNode() );
    // AppSettings.openWIFISettings(asAnotherTask: true).then((value) => checkConnection() );
  }

  // void scanMatchedTheNode() {
  //   print("hello scanMatchedTheNode!!");
  //
  //   Timer.periodic(Duration(seconds: 5), (timer) async {
  //     print("Time: ${DateTime.now()}");
  //
  //     String wifiName = await Wifi.ssid;
  //     setState(() {
  //       _wifiName = "${wifiName}";
  //       _ssid = _wifiName;
  //       _ssidController.text = _ssid;
  //       if(_ssid.contains("theNode_")) {
  //         _passwordController.text = "Device[${_ssid}] Matched";
  //         _ssidController.text = "Device[${_ssid}] Matched";
  //         timer.cancel();
  //       } else {
  //         _passwordController.text = "Device[${_ssid}] Not Matched";
  //         _ssidController.text = "Device[${_ssid}] Not Matched";
  //       }
  //       print("${_passwordController.text}");
  //     });
  //   });
  // }

  void scanMatchedTheNode() {
    print("hello scanMatchedTheNode!!");

    Timer.periodic(Duration(seconds: 5), (timer) async {
      print("Time: ${DateTime.now()}");

      // getActiveWifiNetwork() async {
        ActiveWifiNetwork activeWifiNetwork = await AndroidFlutterWifi.getActiveWifiInfo();
        print('xxConnection name: ${activeWifiNetwork.ssid}');
        _ssid = activeWifiNetwork.ssid!;
        print('_ssid=$_ssid');
        String deviceWifiName = _ssid;
        setState(() {
          _wifiName = deviceWifiName;
          _ssidController.text = _ssid;
          if(_ssid.contains("theNode_")) {
            _passwordController.text = "Device[${_ssid}] Matched";
            _ssidController.text = "Device[${_ssid}] Matched";
            timer.cancel();
          } else {
            _passwordController.text = "Device[${_ssid}] Not Matched";
            _ssidController.text = "Device[${_ssid}] Not Matched";
          }
          print("${_passwordController.text}");
        });
      // }


      // // String wifiName = await Wifi.ssid;
      // WifiConnectionObject wifiConnectionObject =
      // await wifiConfiguration!.connectedToWifi();
      //
      // if (wifiConnectionObject != null) {
      //   print('xxConnection name: ${wifiConnectionObject.ssid}');
      //   _ssid = wifiConnectionObject.ssid!;
      //   print('_ssid=$_ssid');
      //   String deviceWifiName = _ssid;
      //   setState(() {
      //     _wifiName = deviceWifiName;
      //     _ssidController.text = _ssid;
      //     if(_ssid.contains("theNode_")) {
      //       _passwordController.text = "Device[${_ssid}] Matched";
      //       _ssidController.text = "Device[${_ssid}] Matched";
      //       timer.cancel();
      //     } else {
      //       _passwordController.text = "Device[${_ssid}] Not Matched";
      //       _ssidController.text = "Device[${_ssid}] Not Matched";
      //     }
      //     print("${_passwordController.text}");
      //   });
      // }

    });
  }

  void _tapTheNodeSSID([String? ssid]) {
    _password = ssid!;
    _passwordController.text = _password;
  }

  // Future<void> getCurrentWifiSSID() async {
  //   String wifiConnected = (await wifiConfiguration.connectedToWifi()) as String;
  //   print("wifiConnected: $wifiConnected");
  //
  // }

  void checkConnection() async {
    await AndroidFlutterWifi.init();
    var isConnected = await AndroidFlutterWifi.isConnected();
    print('Is connected: ${isConnected.toString()}');

    List<WifiNetwork> wifiList = await AndroidFlutterWifi.getWifiScanResult();
    if (wifiList.isNotEmpty) {
      scanMatchedTheNode();
    }

    // wifiConfiguration!.isWifiEnabled().then((value) {
    //   print('Is wifi enabled: ${value.toString()}');
    // });
    //
    // wifiConfiguration!.checkConnection().then((value) {
    //   print('Value: ${value.toString()}');
    // });
    //
    // WifiConnectionObject wifiConnectionObject =
    // await wifiConfiguration!.connectedToWifi();
    // print('Connection name: ${wifiConnectionObject.ssid}');
    // _ssid = wifiConnectionObject.ssid!;
    // print('_ssid=$_ssid');
    // if (wifiConnectionObject != null) {
    //   scanMatchedTheNode();
    // }
  }
}