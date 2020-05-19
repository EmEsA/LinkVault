import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:link_vault/EditForm.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:link_vault/models/Item.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share/share.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ext_storage/ext_storage.dart';
import 'main.dart';

enum MenuOption { export, import }

class LinkPage extends StatefulWidget {
  LinkPage({Key key, this.box, this.folder}) : super(key: key);
  final Box box;
  final Item folder;
  @override
  _LinkPageState createState() => _LinkPageState();
}

class _LinkPageState extends State<LinkPage> {
  void _addItem(Item item) {
    widget.folder.children.add(item);
    widget.folder.save();
    Navigator.pop(context);
  }

  void _updateItem(Item item) async {
    await item.save();
    widget.folder.save();
    Navigator.pop(context);
  }

  void _deleteItem(Item item) async {
    await item.delete();
    widget.folder.save();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }

  void _pushEditScreen(
      BuildContext context, Item item, void Function(Item item) handleSave) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return ItemEditForm(item, _getChildrenNames(widget.folder), handleSave);
    }));
  }

  void _pushFolderEnteredScreen(BuildContext context, Item folder) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return LinkPage(box: widget.box, folder: folder);
    })).then((_) {
      setState(() => {});
    });
  }

  Widget _buildPage(BuildContext context) {
    var body = ValueListenableBuilder(
      valueListenable: widget.box.listenable(keys: [widget.folder.key]),
      builder: (context, box, wdg) {
        return _buildList(context, widget.folder);
      },
    );

    var actions = <Widget>[
      IconButton(
        icon: Icon(Icons.home),
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
      Builder(
        builder: (context) {
          return PopupMenuButton(
            offset: Offset(10, 50),
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<MenuOption>>[
                PopupMenuItem(
                  value: MenuOption.export,
                  child: ListTile(
                    leading: Icon(Icons.backup),
                    title: Text('Export folder'),
                  ),
                ),
                PopupMenuItem(
                  value: MenuOption.import,
                  child: ListTile(
                    leading: Icon(Icons.restore),
                    title: Text('Import into folder'),
                  ),
                ),
              ];
            },
            onSelected: (MenuOption option) => _handleMenu(context, option),
          );
        },
      ),
    ];

    var itemMoveData = context.watch<ItemMoveData>();
    if (itemMoveData.itemsToMove.length != 0) {
      actions.insertAll(0, <Widget>[
        IconButton(
          icon: Icon(Icons.content_paste),
          onPressed: () =>
              setState(() => _moveItems(context, itemMoveData, widget.folder)),
        ),
        IconButton(
          icon: Icon(Icons.cancel),
          onPressed: () => setState(() => itemMoveData.clear()),
        ),
      ]);
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.folder.name),
          actions: actions,
        ),
        body: Center(
          child: body,
        ),
        floatingActionButton: _buildSpeedDial(context));
  }

  ListView _buildList(BuildContext context, Item folder) {
    HiveList<Item> children = Hive.box<Item>('links').get(folder.key).children;
    if (children != null) {
      children.sort((c1, c2) {
        if (c1.type != c2.type) {
          if (c1.type == ItemType.folder) {
            return -1;
          } else {
            return 1;
          }
        }
        return c1.name.compareTo(c2.name);
      });
    }
    return children == null || children.length == 0
        ? ListView()
        : ListView(children: _buildChildren(context, children));
  }

  List<Widget> _buildChildren(BuildContext context, HiveList<Item> children) {
    var l = List<Widget>();
    children.forEach((item) {
      l.add(_buildItem(context, item));
    });
    return l;
  }

  Widget _buildItem(BuildContext context, Item item) {
    if (item.type == ItemType.folder) {
      return _buildFolder(context, item);
    } else {
      return _buildLink(context, item);
    }
  }

  Slidable _buildFolder(BuildContext context, Item item) {
    var itemMoveData = Provider.of<ItemMoveData>(context, listen: false);
    return Slidable(
      key: ObjectKey(item),
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: Container(
        height: 80,
        alignment: Alignment.center,
        child: ListTile(
          leading: Icon(Icons.folder,
              color: itemMoveData.itemsToMove.containsKey(item.key)
                  ? Colors.grey[600]
                  : Theme.of(context).buttonColor),
          title: Text(
            item.name,
            style: TextStyle(
                color: itemMoveData.itemsToMove != null &&
                        itemMoveData.itemsToMove.containsKey(item.key)
                    ? Colors.grey[600]
                    : Colors.white),
          ),
          onTap: () => _pushFolderEnteredScreen(context, item),
          onLongPress: () => setState(() {
            if (itemMoveData.itemsToMove.containsKey(item.key)) {
              // itemMoveData.clear();
              itemMoveData.itemsToMove.remove(item.key);
            } else {
              itemMoveData.add(item, widget.folder);
            }
          }),
        ),
      ),
      secondaryActions: <Widget>[
        IconSlideAction(
            caption: 'Delete',
            color: Colors.red,
            icon: Icons.delete,
            onTap: () {
              _deleteItem(item);
            }),
        IconSlideAction(
          caption: 'Edit',
          color: Colors.green,
          icon: Icons.edit,
          onTap: () => _pushEditScreen(context, item, _updateItem),
        )
      ],
    );
  }

  Slidable _buildLink(BuildContext context, Item item) {
    var itemMoveData = Provider.of<ItemMoveData>(context, listen: false);
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.25,
      child: Container(
        height: 80,
        alignment: Alignment.center,
        child: ListTile(
          leading: Icon(Icons.link,
              color: itemMoveData.itemsToMove.containsKey(item.key)
                  ? Colors.grey[600]
                  : Theme.of(context).buttonColor),
          title: Text(
            item.name,
            style: TextStyle(
                color: itemMoveData.itemsToMove != null &&
                        itemMoveData.itemsToMove.containsKey(item.key)
                    ? Colors.grey[600]
                    : Colors.white),
          ),
          onTap: () => _launchURL(context, item.url),
          onLongPress: () {
            setState(() {
              if (itemMoveData.itemsToMove.containsKey(item.key)) {
                // itemMoveData.clear();
                itemMoveData.itemsToMove.remove(item.key);
              } else {
                itemMoveData.add(item, widget.folder);
              }
            });
          },
        ),
      ),
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => _deleteItem(item),
        ),
        IconSlideAction(
          caption: 'Edit',
          color: Colors.green,
          icon: Icons.edit,
          onTap: () => _pushEditScreen(context, item, _updateItem),
        )
      ],
      actions: <Widget>[
        IconSlideAction(
          caption: 'Share',
          color: Colors.blue,
          icon: Icons.share,
          onTap: () => Share.share(item.url,
              subject:
                  'Check out this link'), //_copyToClipboard(context, item.url),
        )
      ],
    );
  }

  SpeedDial _buildSpeedDial(BuildContext context) {
    final linkBox = Hive.box<Item>('links');
    return SpeedDial(
      child: Icon(
        Icons.add,
        color: Colors.black,
      ),
      overlayOpacity: 0,
      children: [
        _speedDialChild(Icons.link, 'Add link',
            () => _pushEditScreen(context, Item.newLink(), _addItem)),
        _speedDialChild(Icons.folder, 'Add folder',
            () => _pushEditScreen(context, Item.newFolder(linkBox), _addItem))
      ],
    );
  }

  SpeedDialChild _speedDialChild(
      IconData icon, String labelText, Function callback) {
    return SpeedDialChild(
        labelWidget: _label(labelText),
        child: Icon(
          icon,
          color: Colors.black,
        ),
        onTap: callback //_pushEditLinkScreen(ItemType.link, widget.items),
        );
  }

  Container _label(String text) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).buttonColor,
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  List<String> _getChildrenNames(Item folder) {
    var names = <String>[];
    folder.children.forEach((item) => names.add(item.name));
    return names;
  }

  void _handleMenu(BuildContext context, MenuOption option) async {
    if (await Permission.storage.request().isGranted) {
      if (option == MenuOption.export) {
        var filePath = await _exportFolder(context, widget.box, widget.folder);
        if (filePath != null) {
          Scaffold.of(context).showSnackBar(SnackBar(
            content:
                Text("Exported to ${filePath}.", textAlign: TextAlign.center),
          ));
        }
      } else {
        var filePath = await _importFolder(context, widget.box, widget.folder);
        if (filePath != null) {
          widget.folder.save();
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text("Imported ${filePath}", textAlign: TextAlign.center),
          ));
        }
      }
    }
  }
}

