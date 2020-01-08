import 'package:flutter/material.dart';

AppBar header(BuildContext context,
    {bool isAppTitle = false, String titleText, bool backButton = true}) {
  return AppBar(
    automaticallyImplyLeading: backButton,
    title: Text(
      isAppTitle ? 'SharingGan' : titleText,
      style: TextStyle(
          color: Colors.white,
          fontFamily: isAppTitle ? 'Signatra' : '',
          fontSize: isAppTitle ? 50 : 24),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
