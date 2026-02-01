import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text('What\'s new in this release?'),
          onTap: () {},
        ),
        ListTile(
          title: Text('Check for Updates'),
          onTap: () {},
        ),
        ListTile(
          title: Text('Version'),
          subtitle: Text('1.0.0'),
          onTap: () {},
        ),
        ListTile(
          title: Text('Open Source License'),
          subtitle: Text('MIT License'),
          onTap: () {},
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.info),
          title: Text('Who are we?'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.web),
          title: Text('Our Website'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(FontAwesomeIcons.github),
          title: Text('Our GitHub'),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.email),
          title: Text('Our Email'),
          onTap: () {},
        ),
      ],
    );
  }
}