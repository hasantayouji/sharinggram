import 'package:flutter/material.dart';
import 'package:sharinggram/screens/home.dart';
import 'package:sharinggram/widgets/header.dart';
import 'dart:async';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  String username;
  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar:
          header(context, titleText: 'Set up your profile', backButton: false),
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(padding: EdgeInsets.only(top: 25)),
                Center(
                  child: Text(
                    'Create a username',
                    style: TextStyle(fontSize: 25),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      autovalidate: true,
                      child: TextFormField(
                        validator: (val) {
                          if (val.trim().length < 3 || val.isEmpty) {
                            return 'Username too short';
                          } else if (val.trim().length > 12) {
                            return 'username too long';
                          } else {
                            return null;
                          }
                        },
                        onSaved: (val) => username = val,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Useraname',
                            labelStyle: TextStyle(fontSize: 15),
                            hintText:
                                'Username must contain at least 3 characters'),
                      ),
                    )),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    width: 350,
                    height: 50,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        color: Colors.blue),
                    child: Center(
                      child: Text(
                        'Submit',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  submit() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      SnackBar snackbar = SnackBar(content: Text('Welcome, $username!'));
      _scaffoldKey.currentState.showSnackBar(snackbar);
      Timer(Duration(seconds: 2), () => Navigator.pop(context, username));
    }
  }
}
