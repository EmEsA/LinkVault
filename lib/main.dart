import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:link_vault/LinkPage.dart';
import 'package:link_vault/models/Item.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:provider/provider.dart';

const rootFolderName = 'Link Vault';

class ItemToMove {
  Item item;
  Item parentFolder;

  ItemToMove(this.item, this.parentFolder);
}

class ItemMoveData {
  Map<String, ItemToMove> itemsToMove;

  ItemMoveData() : itemsToMove = Map<String, ItemToMove>();

  void clear() {
    this.itemsToMove = Map();
  }

  void add(Item item, Item parentFolder) {
    this.itemsToMove[item.key] = ItemToMove(item, parentFolder);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDirectory =
      await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(ItemTypeAdapter());
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Provider<ItemMoveData>(
      create: (BuildContext context) => ItemMoveData(),
      child: MaterialApp(
        title: 'Link Vault',
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        home: FutureBuilder(
          future: Hive.openBox<Item>('links'),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              }
              var linkBox = Hive.box<Item>('links');
              print(linkBox.length);
              if (linkBox.get(rootFolderName) == null) {
                linkBox.put(rootFolderName,
                    Item.folder(rootFolderName, HiveList<Item>(linkBox)));
              }
              return LinkPage(
                box: linkBox,
                folder: linkBox.get(rootFolderName),
                path: <String>['Link Vault'],
              );
            }
            return Scaffold();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    Hive.box<Item>('links').compact();
    Hive.close();
    super.dispose();
  }
}

ThemeData _theme() {
  return ThemeData(
    // Define the default brightness and colors.
    brightness: Brightness.dark,
    primaryColor: Colors.teal,
    accentColor: Colors.teal[300],
    buttonColor: Colors.teal[300],
    cursorColor: Colors.teal[300],
    iconTheme: IconThemeData(color: Colors.teal[300]),
    errorColor: Colors.orange[500],
    snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.teal[300],
        contentTextStyle: TextStyle(color: Colors.black)),
    appBarTheme: AppBarTheme(
      textTheme: TextTheme(
          headline6: TextStyle(
        color: Colors.white,
        fontSize: 20,
      )),
    ),
  );
}

// int nameComparator(dynamic k1, dynamic k2) {
//   var linkBox = Hive.box<Item>('links');
//   var k1Name = linkBox.get(k1).name;
//   var k2Name = linkBox.get(k2).name;

//   return (k1Name).compareTo(k2Name);
// }
