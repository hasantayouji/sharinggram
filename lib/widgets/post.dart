import 'dart:async';
import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sharinggram/models/user.dart';
import 'package:sharinggram/screens/activity_feed.dart';
import 'package:sharinggram/screens/comments.dart';
import 'package:sharinggram/screens/home.dart';
import 'package:sharinggram/widgets/custom_image.dart';
import 'package:sharinggram/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.description,
      this.mediaUrl,
      this.likes});
  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  getLikeCount(likes) {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((val) {
      if (val) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likeCount: this.getLikeCount(this.likes),
        likes: this.likes,
      );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked;
  bool showHeart = false;
  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likeCount,
    this.likes,
  });
  factory _PostState.fromDocument(DocumentSnapshot doc) {
    return _PostState(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likeCount: doc['likeCount'],
      likes: doc['likes'],
    );
  }

  buildPostHeader() {
    return FutureBuilder(
        future: userRef.document(ownerId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          User user = User.fromDocument(snapshot.data);
          bool isPostOwner = currentUserId == ownerId;
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              backgroundColor: Colors.grey,
            ),
            title: GestureDetector(
              onTap: () => showProfile(context, profileId: user.id),
              child: Text(
                user.username,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            subtitle: Text(location),
            trailing: isPostOwner
                ? IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () => handleDeletePost(context))
                : SizedBox(),
          );
        });
  }

  deletePost() async {
    postRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    storageRef.child('post_$postId.jpg').delete();

    QuerySnapshot activityFeddSnapshot = await activityFeedRef
        .document(ownerId)
        .collection('feedItems')
        .where('posId', isEqualTo: postId)
        .getDocuments();
    activityFeddSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });

    QuerySnapshot commentSnapshot =
        await commentRef.document(postId).collection('comments').getDocuments();
    commentSnapshot.documents.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text('Remove this post?'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                deletePost();
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            )
          ],
        );
      },
    );
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;
    if (_isLiked) {
      postRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': false});
      addLikeToActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 1000), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;

    if (!isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .setData({
        'type': 'like',
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImage': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timeStamp': timeStamp,
      });
    }
  }

  removeLikeToActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;

    if (!isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection('feeditems')
          .document(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 800),
                  tween: Tween(begin: 0.6, end: 1.4),
                  curve: Curves.easeInOut,
                  cycles: 1,
                  builder: (anim) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 80,
                    ),
                  ),
                )
              : SizedBox(),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40)),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: Colors.pink,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
            ),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                '$likeCount likes',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                '$username',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 5,
            ),
            Expanded(child: Text(description)),
          ],
        ),
      ],
    );
  }

  showComments(
    BuildContext context, {
    String postId,
    String ownerId,
    String mediaUrl,
  }) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => Comments(
                  postId: postId,
                  postOwnerId: ownerId,
                  postMediaUrl: mediaUrl,
                )));
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}
