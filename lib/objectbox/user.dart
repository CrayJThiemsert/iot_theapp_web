import 'package:objectbox/objectbox.dart';

@Entity()
class User {
  // Each "Entity" needs a unique integer ID property.
  // Add `@Id()` annotation if its name isn't "id" (case insensitive).
  int id = 0;

  String? userName;
  String? password;
  bool? isServer = false;
  String? updatedWhen;

  @Transient() // Make this field ignored, not stored in the database.
  int? notPersisted;

  // An empty default constructor is needed but you can use optional args.
  User({this.userName, this.password, this.isServer, this.updatedWhen});

  // User: just for logs in the examples below(), not needed by ObjectBox.
  toString() => 'User{id: $id, userName: $userName, password: $password, isServer: $isServer, updatedWhen: $updatedWhen}';
}