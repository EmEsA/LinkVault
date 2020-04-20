import 'package:flutter/material.dart';
import 'package:link_vault/editForm.dart';
import 'package:flutter/services.dart';

class Link {
  String title;
  String url;

  Link(this.title, this.url);
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Link Vault',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: MyHomePage(title: 'Link Vault'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _links = List<Link>();

  void _addLink(Link link) {
    setState(() {
      _links.add(link);
    });
  }

  void _updateLink(int index, Link link) {
    setState(() {
      _links[index] = link;
    });
  }

  void _deleteLink(int index) {
    setState(() {
      _links.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    List<Link> dummyElements = [
      Link('youtube', 'youtube.com'),
      Link('google', 'google.com'),
      Link('soundcloud', 'soundcloud.com'),
    ];
    _links.addAll(dummyElements);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _links.length,
        itemBuilder: (BuildContext context, int index) {
          return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Text(_links[index].title),
                  ],
                ),
                Column(children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.content_copy,
                          color: Colors.green,
                        ),
                        onPressed: () => Clipboard.setData(
                            ClipboardData(text: _links[index].url)),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Colors.blue,
                        ),
                        onPressed: () => _pushEditLinkScreen(index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteLink(index),
                      ),
                    ],
                  )
                ]),
              ]);
        },
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _pushEditLinkScreen,
        tooltip: 'Add link',
        child: Icon(Icons.add),
      ),
    );
  }

  void _pushEditLinkScreen([int index]) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      if (index != null) {
        return LinkEditForm.withInitial(_links[index], (Link link) {
          _updateLink(index, link);
          Navigator.pop(context);
        });
      } else {
        return LinkEditForm((Link link) {
          _addLink(link);
          Navigator.pop(context);
        });
      }
    }));
  }
}
