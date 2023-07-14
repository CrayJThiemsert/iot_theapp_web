import 'package:iot_theapp_web/pages/device/entity/item_entity.dart';
import 'package:iot_theapp_web/pages/device/model/item.dart';
import 'package:meta/meta.dart';

@immutable
class OperatedLog extends Item{
  final String id;

  String uid;
  final int index;
  final String name;


  String mqttMsg;
  String updatedWhen;

  OperatedLog({
    String? id,
    String? uid,
    int index = 0,
    String name = '',
    String mqttMsg = '',
    String updatedWhen = '',
  })
    : this.index = index,
      this.name = name ?? '',
      this.mqttMsg = mqttMsg ?? '',
      this.id = id ?? '',
      this.uid = uid ?? '',
      this.updatedWhen = updatedWhen ?? '';

  OperatedLog copyWith({
    String? id,
    String? uid,
    int? index,
    String? name,
    String? mqttMsg,

    String? updatedWhen,

  }) {
    return OperatedLog(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      index: index ?? this.index,
      name: name ?? this.name,
      mqttMsg: mqttMsg ?? this.mqttMsg,
      updatedWhen: updatedWhen ?? this.updatedWhen,
    );
  }

  @override
  int get hashCode =>
      id.hashCode ^
      uid.hashCode ^
      index.hashCode ^
      name.hashCode ^
      mqttMsg.hashCode ^
      updatedWhen.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperatedLog &&

          runtimeType == other.runtimeType &&
          id == other.id &&
          uid == other.uid &&
          index == other.index &&
          mqttMsg == other.mqttMsg &&

          updatedWhen == other.updatedWhen &&

          name == other.name; // &&

  @override
  String toString() {
    return 'OperatedLog { id: $id, '
        'uid: $uid, '
        'index: $index, '
        'name: $name, '
        'mqttMsg: $mqttMsg, '
        'updatedWhen: $updatedWhen}';
  }

  ItemEntity toEntity() {
    return ItemEntity(id, uid, index, name);
  }

  static OperatedLog fromEntity(ItemEntity entity) {
    return OperatedLog(
      id: entity.id,
      uid: entity.uid,
      index: entity.index,
      name: entity.name,
    );
  }

  factory OperatedLog.fromJson(Map<dynamic, dynamic> json) {
    print('OperatedLog.fromJson json= ${json}');
    return OperatedLog(
      uid: json['uid'] ?? '',
      mqttMsg: json['mqttMsg'] ?? '',
      updatedWhen: json['updatedWhen'] ?? '',
    );
  }


}