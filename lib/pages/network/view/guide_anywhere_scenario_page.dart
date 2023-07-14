import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gifimage/flutter_gifimage.dart';
import 'package:iot_theapp_web/pages/device/choose_device.dart';
import 'package:iot_theapp_web/pages/network/entity/scenario_entity.dart';
import 'package:iot_theapp_web/pages/network/widget/GuidePage.dart';
import 'package:iot_theapp_web/utils/sizes_helpers.dart';
// import 'package:wifi/wifi.dart';
// import 'package:wifi_configuration_2/wifi_configuration_2.dart';
import 'package:android_flutter_wifi/android_flutter_wifi.dart';

import 'package:iot_theapp_web/globals.dart' as globals;

String _ssid = '';  // Wifi name
// WifiConfiguration wifiConfiguration = WifiConfiguration();

class GuideAnywhereScenarioPage extends StatefulWidget {
  const GuideAnywhereScenarioPage({
    Key? key,
    required this.scenario,
  }) : super(key: key);

  final Scenario scenario;

  @override
  _GuideAnywhereScenarioPageState createState() => new _GuideAnywhereScenarioPageState();
}

class _GuideAnywhereScenarioPageState extends State<GuideAnywhereScenarioPage> with AfterLayoutMixin<GuideAnywhereScenarioPage>, TickerProviderStateMixin  {
  String _wifiName = 'click button to get wifi ssid.';
  int level = 0;
  List<WifiNetwork> ssidList = <WifiNetwork>[];
  String ssid = '', password = '';

  var _ssidController = TextEditingController();

  // late GifController gifController;

  @override
  void initState() {

    // gifController = GifController(vsync: this);

    // WidgetsBinding.instance!.addPostFrameCallback((_){
    //   gifController.repeat(min: 0,max: 100,period: Duration(milliseconds: 5000));
    // });

    super.initState();
    // loadData();
    // wifiConfiguration = WifiConfiguration();

    print('GuideAnywhereScenarioPage<-');
    checkConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anywhere Scenario 1/5'),
        backgroundColor: Colors.cyan[400],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GuidePage(scenario: widget.scenario, gifController: gifController),
            GuidePage(scenario: widget.scenario),
          ],
        ),
      ),
    );
  }



  @override
  void dispose() {
    // gifController.dispose();
    super.dispose();
  }

  void checkConnection() async {
    await AndroidFlutterWifi.init();
    var isConnected = await AndroidFlutterWifi.isConnected();
    print('Is connected: ${isConnected.toString()}');

    getWifiList();
    // wifiConfiguration.isWifiEnabled().then((value) {
    //   print('Is wifi enabled: ${value.toString()}');
    // });
    //
    // wifiConfiguration.checkConnection().then((value) {
    //   print('Value: ${value.toString()}');
    // });
    //
    // WifiConnectionObject wifiConnectionObject =
    // await wifiConfiguration.connectedToWifi();
    // if (wifiConnectionObject != null) {
    //   getWifiList();
    // }
  }

  Future<void> getWifiList() async {
    ssidList = await AndroidFlutterWifi.getWifiScanResult();
    if (ssidList.isNotEmpty) {
      // WifiNetwork wifiNetwork = ssidList[0];
      // print('Name: ${wifiNetwork.ssid}');
      print('Network list length: ${ssidList.length.toString()}');
    }
    // ssidList = await wifiConfiguration.getWifiList() as List<WifiNetwork>;
    // print('Network list length: ${ssidList.length.toString()}');
    setState(() {
      ssidList = filterTheNodeOut(ssidList);
    });
  }

  // void loadData() async {
  //   Wifi.list('').then((list) {
  //     setState(() {
  //       ssidList = filterTheNodeOut(list);
  //     });
  //   });
  // }

  List<WifiNetwork> filterTheNodeOut(List<WifiNetwork> rawList)  {
    List<WifiNetwork> resultList = [];
    for (int i = 0; i < rawList.length; i++) {
      if(!rawList[i].ssid!.contains("theNode_")) {
        resultList.add(WifiNetwork(
            ssid: rawList[i].ssid,
            level: rawList[i].level));
      }
    }
    return resultList;
  }

  // List<WifiResult> filterTheNodeOut(List<WifiResult> rawList)  {
  //   List<WifiResult> resultList = [];
  //   for (int i = 0; i < rawList.length; i++) {
  //     if(!rawList[i].ssid.contains("theNode_")) {
  //       resultList.add(WifiResult(rawList[i].ssid, rawList[i].level));
  //     }
  //   }
  //   return resultList;
  // }

  // Future<Null> _getWifiName() async {
  //   int l = await Wifi.level;
  //   String wifiName = await Wifi.ssid;
  //   String wifiIp = await Wifi.ip;
  //   setState(() {
  //     level = l;
  //     _wifiName = "${wifiName}";
  //     _ssid = _wifiName;
  //     globals.g_internet_ssid = _ssid;
  //     _ssidController.text = _ssid;
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

  @override
  void afterFirstLayout(BuildContext context) {
    // Get the current ssid
    // _getWifiName();
  }

}