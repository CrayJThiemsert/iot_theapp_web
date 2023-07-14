import 'package:iot_theapp_web/pages/device/entity/item_entity.dart';
import 'package:meta/meta.dart';

@immutable
class Item {
  final String id;
  final String uid;
  final int index;
  final String name;
  // List<Header> headers;
  // List<ItemData> itemDatas;
  // Topic topic;

  Item({
    String? id,
    String? uid,
    int index = 0,
    String name = '',
    // List<Header> headers,
    // List<ItemData> itemDatas,
    // Topic topic,
  })
    : this.index = index ?? 0,
      this.name = name ?? '',
      this.id = id ?? '',
      this.uid = uid ?? ''
      // this.headers = headers,
      // this.itemDatas = itemDatas,
      // this.topic = topic
    ;

  Item copyWith({
    String? id,
    String? uid,
    int? index,
    String? name,
    // List<Header> headers,
    // List<ItemData> itemDatas,
    // Topic topic,
  }) {
    return Item(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      index: index ?? this.index,
      name: name ?? this.name,
      // headers: headers ?? this.headers,
      // itemDatas: itemDatas ?? this.itemDatas,
      // topic: topic ?? this.topic,
    );
  }

  @override
  int get hashCode =>
      id.hashCode ^ uid.hashCode ^ index.hashCode ^ name.hashCode; // ^ topic.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        uid == other.uid &&
        index == other.index &&
        name == other.name; // &&
        // headers == other.headers &&
        // itemDatas == other.itemDatas &&
        // topic == other.topic;

  @override
  String toString() {
    return 'Item { id: $id, uid: $uid, index: $index, name: $name}'; //, headers: $headers, itemDatas: ${itemDatas}, topic: ${topic} }';
  }

  ItemEntity toEntity() {
    return ItemEntity(id, uid, index, name);
  }

  static Item fromEntity(ItemEntity entity) {
    return Item(
      id: entity.id,
      uid: entity.uid,
      index: entity.index,
      name: entity.name,
    );
  }
}