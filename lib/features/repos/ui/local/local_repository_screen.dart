import 'package:flutter/material.dart';

class LocalRepositoryScreen extends StatelessWidget {
  const LocalRepositoryScreen({super.key, required this.param});

  final String param;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(spacing: 16.0, children: [const BackButton(), Text(param)]),
      ],
    );
  }
}
