import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import 'package:iot_theapp_web/pages/device/choose_device.dart';
import 'package:iot_theapp_web/pages/network/entity/scenario_entity.dart';
import 'package:iot_theapp_web/pages/network/guide_anywhere_scenario.dart';
import 'package:iot_theapp_web/pages/network/guide_directly_scenario.dart';
import 'package:iot_theapp_web/pages/network/guide_territory_scenario.dart';
import 'package:iot_theapp_web/utils/constants.dart';
import 'package:iot_theapp_web/utils/sizes_helpers.dart';
import 'package:intl/intl.dart';
// import 'package:wifi/wifi.dart';
// import 'package:wifi_configuration_2/wifi_configuration_2.dart';
import 'package:android_flutter_wifi/android_flutter_wifi.dart';

import 'package:iot_theapp_web/globals.dart' as globals;

String _ssid = '';  // Wifi name
String _password = '';  // Wifi password
// WifiConfiguration wifiConfiguration = WifiConfiguration();

class ChooseTerritoryScenarioPage extends StatefulWidget {
  // late Socket channel;

  @override
  _ChooseTerritoryScenarioPageState createState() => new _ChooseTerritoryScenarioPageState();
}

class _ChooseTerritoryScenarioPageState extends State<ChooseTerritoryScenarioPage> with AfterLayoutMixin<ChooseTerritoryScenarioPage> {
  String _wifiName = 'click button to get wifi ssid.';
  int level = 0;
  String _ip = 'click button to get ip.';
  List<WifiNetwork> ssidList = <WifiNetwork>[];
  String ssid = '', password = '';

  var _ssidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // loadData();
    // wifiConfiguration = WifiConfiguration();

    print('GuideChooseDevicePage<-');
    checkConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('${Constants.of(context).DEFAULT_THE_NODE_IP} Internet Wifi Network'),
        title: Text('Select Territory Scenario'),
        backgroundColor: Colors.cyan[400],
        centerTitle: true,
      ),
      body: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            drawScenarioList(),
          ],
        ),
      ),
    );
  }

  Widget drawScenarioList() {
    final TextStyle? captionStyle = Theme.of(context).textTheme.headline4;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Please choose a network scenario', textAlign: TextAlign.center, style: captionStyle,),
        SizedBox(height: 40,),
        ScenarioCard(scenario: Scenario(caption: 'Read sensor values from anywhere', description: 'require internet network', guide: 'for user who plan to setup each sensors in internet access territory.', iconImage: 'images/diagram_anywhere.png', index: 1)),
        ScenarioCard(scenario: Scenario(caption: 'Read sensor values in user territory', description: 'non internet access but have WIFI router network', guide: 'for user who plan to setup each sensors in non internet access territory. But still have WIFI router network.', iconImage: 'images/diagram_territory.png', index: 2)),
        ScenarioCard(scenario: Scenario(caption: 'Read sensor values from device directly', description: 'non internet access and non WIFI router network', guide: 'for user who plan to setup each sensors in non internet access territory. But have no WIFI router network.', iconImage: 'images/diagram_directly.png', index: 3)),
      ],
    );
  }

  @override
  void dispose() {
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

  // void loadData() async {
  //   Wifi.list('').then((list) {
  //     setState(() {
  //       ssidList = filterTheNodeOut(list);
  //     });
  //   });
  // }
  //
  // List<WifiResult> filterTheNodeOut(List<WifiResult> rawList)  {
  //   List<WifiResult> resultList = [];
  //   for (int i = 0; i < rawList.length; i++) {
  //     if(!rawList[i].ssid.contains("theNode_")) {
  //       resultList.add(WifiResult(rawList[i].ssid, rawList[i].level));
  //     }
  //   }
  //   return resultList;
  // }
  //
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

class ScenarioCard extends StatefulWidget {
  const ScenarioCard({
    Key? key,
    required this.scenario,
  }) : super(key: key);

  final Scenario scenario;

  @override
  _ScenarioCardState createState() => _ScenarioCardState();
}

class _ScenarioCardState extends State<ScenarioCard> {
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
        print('on press ${widget.scenario.caption}');

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => gotoNextPage(widget.scenario)),
        );
        // String uri = '/device/${widget.scenario.uid}';
        //
        // print('${uri} pressed...');
        // Navigator.pushNamed(context, uri, arguments: widget.scenario);

      },
      child: Tooltip(
        message: '${widget.scenario.caption}' ,
        child: Container(
          height: displayHeight(context) * 0.2,
          width: displayWidth(context) * 0.9,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0, right: 6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    iconScenario(widget.scenario),
                    color: Colors.brown[300],
                    size: 48,
                  ),
                  Text('${widget.scenario.caption}',
                    style: nameStyle,
                  ),
                  Text('${widget.scenario.description}',
                    style: subtitleStyle,
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget gotoNextPage(Scenario scenario) {
    switch(scenario.index) {
      case 1: {
        return GuideAnywhereScenarioPage(scenario: scenario,);
      }
      break;
      case 2: {
        return GuideTerritoryScenarioPage(scenario: scenario,);
      }
      break;
      case 3: {
        return GuideDirectlyScenarioPage(scenario: scenario,);
      }
      break;
      default: {
        return GuideAnywhereScenarioPage(scenario: scenario,);
      }
      break;
    }
  }

  IconData iconScenario(Scenario scenario) {
    switch(scenario.index) {
      case 1: {
        return Icons.public_outlined;
      }
      break;
      case 2: {
        return Icons.router_outlined;
      }
      break;
      case 3: {
        return Icons.multiple_stop_outlined;
      }
      break;
      default: {
        return Icons.image_outlined;
      }
      break;
    }

  }
}