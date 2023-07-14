import 'package:iot_theapp_web/pages/device/entity/item_entity.dart';
import 'package:iot_theapp_web/pages/device/model/item.dart';
import 'package:meta/meta.dart';

@immutable
class Notification extends Item{
  final String id;
  final String uid;
  final int index;
  final String name;
  final String deviceId;

  final String updatedWhen;

  double notifyHumidLower;
  double notifyHumidHigher;
  double notifyTempLower;
  double notifyTempHigher;
  double notifyTOFDistanceLower;
  double notifyTOFDistanceHigher;
  String notifyEmail;
  bool isSendNotify;



  Notification({
    String? id,
    String? uid,
    int index = 0,
    String name = '',
    String deviceId = '',

    String updatedWhen = '',

    double notifyHumidLower = 0,
    double notifyHumidHigher = 0,
    double notifyTempLower = 0,
    double notifyTempHigher = 0,
    double notifyTOFDistanceHigher = 0,
    double notifyTOFDistanceLower = 0,
    String notifyEmail = '',
    bool isSendNotify = true,
  })
    : this.index = index,
      this.name = name ?? '',
      this.deviceId = deviceId ?? '',

      this.id = id ?? '',
      this.uid = uid ?? '',
      this.updatedWhen = updatedWhen ?? '',


      this.notifyHumidLower = notifyHumidLower ?? 0,
      this.notifyHumidHigher = notifyHumidHigher ?? 0,
      this.notifyTempLower = notifyTempLower ?? 0,
      this.notifyTempHigher = notifyTempHigher ?? 0,
      this.notifyTOFDistanceHigher = notifyTOFDistanceHigher ?? 0,
      this.notifyTOFDistanceLower = notifyTOFDistanceLower ?? 0,
      this.notifyEmail = notifyEmail ?? '',
        this.isSendNotify = isSendNotify ?? false

    ;

  Notification copyWith({
    String? id,
    String? uid,
    int? index,
    String? name,
    String? deviceId,
    String? updatedWhen,

    double? notifyHumidLower,
    double? notifyHumidHigher,
    double? notifyTempLower,
    double? notifyTempHigher,
    double? notifyTOFDistanceLower,
    double? notifyTOFDistanceHigher,

    String? notifyEmail,
    bool? isSendNotify,

  }) {
    return Notification(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      index: index ?? this.index,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      updatedWhen: updatedWhen ?? this.updatedWhen,

      notifyHumidLower: notifyHumidLower ?? this.notifyHumidLower,
      notifyHumidHigher: notifyHumidHigher ?? this.notifyHumidHigher,
      notifyTempLower: notifyTempLower ?? this.notifyTempLower,
      notifyTempHigher: notifyTempHigher ?? this.notifyTempHigher,
      notifyTOFDistanceLower: notifyTOFDistanceLower ?? this.notifyTOFDistanceLower,
      notifyTOFDistanceHigher: notifyTOFDistanceHigher ?? this.notifyTOFDistanceHigher,
      notifyEmail: notifyEmail ?? this.notifyEmail,
      isSendNotify: isSendNotify ?? this.isSendNotify,
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
      notifyHumidLower.hashCode ^
      notifyHumidHigher.hashCode ^
      notifyTempLower.hashCode ^
      notifyTempHigher.hashCode ^
      notifyTOFDistanceLower.hashCode ^
      notifyTOFDistanceHigher.hashCode ^
      notifyEmail.hashCode ^
      isSendNotify.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notification &&

          runtimeType == other.runtimeType &&
          id == other.id &&
          uid == other.uid &&
          index == other.index &&
          deviceId == other.deviceId &&
          updatedWhen == other.updatedWhen &&

          notifyHumidLower == other.notifyHumidLower &&
          notifyHumidHigher == other.notifyHumidHigher &&
          notifyTempLower == other.notifyTempLower &&
          notifyTempHigher == other.notifyTempHigher &&
          notifyTOFDistanceLower == other.notifyTOFDistanceLower &&
          notifyTOFDistanceHigher == other.notifyTOFDistanceHigher &&

          notifyEmail == other.notifyEmail &&
          isSendNotify == other.isSendNotify &&

          name == other.name; // &&

  @override
  String toString() {
    return 'Notification { id: $id, uid: $uid, index: $index, name: $name, deviceId: $deviceId, updatedWhen: $updatedWhen, notifyHumidLower: $notifyHumidLower, notifyHumidHigher: $notifyHumidHigher, notifyTempLower: $notifyTempLower, notifyTempHigher: $notifyTempHigher, notifyEmail: $notifyEmail, isSendNotify: $isSendNotify}';
  }

  ItemEntity toEntity() {
    return ItemEntity(id, uid, index, name);
  }

  static Notification fromEntity(ItemEntity entity) {
    return Notification(
      id: entity.id,
      uid: entity.uid,
      index: entity.index,
      name: entity.name,
    );
  }

  factory Notification.fromJson(Map<dynamic, dynamic> json) {
    // print('Notification.fromJson json= ${json}');
    return Notification(
      uid: json['uid'] ?? '',
      deviceId: json['deviceId'] ?? '',
      notifyEmail: json['notifyEmail'] ?? '',
      isSendNotify: json['isSendNotify'] ?? false,
      notifyHumidLower: json['notifyHumidLower']?.toDouble() ?? 0,
      notifyHumidHigher: json['notifyHumidHigher']?.toDouble() ?? 0,
      notifyTempLower: json['notifyTempLower']?.toDouble() ?? 0,
      notifyTempHigher: json['notifyTempHigher']?.toDouble() ?? 0,
      notifyTOFDistanceLower: json['notifyTOFDistanceLower']?.toDouble() ?? 0,
      notifyTOFDistanceHigher: json['notifyTOFDistanceHigher']?.toDouble() ?? 0,
    );
  }


}