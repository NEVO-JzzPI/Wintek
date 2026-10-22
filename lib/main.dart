import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: WintekApp()));
}

class WintekApp extends StatelessWidget {
  const WintekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Wintek', home: WintekPlaceholderScreen());
  }
}

class WintekPlaceholderScreen extends StatelessWidget {
  const WintekPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wintek')),
      body: const Center(
        child: Text(
          'Wintek — tracking ISS, Tiangong, FASat-Charlie and GOES-East',
        ),
      ),
    );
  }
}
