import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Détail facture'),
        backgroundColor: AppColors.bg,
      ),
      body: const Center(
        child: Text('À venir...', style: TextStyle(color: AppColors.textDim)),
      ),
    );
  }
}
