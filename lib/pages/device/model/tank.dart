import 'package:iot_theapp_web/pages/device/entity/item_entity.dart';
import 'package:iot_theapp_web/pages/device/model/item.dart';
import 'package:meta/meta.dart';

@immutable
class Tank extends Item{
  final String id;
  final String uid;
  final int index;
  final String name;
  final String deviceId;

  final String updatedWhen;

  String wTankType;
  double wRangeDistance;
  double wFilledDepth;
  double wHeight;
  double wWidth;
  double wDiameter;
  double wSideLength;
  double wLength;
  double wCapacity;
  double wOffset;

  Tank({
    String? id,
    String? uid,
    int index = 0,
    String name = '',
    String deviceId = '',

    String updatedWhen = '',

    String wTankType = '',
    double wRangeDistance = 0,
    double wFilledDepth = 0,
    double wHeight = 0,
    double wWidth = 0,
    double wDiameter = 0,
    double wSideLength = 0,
    double wLength = 0,
    double wCapacity = 0,
    double wOffset = 0,

  })
    : this.index = index,
      this.name = name ?? '',
      this.deviceId = deviceId ?? '',

      this.id = id ?? '',
      this.uid = uid ?? '',
      this.updatedWhen = updatedWhen ?? '',


      this.wTankType = wTankType ?? '',
      this.wRangeDistance = wRangeDistance ?? 0,
      this.wFilledDepth = wFilledDepth ?? 0,
      this.wHeight = wHeight ?? 0,
      this.wWidth = wWidth ?? 0,
      this.wDiameter = wDiameter ?? 0,
      this.wSideLength = wSideLength ?? 0,
      this.wLength = wLength ?? 0,
      this.wCapacity = wCapacity ?? 0,
      this.wOffset = wOffset ?? 0
    ;

  Tank copyWith({
    String? id,
    String? uid,
    int? index,
    String? name,
    String? deviceId,
    String? updatedWhen,

    String? wTankType,
    double? wRangeDistance,
    double? wFilledDepth,
    double? wHeight,
    double? wWidth,
    double? wDiameter,
    double? wSideLength,
    double? wLength,
    double? wCapacity,
    double? wOffset,

  }) {
    return Tank(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      index: index ?? this.index,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      updatedWhen: updatedWhen ?? this.updatedWhen,

      wTankType: wTankType ?? this.wTankType,
      wRangeDistance: wRangeDistance ?? this.wRangeDistance,
      wFilledDepth: wFilledDepth ?? this.wFilledDepth,
      wHeight: wHeight ?? this.wHeight,
      wWidth: wWidth ?? this.wWidth,
      wDiameter: wDiameter ?? this.wDiameter,
      wSideLength: wSideLength ?? this.wSideLength,
      wLength: wLength ?? this.wLength,
      wCapacity: wCapacity ?? this.wCapacity,
      wOffset: wOffset ?? this.wOffset,
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
      wTankType.hashCode ^
      wFilledDepth.hashCode ^
      wRangeDistance.hashCode ^
      wHeight.hashCode ^
      wWidth.hashCode ^
      wDiameter.hashCode ^
      wSideLength.hashCode ^
      wLength.hashCode ^
      wCapacity.hashCode ^
      wOffset.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tank &&

          runtimeType == other.runtimeType &&
          id == other.id &&
          uid == other.uid &&
          index == other.index &&
          deviceId == other.deviceId &&
          updatedWhen == other.updatedWhen &&

          wTankType == other.wTankType &&
          wRangeDistance == other.wRangeDistance &&
          wFilledDepth == other.wFilledDepth &&
          wHeight == other.wHeight &&
          wWidth == other.wWidth &&

          wDiameter == other.wDiameter &&
          wSideLength == other.wSideLength &&
          wLength == other.wLength &&
          wCapacity == other.wCapacity &&
          wOffset == other.wOffset &&

          name == other.name; // &&

  @override
  String toString() {
    return 'Tank { id: $id, '
        'uid: $uid, '
        'index: $index, '
        'name: $name, '
        'deviceId: $deviceId, '
        'updatedWhen: $updatedWhen, '
        'wTankType: $wTankType, '
        'wRangeDistance: $wRangeDistance, '
        'wFilledDepth: $wFilledDepth, '
        'wHeight: $wHeight, '
        'wWidth: $wWidth, '
        'wDiameter: $wDiameter, '
        'wSideLength: $wSideLength, '
        'wLength: $wLength, '
        'wLength: $wLength, '
        'wOffset: $wOffset}';
  }

  ItemEntity toEntity() {
    return ItemEntity(id, uid, index, name);
  }

  static Tank fromEntity(ItemEntity entity) {
    return Tank(
      id: entity.id,
      uid: entity.uid,
      index: entity.index,
      name: entity.name,
    );
  }

  factory Tank.fromJson(Map<dynamic, dynamic> json) {
    print('Tank.fromJson json= ${json}');
    return Tank(
      uid: json['uid'] ?? '',
      deviceId: json['deviceId'] ?? '',
      wTankType: json['wTankType'] ?? '',
      wRangeDistance: json['wRangeDistance']?.toDouble() ?? 0,
      wFilledDepth: json['wFilledDepth']?.toDouble() ?? 0,
      wHeight: json['wHeight']?.toDouble() ?? 0,
      wWidth: json['wWidth']?.toDouble() ?? 0,
      wDiameter: json['wDiameter']?.toDouble() ?? 0,
      wSideLength: json['wSideLength']?.toDouble() ?? 0,
      wLength: json['wLength']?.toDouble() ?? 0,
      wCapacity: json['wCapacity']?.toDouble() ?? 0,
      wOffset: json['wOffset']?.toDouble() ?? 0,
    );
  }


}