_launchURL(BuildContext context, String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("Cannot open url, check if it's valid.",
          textAlign: TextAlign.center),
    ));
  }
}

Future<String> _exportFolder(BuildContext context, Box box, Item folder) async {
  var _isProcessing = false;
  var storagePath = await ExtStorage.getExternalStorageDirectory();
  var _controller =
      TextEditingController(text: '$storagePath/LinkVault/${folder.name}.json');

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        if (!_isProcessing) {
          return AlertDialog(
            title: Text("Export file path:"),
            content: TextField(
              controller: _controller,
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Ok'),
                onPressed: () {
                  setState(() => _isProcessing = true);

                  var keysToExport = <String>[];
                  folder.children.forEach((Item item) {
                    keysToExport.add(item.key);
                  });
                  var filteredKeys = box.values
                      .where((item) => keysToExport.contains(item.key));

                  final file = File(_controller.text);
                  Directory(file.parent.path).createSync();
                  var encoder = JsonEncoder.withIndent('  ');
                  file.writeAsStringSync(
                      encoder.convert(filteredKeys.toList()));
                  Navigator.of(context).pop(_controller.text);
                },
              )
            ],
          );
        } else {
          return AlertDialog(
              title: Text("Exporting..."),
              content: Center(
                heightFactor: 1,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[300]),
                ),
              ));
        }
      },
    ),
  );
}

