import 'package:flutter/material.dart';

void main() {
  runApp(const NJTranslateCamApp());
}

class NJTranslateCamApp extends StatelessWidget {
  const NJTranslateCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NJ TranslateCam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NJ TranslateCam'),
      ),
      body: const Center(
        child: Text('Paste your custom code here.'),
      ),
    );
  }
}
