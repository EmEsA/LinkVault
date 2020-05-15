// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemTypeAdapter extends TypeAdapter<ItemType> {
  @override
  final typeId = 0;

  @override
  ItemType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ItemType.folder;
      case 1:
        return ItemType.link;
      default:
        return null;
    }
  }

  @override
  void write(BinaryWriter writer, ItemType obj) {
    switch (obj) {
      case ItemType.folder:
        writer.writeByte(0);
        break;
      case ItemType.link:
        writer.writeByte(1);
        break;
    }
  }
}

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final typeId = 1;

  @override
  Item read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Item(
      fields[0] as ItemType,
      fields[1] as String,
      fields[3] as String,
      (fields[4] as HiveList)?.castHiveList(),
    );
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.children);
  }
}
