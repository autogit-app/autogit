import 'package:flutter/material.dart';

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.title,
    this.trailing,
    this.spacing,
    this.onpressed,
  });

  final String title;
  final Widget? trailing;
  final double? spacing;
  final VoidCallback? onpressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onpressed,
            child: Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  spacing: spacing ?? 16.0,
                  children: [
                    CardTitle(title: title),
                    const Spacer(),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CardTitle extends StatelessWidget {
  const CardTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(fontSize: 20));
  }
}
