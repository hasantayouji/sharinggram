import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:sharinggram/models/user.dart';
import 'package:sharinggram/screens/home.dart';
import 'package:sharinggram/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final currentUserId;
  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = false;
  User user;
  bool _displayNameValid = true;
  bool _bioValid = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot documentSnapshot =
        await userRef.document(widget.currentUserId).get();
    user = User.fromDocument(documentSnapshot);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Display Name',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
              hintText: 'Update display name',
              errorText: _displayNameValid
                  ? null
                  : 'Display name must between 3 - 12 characters'),
        ),
      ],
    );
  }

  buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Bio',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: 'Update Bio',
            errorText: _bioValid ? null : 'Maximum 140 characters',
          ),
        ),
      ],
    );
  }

  logout() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  updateProfileData() {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.trim().length > 12 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;
      bioController.text.trim().length > 140
          ? _bioValid = false
          : _bioValid = true;
    });
    if (_displayNameValid && _bioValid) {
      userRef.document(widget.currentUserId).updateData({
        'displayName': displayNameController.text,
        'bio': bioController.text
      });
      SnackBar snackBar = SnackBar(content: Text('Profile updated'));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.done,
                size: 30,
                color: Colors.green,
              ),
              onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 8),
                        child: CircleAvatar(
                          backgroundImage:
                              CachedNetworkImageProvider(user.photoUrl),
                          radius: 50,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      RaisedButton(
                        onPressed: updateProfileData,
                        child: Text(
                          'Update profile',
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: FlatButton.icon(
                            onPressed: logout,
                            icon: Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                            label: Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 20,
                              ),
                            )),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
