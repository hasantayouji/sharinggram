import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sharinggram/models/user.dart';
import 'package:sharinggram/screens/activity_feed.dart';
import 'package:sharinggram/screens/create_account.dart';
import 'package:sharinggram/screens/profile.dart';
import 'package:sharinggram/screens/search.dart';
import 'package:sharinggram/screens/timeline.dart';
import 'package:sharinggram/screens/upload.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final commentRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final userRef = Firestore.instance.collection('users');
final postRef = Firestore.instance.collection('posts');
final timelineRef = Firestore.instance.collection('timeline');
final DateTime timeStamp = DateTime.now();
final StorageReference storageRef = FirebaseStorage.instance.ref();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  PageController pageController;
  int pageIndex = 0;
  @override
  void initState() {
    super.initState();
    pageController = PageController();
    googleSignIn.onCurrentUserChanged.listen((account) {
      _handleSignIn(account);
      print("NOT");
    }, onError: (err) {
      print('User sign in error: $err');
    });
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      _handleSignIn(account);
      print('SILENT');
    }).catchError((err) {
      print('User Sign in error: $err');
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  _handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await _createUserInFireStore();
      setState(() {
        isAuth = true;
      });
      configurePushNotification();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotification() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    _firebaseMessaging.getToken().then((token) {
      print('Firebase Messaging Token: $token\n');
      userRef.document(user.id).updateData({'androidNotificationToken': token});
    });
    _firebaseMessaging.configure(
//      onLaunch: (Map<String, dynamic> message) async {},
//      onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        print('NYAMPE SINI GAK SIH');
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          SnackBar snackbar = SnackBar(
              content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
      },
    );
  }

  _createUserInFireStore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await userRef.document(user.id).get();

    if (!doc.exists) {
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      userRef.document(user.id).setData({
        'id': user.id,
        'username': username,
        'photoURL': user.photoUrl,
        'email': user.email,
        'displayName': user.displayName,
        'bio': '',
        'timeStamp': timeStamp,
      });
      await followersRef
          .document(user.id)
          .collection('userFollowers')
          .document(user.id)
          .setData({});
      doc = await userRef.document(user.id).get();
    }
    currentUser = User.fromDocument(doc);
  }

  bool isAuth = false;

  login() async {
    try {
      await googleSignIn.signIn();
    } catch (e) {
      print('GAGAL MANING');
    }
  }

  Widget buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(
            currentUser: currentUser,
          ),
          //Timeline(),
          ActivityFeed(),
          Upload(
            currentUser: currentUser,
          ),
          Search(),
          Profile(
            profileId: currentUser?.id,
          ),
        ],
        controller: pageController,
        onPageChanged: _onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
        currentIndex: pageIndex,
        onTap: _onTap,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  _onTap(int pageIndex) {
    pageController.animateToPage(pageIndex,
        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  _onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  Widget buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor,
            ])),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'SharingGan',
              style: TextStyle(
                  fontFamily: 'Signatra', fontSize: 90, color: Colors.white),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260,
                height: 60,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/google_signin_button.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
