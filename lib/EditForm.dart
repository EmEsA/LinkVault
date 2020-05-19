import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:link_vault/models/Item.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

class ItemEditForm extends StatefulWidget {
  ItemEditForm(this.item, this.siblingNames, this.handleSave);

  final List<String> siblingNames;
  final Item item;
  final void Function(Item item) handleSave;

  @override
  ItemEditFormState createState() => ItemEditFormState();
}

class ItemEditFormState extends State<ItemEditForm> {
  final _formKey = GlobalKey<FormState>();
  Item _item;
  final linkBox = Hive.box<Item>('links');

  @override
  void initState() {
    _item = widget.item;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var formBody = <Widget>[];

    if (widget.item.type == ItemType.link) {
      formBody = <Widget>[
        Text('Name'),
        TextFormField(
          autofocus: true,
          initialValue: widget.item != null ? widget.item.name : null,
          textCapitalization: TextCapitalization.sentences,
          validator: nameValidator,
          onSaved: (name) => _item.name = name,
        ),
        Padding(padding: EdgeInsets.fromLTRB(0, 10, 0, 0), child: Text('Url')),
        TextFormField(
          initialValue: widget.item != null ? widget.item.url : null,
          validator: urlValidator,
          onSaved: (url) => _item.url = url,
        ),
        RaisedButton(
          child: Text('save'),
          textColor: Colors.black,
          onPressed: _save,
        )
      ];
    } else {
      formBody = <Widget>[
        Text('Name'),
        TextFormField(
          autofocus: true,
          initialValue: widget.item != null ? widget.item.name : null,
          textCapitalization: TextCapitalization.sentences,
          validator: nameValidator,
          onSaved: (name) => _item.name = name,
        ),
        RaisedButton(
          child: Text('save'),
          textColor: Colors.black,
          onPressed: _save,
        )
      ];
    }

    return Scaffold(
      appBar: AppBar(
          title:
              Text('Enter ${_item.type.toString().split('.').last} details')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(children: formBody),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      if (_item.isInBox == true) {
        _item.save();
      } else {
        linkBox.put(uuid.v4(), _item);
      }
      widget.handleSave(_item);
    }
  }

  String nameValidator(String name) {
    if (name.isEmpty) {
      return 'Please enter a name';
    }
    // if (widget.siblingNames.contains(name)) {
    //   return 'This folder already contains $name';
    // }
    return null;
  }

  String urlValidator(String url) {
    var regExp = RegExp(r'(http:|https:).*');
    var match = regExp.matchAsPrefix(url);
    if (match == null) {
      return 'A link should begin from: http: or https:';
    }
    return null;
  }
}
