import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';

class Scenario extends Equatable {
  final String caption;
  final String description;
  final String guide;
  final String iconImage;
  final int index;

  Scenario({
    String caption = '',
    String description = '',
    String guide = '',
    String iconImage = '',
    int index = 0}) :
        this.caption = caption ?? '',
        this.description = description ?? '',
        this.guide = guide ?? '',
        this.iconImage = iconImage ?? '',
        this.index = index ?? 0 ;

  @override
  List<Object> get props => [iconImage, caption, index, description, guide];

  @override
  String toString() {
    return 'Scenario { iconImage: $iconImage, caption: $caption, index: $index, description: $description, guide: $guide, }';
  }

  Map<String, Object> toJson() {
    return {
      "iconImage": iconImage,
      "caption": caption,
      "index": index,
      "description": description,
      "guide": guide,
    };
  }

  static Scenario fromJson(Map<String, Object> json) {
    return Scenario(
      caption: json["caption"] as String,
      description: json["description"] as String,
      guide: json["guide"] as String,
      iconImage: json["iconImage"] as String,
      index: json["index"] as int,

    );
  }

  // static Scenario fromSnapshot(DataSnapshot snap) {
  //   return Scenario(
  //     iconImage: snap.value['iconImage'] ?? '',
  //     description: snap.value['description'] ?? '',
  //     guide: snap.value['guide'] ?? '',
  //     caption: snap.value['caption'] ?? '',
  //     index: int.parse(snap.value['index']) ?? -1,
  //   );
  // }

  Map<String, Object> toDocument() {
    return {
      "iconImage": iconImage,
      "caption": caption,
      "index": index,
      "description": description,
      "guide": guide,
    };
  }
}

