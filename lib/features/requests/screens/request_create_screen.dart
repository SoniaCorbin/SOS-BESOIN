import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RequestCreateScreen extends StatelessWidget {
  const RequestCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Nouvelle demande'),
        backgroundColor: AppColors.bg,
      ),
      body: const Center(
        child: Text('À venir...', style: TextStyle(color: AppColors.textDim)),
      ),
    );
  }
}