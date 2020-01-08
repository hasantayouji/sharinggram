import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sharinggram/screens/home.dart';
import 'package:sharinggram/screens/post_screen.dart';
import 'package:sharinggram/screens/profile.dart';
import 'package:sharinggram/widgets/header.dart';
import 'package:sharinggram/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: 'Activity feed'),
      body: Container(
        child: FutureBuilder(
            future: getActivityFedd(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return circularProgress();
              }
              return ListView(
                children: snapshot.data,
              );
            }),
      ),
    );
  }

  getActivityFedd() async {
    QuerySnapshot snapshot = await activityFeedRef
        .document(currentUser.id)
        .collection('feedItems')
        .orderBy('timeStamp', descending: true)
        .limit(50)
        .getDocuments();
    List<ActivityFeedItem> feedItems = [];
    snapshot.documents.forEach((doc) {
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    });
    return feedItems;
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type;
  final String mediaUrl;
  final String postId;
  final String userProfileImage;
  final String commentData;
  final Timestamp timeStamp;

  ActivityFeedItem({
    this.username,
    this.userId,
    this.type,
    this.mediaUrl,
    this.postId,
    this.userProfileImage,
    this.commentData,
    this.timeStamp,
  });

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      mediaUrl: doc['mediaUrl'],
      postId: doc['postId'],
      userProfileImage: doc['userProfileImage'],
      commentData: doc['commentData'],
      timeStamp: doc['timeStamp'],
    );
  }

  configureMediaPreview(context) {
    if (type == 'like' || type == 'comment') {
      mediaPreview = GestureDetector(
          onTap: () => showPost(context),
          child: Container(
            height: 50,
            width: 50,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: CachedNetworkImageProvider(mediaUrl),
                        fit: BoxFit.cover)),
              ),
            ),
          ));
    } else {
      Text('');
    }
    if (type == 'like') {
      activityItemText = 'liked your post';
    } else if (type == 'follow') {
      activityItemText = 'is following you';
    } else if (type == 'comment') {
      activityItemText = 'replied: $commentData';
    } else {
      activityItemText = 'Unknown type $type';
    }
  }

  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PostScreen(
                  userId: userId,
                  postId: postId,
                )));
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
              text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                        text: username,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: ' $activityItemText')
                  ]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImage),
          ),
          subtitle: Text(
            timeago.format(timeStamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}

showProfile(BuildContext context, {String profileId}) {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Profile(
                profileId: profileId,
              )));
}
