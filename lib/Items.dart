// enum ItemType { link, folder }

// class Item {
//   String name;
//   ItemType type;

//   Item(this.name, this.type);
// }

// class Link extends Item {
//   String url;

//   Link(String name, this.url) : super(name, ItemType.link);
// }

// class Folder extends Item {
//   List<Item> children;

//   Folder.empty(String name)
//       : this.children = List<Item>(),
//         super(name, ItemType.folder);
//   Folder.withChildren(String name, List<Item> children)
//       : this.children = children,
//         super(name, ItemType.folder);
// }
