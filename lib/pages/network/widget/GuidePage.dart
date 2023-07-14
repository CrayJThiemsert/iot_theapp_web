import 'package:flutter/material.dart';
// import 'package:flutter_gifimage/flutter_gifimage.dart';
import 'package:iot_theapp_web/pages/device/choose_device.dart';
import 'package:iot_theapp_web/pages/network/choose_network.dart';
import 'package:iot_theapp_web/pages/network/entity/scenario_entity.dart';
import 'package:iot_theapp_web/pages/network/view/guide_choose_device_page.dart';
import 'package:iot_theapp_web/utils/sizes_helpers.dart';
import 'package:iot_theapp_web/globals.dart' as globals;

class GuidePage extends StatefulWidget {
  const GuidePage({
    Key? key,
    required this.scenario,
    // required this.gifController,
  }) : super(key: key);

  final Scenario scenario;
  // final GifController gifController;

  @override
  _GuidePageState createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {

  @override
  Widget build(BuildContext context) {
    return drawGuide(widget.scenario);
  }

  Widget drawGuide(Scenario scenario) {
    final TextStyle? captionStyle = Theme.of(context).textTheme.headline4;
    final TextStyle? nameStyle = Theme.of(context).textTheme.caption;
    final TextStyle? subtitleStyle = Theme.of(context).textTheme.subtitle1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        Container(
          // height: displayHeight(context) * 0.2,
          width: displayWidth(context) * 0.9,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisSize: MainAxisSize.max,
                children: [
                  Image(
                    image: AssetImage(scenario.iconImage),
                  ),
                  // GifImage(
                  //   controller: widget.gifController,
                  //   image: AssetImage(scenario.iconImage),
                  // ),
                  Text('${scenario.caption} - ${globals.g_mobileServer}',
                    style: nameStyle,
                  ),
                  Text('${scenario.description}',
                    style: subtitleStyle,
                  ),
                  SizedBox(height: 20,),
                  Text('${scenario.guide}',
                    textAlign: TextAlign.justify,
                    style: subtitleStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
        ElevatedButton(
          child: Text('Next'),
          style: ElevatedButton.styleFrom(
            primary: Colors.cyan[400],
            // padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
            // textStyle: TextStyle(
            //     fontSize: 30,
            //     fontWeight: FontWeight.bold)
          ),
          onPressed:
            enableButton(widget.scenario) ? ()=> {
              navigateToNextPage(scenario)
            } : null,

        ),
      ],
    );
  }



  bool enableButton(Scenario scenario) {
    bool isEnabled = true ;
    // switch(scenario.index) {
    //   case 2:
    //   case 3:{
    //     isEnabled = false;
    //   }
    //   break;
    // }

    return isEnabled;
  }

  void navigateToNextPage(Scenario scenario) {
    print('${scenario}');
    // Navigate to add new device page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gotoNextPage(scenario)),
    );
  }

  Widget gotoNextPage(Scenario scenario) {
    switch(scenario.index) {
      case 1: {
        return ChooseNetworkPage(scenario: widget.scenario);
      }
      break;
      case 2: {
        return ChooseNetworkPage(scenario: widget.scenario);
      }
      break;
      case 3: {
        return GuideChooseDevicePage(scenario: widget.scenario);
      }
      case 11:
      case 22:
      case 33:{
        return ChooseDevicePage(scenario: widget.scenario);
      }
      break;

      default: {
        return ChooseNetworkPage(scenario: widget.scenario);
      }
      break;
    }
  }
}
