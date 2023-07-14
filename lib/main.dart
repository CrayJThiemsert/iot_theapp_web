import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:iot_theapp_web/objectbox.dart';
import 'package:iot_theapp_web/pages/device/view/temp_operation_unit_list.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flare_splash_screen/flare_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:iot_theapp_web/pages/device/choose_device.dart';
import 'package:iot_theapp_web/pages/device/model/device.dart';
import 'package:iot_theapp_web/pages/device/view/show_device_page.dart';
import 'package:iot_theapp_web/pages/network/choose_network.dart';
import 'package:iot_theapp_web/pages/network/entity/scenario_entity.dart';
import 'package:iot_theapp_web/utils/constants.dart';
// import 'package:package_info/package_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:iot_theapp_web/globals.dart' as globals;

import 'package:shelf/shelf_io.dart' as shelf_io;

import 'pages/home/home.dart';
// import 'dart:io' show Platform;

/// Provides access to the ObjectBox Store throughout the app.
late ObjectBox objectbox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // This is required so ObjectBox can get the application directory
  // to store the database in.
  objectbox = await ObjectBox.create();

  // await Firebase.initializeApp();
  // final FirebaseApp app = await Firebase.initializeApp();
  final FirebaseApp app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // final FirebaseApp app = await Firebase.initializeApp(
  //   name: 'db2',
  //   options: Platform.isIOS || Platform.isMacOS
  //       ? const FirebaseOptions(
  //     appId: '1:297855924061:ios:c6de2b69b03a5be8',
  //     apiKey: 'AIzaSyCbK11_NkEfVdkc6u4QwdTMY1D0cqNteKA',
  //     projectId: 'asset-management-lff',
  //     messagingSenderId: '1046253125651',
  //     databaseURL: 'https://asset-management-lff.firebaseio.com',
  //   )
  //       : const FirebaseOptions(
  //     appId: '1:1046253125651:android:7f197e41fe80cea000ffe6',
  //     apiKey: 'AIzaSyCbK11_NkEfVdkc6u4QwdTMY1D0cqNteKA',
  //     messagingSenderId: '1046253125651',
  //     projectId: 'asset-management-lff',
  //     databaseURL: 'https://asset-management-lff.firebaseio.com',
  //   ),
  // );

  print('Firebase app.name=${app.name}');

  // add these lines
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TempOperationUnitList()),
      ],
      // child: const MyApp(),
      child: Constants(
        child: MyApp(app: app),
        // child: MyApp(),
      ),
    ),

  );
}

class MyApp extends StatefulWidget {
  // const MyApp({Key? key, this.app}) : super(key: key);
  const MyApp({Key? key, required this.app}) : super(key: key);

  final FirebaseApp app;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;

      String appName = _packageInfo.appName;
      String packageName = _packageInfo.packageName;
      String version = _packageInfo.version;
      String buildNumber = _packageInfo.buildNumber;

      globals.g_appName = appName;
      globals.g_packageName = packageName;
      globals.g_version = version;
      globals.g_buildNumber = buildNumber;

