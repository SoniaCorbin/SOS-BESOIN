import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';

// Toggle réutilisable "Actifs / Archivés" — prend le StateProvider<bool>
// à contrôler en paramètre pour être réutilisé sur les listes SOS,
// missions et conversations.
class ArchiveToggle extends ConsumerWidget {
  final StateProvider<bool> provider;
  const ArchiveToggle({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showArchived = ref.watch(provider);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ArchiveToggleTab(
            label: 'toggle_active'.tr(),
            selected: !showArchived,
            onTap: () => ref.read(provider.notifier).state = false,
          ),
          _ArchiveToggleTab(
            label: 'toggle_archived'.tr(),
            selected: showArchived,
            onTap: () => ref.read(provider.notifier).state = true,
          ),
        ],
      ),
    );
  }
}

class _ArchiveToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ArchiveToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.bg : AppColors.textMute,
          ),
        ),
      ),
    );
  }
}