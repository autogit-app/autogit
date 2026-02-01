import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LocalReposScreen extends StatelessWidget {
  const LocalReposScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          spacing: 16.0,
          children: [BackButton(), Text("Local Repositories")],
        ),
        ElevatedButton(
          onPressed: () => context.push('/home/local/mylocal'),
          child: const Text("next"),
        ),
      ],
    );
  }
}
