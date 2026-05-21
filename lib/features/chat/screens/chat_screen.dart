import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.bg,
      ),
      body: const Center(
        child: Text('À venir...', style: TextStyle(color: AppColors.textDim)),
      ),
    );
  }
}