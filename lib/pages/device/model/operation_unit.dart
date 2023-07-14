import 'package:iot_theapp_web/pages/device/entity/item_entity.dart';
import 'package:iot_theapp_web/pages/device/model/item.dart';
import 'package:meta/meta.dart';

@immutable
class OperationUnit extends Item{
  final String id;
  final String uid;
  final int index;
  final String name;
  final String deviceId;

  final String updatedWhen;

  String user;
  String sensor;
  String status;

  OperationUnit({
    String? id,
    String? uid,
    int index = 0,
    String name = '',
    String deviceId = '',

    String updatedWhen = '',

    String user = '',
    String sensor = '',
    String status = '',
  })
    : this.index = index,
      this.name = name ?? '',
      this.deviceId = deviceId ?? '',

      this.id = id ?? '',
      this.uid = uid ?? '',
      this.updatedWhen = updatedWhen ?? '',

      this.user = user ?? '',
      this.sensor = sensor ?? '',
      this.status = status ?? '';

  OperationUnit copyWith({
    String? id,
    String? uid,
    int? index,
    String? name,
    String? deviceId,
    String? updatedWhen,

    String? user,
    String? sensor,
    String? status,

  }) {
    return OperationUnit(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      index: index ?? this.index,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      updatedWhen: updatedWhen ?? this.updatedWhen,

      user: user ?? this.user,
      sensor: sensor ?? this.sensor,
      status: status ?? this.status,
    );
  }

  @override
  int get hashCode =>
      id.hashCode ^
      uid.hashCode ^
      index.hashCode ^
      name.hashCode ^
      deviceId.hashCode ^
      updatedWhen.hashCode ^
      user.hashCode ^
      sensor.hashCode ^
      status.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationUnit &&

          runtimeType == other.runtimeType &&
          id == other.id &&
          uid == other.uid &&
          index == other.index &&
          deviceId == other.deviceId &&
          updatedWhen == other.updatedWhen &&

          user == other.user &&
          sensor == other.sensor &&
          status == other.status &&

          name == other.name; // &&

  @override
  String toString() {
    return 'OperationUnit { id: $id, '
        'uid: $uid, '
        'index: $index, '
        'name: $name, '
        'deviceId: $deviceId, '
        'updatedWhen: $updatedWhen, '
        'user: $user, '
        'sensor: $sensor, '
        'status: $status}';
  }

  ItemEntity toEntity() {
    return ItemEntity(id, uid, index, name);
  }

  static OperationUnit fromEntity(ItemEntity entity) {
    return OperationUnit(
      id: entity.id,
      uid: entity.uid,
      index: entity.index,
      name: entity.name,
    );
  }

  factory OperationUnit.fromJson(Map<dynamic, dynamic> json) {
    print('OperationUnit.fromJson json= ${json}');
    return OperationUnit(
      uid: json['uid'] ?? '',
      deviceId: json['deviceId'] ?? '',
      user: json['user'] ?? '',
      sensor: json['sensor'] ?? '',
      status: json['status'] ?? '',
    );
  }


}