Future<String> _importFolder(BuildContext context, Box box, Item folder) async {
  File file = await FilePicker.getFile(
      type: FileType.custom, allowedExtensions: ['json']);
  if (file == null) {
    return null;
  }

  var _controller = TextEditingController(text: file.path);
  _controller.selection =
      TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
  var _isProcessing = false;
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        if (!_isProcessing) {
          return AlertDialog(
            title: Text("Import from path:"),
            content: TextField(
              controller: _controller,
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Ok'),
                onPressed: () {
                  setState(() => _isProcessing = true);
                  var jsonString = file.readAsStringSync();
                  (json.decode(jsonString) as List)
                      .forEach((item) => _importItem(box, item, folder));
                  Navigator.of(context).pop(_controller.text);
                },
              )
            ],
          );
        } else {
          return AlertDialog(
              title: Text("Importing..."),
              content: Center(
                heightFactor: 1,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[300]),
                ),
              ));
        }
      },
    ),
  );
}

_importItem(Box box, Map<String, dynamic> json, Item folder) {
  var item = Item(_itemTypefromString(json['type']), json['name'], json['url'],
      HiveList(box));
  box.put(uuid.v4(), item);
  folder.children.add(item);
  var children = json['children'];
  if (children != null)
    (json['children'] as List).forEach((child) {
      _importItem(box, child, item);
    });
}

_itemTypefromString(String type) {
  for (ItemType itemType in ItemType.values) {
    if (itemType.toString() == type) {
      return itemType;
    }
  }
  return null;
}

void _moveItems(BuildContext context, ItemMoveData itemMoveData, Item folder) {
  itemMoveData.itemsToMove.forEach((_, itemToMove) {
    folder.children.add(itemToMove.item);
    itemToMove.parentFolder.children.remove(itemToMove.item);
    itemToMove.parentFolder.save();
    folder.save();
  });
  itemMoveData.clear();
}
