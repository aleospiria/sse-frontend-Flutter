import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('Usuarios'),
      ),
      body: const Center(
        child: Text('Proximamente...',
            style: TextStyle(color: Color(0xFF94A3B8))),
      ),
    );
  }
}
