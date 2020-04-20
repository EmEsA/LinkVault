import 'package:flutter/material.dart';
import 'main.dart';

class LinkEditForm extends StatelessWidget {
  String _title, _url;
  Link _link;
  final void Function(Link link) handleSave;
  final _formKey = GlobalKey<FormState>();

  LinkEditForm(this.handleSave) {
    _link = Link('', '');
  }
  LinkEditForm.withInitial(Link link, this.handleSave) {
    _link = link;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter link details')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Text('Title'),
              TextFormField(
                initialValue: _link != null ? _link.title : null,
                onSaved: (val) => _title = val,
              ),
              Text('Url'),
              TextFormField(
                initialValue: _link != null ? _link.url : null,
                onSaved: (val) => _url = val,
              ),
              RaisedButton(
                child: Text('save'),
                onPressed: _save,
              )
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    _formKey.currentState.save();
    _link.title = _title;
    _link.url = _url;
    handleSave(_link);
  }
}