      print('g_appName=${globals.g_appName}');
      print('g_packageName=${globals.g_packageName}');
      print('g_version=${globals.g_version}');
      print('g_buildNumber=${globals.g_buildNumber}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Kanit',
        textTheme: TextTheme(


          caption: TextStyle(fontFamily: 'Kanit', fontSize: 14.0, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.6),),


          subtitle1: TextStyle(fontFamily: 'Kanit', fontSize: 12.0, fontWeight: FontWeight.w300, color: Colors.grey.withOpacity(0.6),),
          subtitle2: TextStyle(fontFamily: 'Kanit', fontSize: 12.0, fontWeight: FontWeight.w600, color: Colors.lightGreen,),
          bodyText1: TextStyle(fontFamily: 'Kanit', fontSize: 14.0, fontWeight: FontWeight.w300, color: Colors.grey.withOpacity(0.9),),

          headline1: TextStyle(fontFamily: 'Kanit', fontSize: 36.0, fontWeight: FontWeight.w300, color: Colors.white,),
          headline2: TextStyle(fontFamily: 'Kanit', fontSize: 12.0, fontWeight: FontWeight.w300, color: Colors.white,),
          headline4: TextStyle(fontFamily: 'Kanit', fontSize: 16.0, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.4),),
          headline3: TextStyle(fontFamily: 'Kanit', fontSize: 20.0, fontWeight: FontWeight.w400, color: Colors.white,),
          headline5: TextStyle(fontFamily: 'Kanit', fontSize: 28.0, fontWeight: FontWeight.w300, color: Colors.grey.withOpacity(0.6),),
          headline6: TextStyle(fontFamily: 'Kanit', fontSize: 28.0, fontWeight: FontWeight.w600, color: Colors.lightGreen,),
        ),
      ),
      home: SplashScreen.navigate(
        name: 'intro.flr',
        // next: (context) => MainHomePage(title: 'Flutter Demo Home Page'),
        next: (context) => HomePage(app: widget.app),
        until: () => Future.delayed(Duration(seconds: 5)),
        startAnimation: '1',
      ),
      onGenerateRoute: (settings) {
        // Handle '/'
        if(settings.name == '/') {
          return MaterialPageRoute(builder: (context) => HomePage(app: widget.app));
        } else if(settings.name == '/choosenetwork') {
          return MaterialPageRoute(builder: (context) => ChooseNetworkPage(scenario: Scenario(),));
        } else if(settings.name == '/choosedevice') {
          return MaterialPageRoute(builder: (context) => ChooseDevicePage(scenario: Scenario(),));
        }
        // Prepare for case specify device id
        var uri = Uri.parse(settings.name!);
        if(uri.pathSegments.length == 2) {
          var uid = uri.pathSegments[1];
          Device device = settings.arguments as Device;
          switch (uri.pathSegments.first) {
            case 'device':
              {
                return MaterialPageRoute(builder: (context) => ShowDevicePage(deviceUid: uid, device: device));
              }
              break;
          }
        }

        // if(uri.pathSegments.length == 4) {
        //   var path = uri.pathSegments[2];
        //   var categoryUid = uri.pathSegments[1];
        //   var partUid = uri.pathSegments[3];
        //   Part part = settings.arguments;
        //   switch (path) {
        //     case 'part':
        //       {
        //         return MaterialPageRoute(builder: (context) => PartPage(categoryUid: categoryUid, partUid: partUid, part: part));
        //       }
        //       break;
        //   }
        // }
        //
        // if(uri.pathSegments.length == 6) {
        //   var path = uri.pathSegments[4];
        //   var categoryUid = uri.pathSegments[1];
        //   var partUid = uri.pathSegments[3];
        //   var topicUid = uri.pathSegments[5];
        //   Topic topic = settings.arguments;
        //   switch (path) {
        //     case 'topic':
        //       {
        //         return MaterialPageRoute(builder: (context) => TopicPage(categoryUid: categoryUid, partUid: partUid, topicUid: topicUid, topic: topic));
        //       }
        //       break;
        //   }
        // }
        return MaterialPageRoute(builder: (context) => UnknownScreen());
      },
    ));
  }
}

class UnknownScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text('404 - Page not found'),
      ),
    );
  }
}

class MainHomePage extends StatefulWidget {
  MainHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MainHomePageState createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}


// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
//
// import 'package:firebase_database/firebase_database.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // Try running your application with "flutter run". You'll see the
//         // application has a blue toolbar. Then, without quitting the app, try
//         // changing the primarySwatch below to Colors.green and then invoke
//         // "hot reload" (press "r" in the console where you ran "flutter run",
//         // or simply save your changes to "hot reload" in a Flutter IDE).
//         // Notice that the counter didn't reset back to zero; the application
//         // is not restarted.
//         primarySwatch: Colors.blue,
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({Key? key, required this.title}) : super(key: key);
//
//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.
//
//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".
//
//   final String title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   @override
//   void initState() {
//     init();
//
//     // TODO: implement initState
//     super.initState();
//   }
//
//   Future<void> init() async {
//     DatabaseReference ref = FirebaseDatabase.instance.ref("users/cray/devices/40:F5:20:3D:65:72");
//     // Access a child of the current reference
//     DatabaseReference child = ref.child("name");
//
//     print(ref.key); // "40:F5:20:3D:65:72"
//     print(ref.parent!.key); // "devices"
//     print(child.key);
//   }
//
//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Invoke "debug painting" (press "p" in the console, choose the
//           // "Toggle Debug Paint" action from the Flutter Inspector in Android
//           // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
//           // to see the wireframe for each widget.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headline4,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
//
//
// }
