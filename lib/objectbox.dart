import 'package:iot_theapp_web/objectbox/user.dart';

import 'objectbox.g.dart'; // created by `flutter pub run build_runner build`

class ObjectBox {
  /// The Store of this app.
  late final Store store;

  late final Box<User> userBox;

  ObjectBox._create(this.store) {
    // Add any additional setup code, e.g. build queries.

    userBox = Box<User>(store);

  }



  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    final store = await openStore();
    return ObjectBox._create(store);
  }
}