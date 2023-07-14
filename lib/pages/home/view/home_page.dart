import 'dart:async';
// import 'dart:js_interop';


import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:iot_theapp_web/objectbox/user.dart';

import 'package:iot_theapp_web/pages/home/widget/devices_list.dart';
// import 'package:iot_theapp_web/pages/network/choose_network.dart';

import 'package:iot_theapp_web/globals.dart' as globals;
import 'package:iot_theapp_web/pages/network/view/choose_territory_scenario_page.dart';

import 'package:iot_theapp_web/main.dart';
import 'package:validators/validators.dart';





class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.app}) : super(key: key);

  final FirebaseApp app;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final fb = FirebaseDatabase.instance;
  final myController = TextEditingController();
  final name = "Name2";
  final databaseReference = FirebaseDatabase.instance.ref();

  int? userId;
  User? user;

  // -------------------------
  int _counter = 0;
  // late DatabaseReference _counterRef;
  // late DatabaseReference _messagesRef;
  // late StreamSubscription<DatabaseEvent> _counterSubscription;
  // late StreamSubscription<DatabaseEvent> _messagesSubscription;
  bool _anchorToBottom = false;

  String _kTestKey = 'Hello';
  String _kTestValue = 'world!';
  FirebaseException? _error;

  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _userNameFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Demonstrates configuring to the database using a file
    // _counterRef = FirebaseDatabase.instance.reference().child('counter');
    // Demonstrates configuring the database directly
    final FirebaseDatabase database = FirebaseDatabase(app: widget.app);
    // _messagesRef = database.reference().child('messages');
    // database.reference().child('counter').once().then((DataSnapshot snapshot) {
    //     print('Connected to second database and read ${snapshot.value}');
    //   }, onError: (Object o) {
    //     final FirebaseException error = o as FirebaseException;
    //     print('Error: ${error.code} ${error.message}');
    // });

    database.setPersistenceEnabled(true);
    database.setPersistenceCacheSizeBytes(10000000);
    // _counterRef.keepSynced(true);
    // _counterSubscription = _counterRef.onValue.listen((DatabaseEvent event) {
    //   setState(() {
    //     _error = null;
    //     _counter = (event.snapshot.value ?? 0) as int;
    //   });
    // }, onError: (Object o) {
    //   final FirebaseException error = o as FirebaseException;
    //   setState(() {
    //     _error = error;
    //   });
    // });
    // _messagesSubscription =
    //     _messagesRef.limitToLast(10).onChildAdded.listen((DatabaseEvent event) {
    //       print('Child added: ${event.snapshot.value}');
    //     }, onError: (Object o) {
    //       final FirebaseException error = o as FirebaseException;
    //       print('Error: ${error.code} ${error.message}');
    //     });



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
        if(user!.isServer == null) {
          user!.isServer = false;
        }

        // Test re-write user objectbox
        // user!.userName = 'cray';
        // objectbox.userBox.put(user!);
        // print('renew-read user[${userId}]: ${objectbox.userBox.get(userId!)}');
      }
    }



  }



  @override
  Widget build(BuildContext context) {
    // final ref = fb.reference();
    // var devicesRef = ref.child("devices");

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
            onTap: () async {
              final title =
                  await openUserInputDialog();
              if (title == null) return;
            },
            child: Text('${user!.userName}\'s Iot - v.${globals.g_version}.${globals.g_buildNumber}')
        ),
        backgroundColor: Colors.cyan[400],
      ),
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
              child: Text('Add New Device'),
              style: ElevatedButton.styleFrom(
                primary: Colors.cyan[400],
                // padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                // textStyle: TextStyle(
                //     fontSize: 30,
                //     fontWeight: FontWeight.bold)
              ),
              onPressed: () async {
                // /// Finally, unsubscribe and exit gracefully
                // print('EXAMPLE::Unsubscribing');
                // client.unsubscribe(topic);
                //
                // /// Wait for the unsubscribe message from the broker if you wish.
                // await MqttUtilities.asyncSleep(2);
                // print('EXAMPLE::Disconnecting');
                // client.disconnect();
                // print('EXAMPLE::Exiting normally');
                // Navigate to add new device page
                Navigator.push(
                  context,
                  // MaterialPageRoute(builder: (context) => ChooseNetworkPage()),
                  MaterialPageRoute(builder: (context) => ChooseTerritoryScenarioPage()),
                );
              },
            ),
          ),
          // ElevatedButton(onPressed: () {
          //   print('get data name2 once...');
          //   ref.child("Name2").once().then((DataSnapshot data){
          //     print('value=${data.value}');
          //     print('key=${data.key}');
          //     // setState(() {
          //     //   retrievedName = data.value;
          //     // });
          //   });
          // }, child: Text('Get sample data')),

          DevicesList(),

        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   // onPressed: _increment,
      //   onPressed: () {
      //     var post = Post('Hello', 'Cray');
      //     post.setId(savePost(post));
      //   },
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
    );
  }

  Future<String?>  openUserInputDialog() =>
      showDialog<String>(
        context: context,
        builder: (context) =>
            AlertDialog(
              insetPadding: EdgeInsets.only(
                top: 2.0,
                left: 4.0,
                right: 4.0,
              ),
              title: Container(
                  alignment: Alignment.topCenter, child: Text('User')
              ),
              // content: buildOperationUnitList(),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Form(
                    key: _userNameFormKey,
                    child: TextFormField(
                      initialValue: user!.userName,
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text for user name.';
                        } else {
                          if (!isAlphanumeric(value!)) {
                            return 'Invalid user name format!!';
                          }
                          setState(() {
                            // this.notificationDialog.notifyEmail = value;
                            user!.userName = value;
                          });

                          return null;
                        }
                      },
                      autofocus: false,
                      decoration: InputDecoration(
                        label: Text(
                          'User name:',
                          style: TextStyle(fontSize: 16, color: Colors.black45),
                        ),
                        // labelText: Text('Email:'),
                        hintText: 'Enter your user name who own the system.',
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
                  SizedBox(
                    height: 16,
                  ),
                  Visibility(
                    visible: true,
                    child: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Container(
                            padding: EdgeInsets.only(left: 0.0, right: 0.0),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black26)),
                            child: CheckboxListTile(
                              title: Text(
                                'MQTT Subscribed Server',
                                style: TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                              subtitle: Text(
                                'Enable for only server machine to update cloud database from MQTT message trigger.',
                                style: TextStyle(fontSize: 12, color: Colors.black38),
                              ),
                              secondary: Icon(Icons.mail_outline),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: this.user!.isServer!,
                              selected: this.user!.isServer!,
                              // value: _checked,
                              onChanged: (bool? value) {
                                setState(() {
                                  this.user!.isServer = value!;
                                  print('check value=${value}');
                                });
                              },
                              activeColor: Colors.lightGreen,
                              checkColor: Colors.yellow,
                            ),
                          );
                        }),
                  ),
                  // Center(
                  //   child: SwitchListTile(
                  //     // This bool value toggles the switch.
                  //     title: Text('MQTT Subscribed Server'),
                  //     value: user!.isServer!,
                  //
                  //     activeColor: Colors.red,
                  //     onChanged: (bool value) {
                  //       // This is called when the user toggles the switch.
                  //       setState(() {
                  //         user!.isServer = value;
                  //         print('value=$value');
                  //
                  //         objectbox.userBox.put(user!);
                  //         print('renew-read user[${userId}]: ${objectbox.userBox.get(userId!)} is success!!');
                  //
                  //         Navigator.pop(context);
                  //         Navigator.of(context).pop();
                  //
                  //         Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
                  //
                  //       });
                  //     },
                  //   ),
                  // )
                ],
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
                      // Validate returns true if the form is valid, or false otherwise.
                      if (_userNameFormKey.currentState!.validate()) {
                        objectbox.userBox.put(user!);
                        print('renew-read user[${userId}]: ${objectbox.userBox.get(userId!)} is success!!');

                        showDialog(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                              title: Text("Update Successfully"),
                              content:
                              Text("Update owner user name settings is successfully."),
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
                      } else {
                        showDialog(
                            context: context,
                            builder: (_) =>
                                CupertinoAlertDialog(
                                  title: Text("The user name who own the system not found!"),
                                  content: Text(
                                      "Please enter the user name. ie. john.\ And try again."),
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

                      // List<OperationUnit> batchUpdatedLists = [];
                      //
                      // batchUpdatedLists = Provider.of<TempOperationUnitList>(context, listen: false).tempOperationUnitLists;

                      // Validate returns true if the form is valid, or false otherwise.
                      // print('tempOperationUnitLists.length=${context.read<_OperationUnitListWidgetState>().tempOperationUnitLists.length}');
                      // if (batchUpdatedLists.length > 0) {
                        // If the form is valid, display a snackbar. In the real world,
                        // you'd often call a server or save the information in a database.
                        // updateSensorParing(batchUpdatedLists);

                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(content: Text('Updated Data')),
                        // );


                    },
                    child: Text('SUBMIT')),
              ],
            ),
      );

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();

    // _messagesSubscription.cancel();
    // _counterSubscription.cancel();
  }
}