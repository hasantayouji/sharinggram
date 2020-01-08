import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sharinggram/models/user.dart';
import 'package:sharinggram/screens/activity_feed.dart';
import 'package:sharinggram/screens/home.dart';
import 'package:sharinggram/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin {
  Future<QuerySnapshot> searchResultFuture;
  handleSearch(String query) {
    Future<QuerySnapshot> users =
        userRef.where('username', isGreaterThanOrEqualTo: query).getDocuments();
    setState(() {
      searchResultFuture = users;
    });
  }

  buildSearchResult() {
    return FutureBuilder(
        future: searchResultFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<UserResult> searchResults = [];
          snapshot.data.documents.forEach((doc) {
            User user = User.fromDocument(doc);
            UserResult searchResult = UserResult(user);
            print('HALOOOO ${user.username}');
            searchResults.add(searchResult);
          });
          return ListView(
            children: searchResults.length == 0
                ? <Widget>[Text('User does not exist')]
                : searchResults,
          );
        });
  }

  buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        decoration: InputDecoration(
          hintText: 'Search for a user...',
          filled: true,
          prefixIcon: Icon(
            Icons.account_box,
            size: 28,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              print('Cleared');
            },
          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  buildNoContent() {
    final orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: orientation == Orientation.portrait ? 300 : 200,
            ),
            Text(
              'Find users',
              style: TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  fontSize: 60),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: buildSearchField(),
      body: searchResultFuture == null ? buildNoContent() : buildSearchResult(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user.username,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Divider(
            height: 2,
            color: Colors.white54,
          )
        ],
      ),
    );
  }
}
