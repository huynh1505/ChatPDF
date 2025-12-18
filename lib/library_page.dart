import 'package:flutter/material.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text("Library"),
      ),
      body: const Center(
        child: Text(
          "Your PDF Library",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
