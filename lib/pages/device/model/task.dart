import 'package:iot_theapp_web/pages/device/entity/item_entity.dart';
import 'package:iot_theapp_web/pages/device/model/item.dart';
import 'package:meta/meta.dart';

@immutable
class Task extends Item{
  final String id;

  String uid;
  final int index;
  final String name;


  String operationDeviceId;
  String operationMode;
  int operationPeriod;
  String command;
  int readingInterval;

  String updatedWhen;
  String expectedWhen;

  String user;
  String sensor;
  String status;

  Task({
    String? id,
    String? uid,
    int index = 0,
    String name = '',
    String operationDeviceId = '',

    String operationMode = '',
    int operationPeriod  = 0,
    String command = '',
    int readingInterval = 0,

    String updatedWhen = '',
    String expectedWhen = '',

    String user = '',
    String sensor = '',
    String status = '',
  })
    : this.index = index,
      this.name = name ?? '',
      this.operationDeviceId = operationDeviceId ?? '',

      this.id = id ?? '',
      this.uid = uid ?? '',

      this.operationMode = operationMode ?? '',
      this.operationPeriod = operationPeriod,
      this.command = command ?? '',
      this.readingInterval = readingInterval,

      this.updatedWhen = updatedWhen ?? '',
      this.expectedWhen = expectedWhen ?? '',

      this.user = user ?? '',
      this.sensor = sensor ?? '',
      this.status = status ?? '';

  Task copyWith({
    String? id,
    String? uid,
    int? index,
    String? name,
    String? operationDeviceId,

    String? operationMode,
    int? operationPeriod,
    String? command,
    int? readingInterval,

    String? updatedWhen,
    String? expectedWhen,

    String? user,
    String? sensor,
    String? status,

  }) {
    return Task(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      index: index ?? this.index,
      name: name ?? this.name,
      operationDeviceId: operationDeviceId ?? this.operationDeviceId,

      operationMode: operationMode ?? this.operationMode,
      operationPeriod: operationPeriod ?? this.operationPeriod,
      command: command ?? this.command,
      readingInterval: readingInterval ?? this.readingInterval,

      updatedWhen: updatedWhen ?? this.updatedWhen,
      expectedWhen: expectedWhen ?? this.expectedWhen,

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
      operationDeviceId.hashCode ^

      operationMode.hashCode ^
      operationPeriod.hashCode ^
      command.hashCode ^
      readingInterval.hashCode ^

      updatedWhen.hashCode ^
      expectedWhen.hashCode ^
      user.hashCode ^
      sensor.hashCode ^
      status.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&

          runtimeType == other.runtimeType &&
          id == other.id &&
          uid == other.uid &&
          index == other.index &&
          operationDeviceId == other.operationDeviceId &&

          operationMode == other.operationMode &&
          operationPeriod == other.operationPeriod &&
          command == other.command &&
          readingInterval == other.readingInterval &&

          updatedWhen == other.updatedWhen &&
          expectedWhen == other.expectedWhen &&

          user == other.user &&
          sensor == other.sensor &&
          status == other.status &&

          name == other.name; // &&

  @override
  String toString() {
    return 'Task { id: $id, '
        'uid: $uid, '
        'index: $index, '
        'name: $name, '
        'operationDeviceId: $operationDeviceId, '

        'operationMode: $operationMode, '
        'operationPeriod: $operationPeriod, '
        'command: $command, '
        'readingInterval: $readingInterval, '

        'updatedWhen: $updatedWhen, '
        'expectedWhen: $expectedWhen, '
        'user: $user, '
        'sensor: $sensor, '
        'status: $status}';
  }

  ItemEntity toEntity() {
    return ItemEntity(id, uid, index, name);
  }

  static Task fromEntity(ItemEntity entity) {
    return Task(
      id: entity.id,
      uid: entity.uid,
      index: entity.index,
      name: entity.name,
    );
  }

  factory Task.fromJson(Map<dynamic, dynamic> json) {
    // print('Task.fromJson json= ${json}');
    return Task(
      uid: json['uid'] ?? '',
      operationDeviceId: json['operationDeviceId'] ?? '',
      operationMode: json['operationMode'] ?? '',
      operationPeriod: json['operationPeriod'] ?? '',
      command: json['command'] ?? '',
      readingInterval: json['readingInterval'] ?? '',
      updatedWhen: json['updatedWhen'] ?? '',
      expectedWhen: json['expectedWhen'] ?? '',
      user: json['user'] ?? '',
      sensor: json['sensor'] ?? '',
      status: json['status'] ?? '',
    );
  }


}