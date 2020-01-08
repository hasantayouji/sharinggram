import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sharinggram/models/user.dart';
import 'package:sharinggram/screens/edit_profile.dart';
import 'package:sharinggram/screens/home.dart';
import 'package:sharinggram/screens/post_screen.dart';
import 'package:sharinggram/widgets/header.dart';
import 'package:sharinggram/widgets/post_tile.dart';
import 'package:sharinggram/widgets/progress.dart';
import 'package:sharinggram/widgets/post.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  bool isFollowing = false;
  bool isLoading = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  String postOrientation = 'grid';
  List<Post> posts = [];
  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followerCount = snapshot.documents.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  buildCountColumn(String title, int count) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '${count.toString()}',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          child: Text(
            title,
            style: TextStyle(
                color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  Container buildButton({String label, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: FlatButton(
          onPressed: function,
          child: Container(
            width: 250,
            height: 27,
            child: Text(
              label,
              style: TextStyle(
                  color: isFollowing ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFollowing ? Colors.white : Colors.blue,
              border:
                  Border.all(color: isFollowing ? Colors.grey : Colors.blue),
              borderRadius: BorderRadius.circular(5),
            ),
          )),
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(
                  currentUserId: currentUserId,
                )));
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(label: 'Edit Profile', function: editProfile);
    } else if (isFollowing) {
      return buildButton(label: 'Unfollow', function: handleUnfollowUser);
    } else if (!isFollowing) {
      return buildButton(label: 'Follow', function: handleFollowUser);
    }
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
      followersRef
          .document(widget.profileId)
          .collection('userFollowers')
          .document(currentUserId)
          .setData({});
      followingRef
          .document(currentUserId)
          .collection('userFollowing')
          .document(widget.profileId)
          .setData({});
      activityFeedRef
          .document(widget.profileId)
          .collection('feedItems')
          .document(currentUserId)
          .setData({
        'type': 'follow',
        'ownerId': widget.profileId,
        'username': currentUser.username,
        'userId': currentUserId,
        'userProfileImage': currentUser.photoUrl,
        'timeStamp': timeStamp,
      });
    });
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
      followersRef
          .document(widget.profileId)
          .collection('userFollowers')
          .document(currentUserId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
      followingRef
          .document(currentUserId)
          .collection('userFollowing')
          .document(widget.profileId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
        future: userRef.document(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          User user = User.fromDocument(snapshot.data);
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          CachedNetworkImageProvider(user.photoUrl),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildCountColumn('posts', postCount),
                              buildCountColumn('followers', followerCount),
                              buildCountColumn('following', followingCount),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildProfileButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    user.username,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 4),
                  child: Text(user.bio),
                )
              ],
            ),
          );
        });
  }

  buildTogglePostView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () {
            setState(() {
              postOrientation = 'grid';
            });
          },
          icon: Icon(Icons.grid_on),
          color: postOrientation == 'grid'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        ),
        IconButton(
          onPressed: () {
            setState(() {
              postOrientation = 'list';
            });
          },
          icon: Icon(Icons.list),
          color: postOrientation == 'list'
              ? Theme.of(context).primaryColor
              : Colors.grey,
        )
      ],
    );
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timeStamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: SvgPicture.asset(
          'assets/images/no_content.svg',
          height: 260,
        ),
      );
    } else if (postOrientation == 'grid') {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(
            child: PostTile(
          post: post,
        )));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == 'list') {
      return Column(
        children: posts,
      );
    }

//    }
//    return Column(
//      children: posts,
//    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: 'Profile'),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostView(),
          Divider(),
          buildProfilePosts()
        ],
      ),
    );
  }
}
