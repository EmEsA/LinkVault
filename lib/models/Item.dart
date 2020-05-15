import 'package:hive/hive.dart';

part 'Item.g.dart';

@HiveType(typeId: 0)
enum ItemType {
  @HiveField(0)
  folder,
  @HiveField(1)
  link,
}

// ItemType getItemTypeFromString(String typeAsString) {
//   for (ItemType itemType in ItemType.values) {
//     if (itemType.toString() == typeAsString) {
//       return itemType;
//     }
//   }
//   return null;
// }

@HiveType(typeId: 1)
class Item extends HiveObject {
  @HiveField(0)
  ItemType type;
  @HiveField(1)
  String name;
  @HiveField(3)
  String url;
  @HiveField(4)
  HiveList<Item> children;

  Item(this.type, this.name, this.url, this.children);

  Item.folder(this.name, this.children)
      : this.type = ItemType.folder,
        this.url = null;

  Item.newFolder(Box box)
      : this.name = null,
        this.type = ItemType.folder,
        this.url = null,
        this.children = HiveList<Item>(box);

  Item.link(this.name, this.url)
      : this.type = ItemType.link,
        this.children = null;

  Item.newLink()
      : this.type = ItemType.link,
        this.name = null,
        this.url = null;

  toJson() {
    return {
      'type': this.type.toString(),
      'name': this.name,
      'url': this.url,
      'children': this.children,
    };
  }

  // Item.fromJson(Box box, Map<String, dynamic> json)
  //     : type = getItemTypeFromString(json['type']),
  //       name = json['name'],
  //       url = json['url'],
  //       children = null;
}
