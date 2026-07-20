import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => context.setLocale(const Locale('fr')),
          child: Text(
            'FR',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.locale.languageCode == 'fr'
                  ? AppColors.amber
                  : AppColors.textMute,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '|',
            style: TextStyle(color: AppColors.textMute, fontSize: 13),
          ),
        ),
        GestureDetector(
          onTap: () => context.setLocale(const Locale('en')),
          child: Text(
            'EN',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.locale.languageCode == 'en'
                  ? AppColors.amber
                  : AppColors.textMute,
            ),
          ),
        ),
      ],
    );
  }
}