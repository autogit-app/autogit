import 'package:flutter/material.dart';

class LargeAppBar extends StatelessWidget {
  const LargeAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.pinned = true,
  });

  final String title;
  final bool pinned;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar.large(
      title: Text(title),
      pinned: pinned,
      expandedHeight: 120,
      leading: onBack == null ? null : BackButton(onPressed: onBack),
      actions: actions,
    );
  }
}
