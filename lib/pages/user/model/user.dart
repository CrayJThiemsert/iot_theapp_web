import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

class User extends Equatable {
  final String id;
  final String uid;
  final String email;
  final String displayName;
  final String firstName;
  final String lastName;
  final String photoURL;
  final String phoneNumber;

  const User(
      {id,
      uid,
      email,
      displayName,
      photoURL,
      phoneNumber,
      firstName,
      lastName}) :
      this.id = id ?? '',
      this.uid = uid ?? '',
      this.email = email ?? '',
      this.displayName = displayName ?? '',
      this.photoURL = photoURL ?? '',
      this.phoneNumber = phoneNumber ?? '',
      this.firstName = firstName ?? '',
      this.lastName = lastName ?? ''
  ;

  User copyWith({
    String? id,
    String? uid,
    String? name,
  }) {
    return User(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      phoneNumber: phoneNumber,
      firstName: firstName,
      lastName: lastName,
      // headers: headers ?? this.headers,
      // itemDatas: itemDatas ?? this.itemDatas,
      // topic: topic ?? this.topic,
    );
  }

  @override
  int get hashCode =>
      id.hashCode ^ uid.hashCode ^ email.hashCode ^  displayName.hashCode; // ^ topic.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is User &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              uid == other.uid &&
              email == other.email &&
              displayName == other.displayName &&
              photoURL == other.photoURL &&
              phoneNumber == other.phoneNumber &&
              firstName == other.firstName &&
              lastName == other.lastName
              ; // &&
  // headers == other.headers &&
  // itemDatas == other.itemDatas &&
  // topic == other.topic;

  @override
  List<Object> get props => [id, uid, email, displayName, firstName, lastName, photoURL, phoneNumber];
  
  static const empty = User(id: '', uid: '', email: '', displayName: '', lastName: '', photoURL: '', phoneNumber: '');

  @override
  String toString() {
    return 'User{id: $id, uid: $uid, email: $email, displayName: $displayName, firstName: $firstName, lastName: $lastName, photoURL: $photoURL, phoneNumber: $phoneNumber}';
  }

  // ItemEntity toEntity() {
  //   return ItemEntity(id, uid, index, name);
  // }

  // static User fromEntity(ItemEntity entity) {
  //   return Device(
  //     id: entity.id,
  //     uid: entity.uid,
  //     index: entity.index,
  //     name: entity.name,
  //   );
  // }
}
