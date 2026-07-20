import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String? reportedUserId;
  final String? requestId;
  final String? offerId;
  final String? messageId;

  const ReportScreen({
    super.key,
    this.reportedUserId,
    this.requestId,
    this.offerId,
    this.messageId,
  });

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _descCtrl = TextEditingController();
  String? _reason;
  bool _loading   = false;

  List<String> get _reportReasons => [
    'report_reason_1'.tr(),
    'report_reason_2'.tr(),
    'report_reason_3'.tr(),
    'report_reason_4'.tr(),
    'report_reason_5'.tr(),
    'report_reason_6'.tr(),
    'report_reason_7'.tr(),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('report_reason_required'.tr())),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      await Supabase.instance.client.from('reports').insert({
        'reporter_id': userId,
        'reported_id': widget.reportedUserId,
        'request_id':  widget.requestId,
        'offer_id':    widget.offerId,
        'message_id':  widget.messageId,
        'reason':      _reason,
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('report_success'.tr()),
            backgroundColor: AppColors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'chat_error'.tr()}$e')),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDim, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'report_title'.tr(),
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: AppColors.red,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'report_header'.tr(),
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'report_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMute,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'report_reason_title'.tr(),
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            ..._reportReasons.map((reason) => GestureDetector(
              onTap: () => setState(() => _reason = reason),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _reason == reason
                      ? AppColors.redSoft
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _reason == reason
                        ? AppColors.red
                        : AppColors.line2,
                    width: _reason == reason ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _reason == reason
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: _reason == reason
                          ? AppColors.red
                          : AppColors.textMute,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      reason,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _reason == reason
                            ? AppColors.red
                            : AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),
            Text(
              'report_desc_title'.tr(),
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              style: const TextStyle(color: AppColors.text),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'report_desc_hint'.tr(),
                prefixIcon: const Icon(Icons.description_outlined,
                    color: AppColors.textMute),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: AppColors.text,
                ),
                child: _loading
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.text,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'report_submit_btn'.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}