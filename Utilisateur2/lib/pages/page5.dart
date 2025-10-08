import 'package:flutter/material.dart';

class Page5 extends StatelessWidget {
  const Page5({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salle 5'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text('Bienvenue en Page 5', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}


