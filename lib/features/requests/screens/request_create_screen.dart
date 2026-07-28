import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/request_model.dart';
import '../providers/request_provider.dart';
import '../../../../core/services/geolocation_service.dart';
import 'package:geolocator/geolocator.dart';

class RequestCreateScreen extends ConsumerStatefulWidget {
  const RequestCreateScreen({super.key});

  @override
  ConsumerState<RequestCreateScreen> createState() =>
      _RequestCreateScreenState();
}

class _RequestCreateScreenState extends ConsumerState<RequestCreateScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _neighCtrl    = TextEditingController();
  final _budgetCtrl   = TextEditingController();

  String? _selectedCategory;
  String  _selectedUrgency = 'today';
  int     _currentStep     = 0;
  double? _latitude;
  double? _longitude;
  bool    _locating        = false;
  final _customCategoryCtrl = TextEditingController();
  bool    _addingCategory  = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _neighCtrl.dispose();
    _budgetCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCustomCategory() async {
    if (_customCategoryCtrl.text.trim().isEmpty) return;

    setState(() => _addingCategory = true);
    try {
      final slug = await findOrCreateCategory(_customCategoryCtrl.text);
      ref.invalidate(categoriesProvider);
      setState(() {
        _selectedCategory = slug;
        _customCategoryCtrl.clear();
        if (_currentStep < 1) _currentStep = 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'chat_error'.tr()}$e')),
        );
      }
    }
    if (mounted) setState(() => _addingCategory = false);
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final position = await GeolocationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _latitude  = position.latitude;
        _longitude = position.longitude;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('request_location_error'.tr())),
        );
      }
    }
    setState(() => _locating = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('request_category_required'.tr())),
      );
      return;
    }

    final error = await ref.read(requestNotifierProvider.notifier).createRequest(
      title:        _titleCtrl.text.trim(),
      description:  _descCtrl.text.trim(),
      category:     _selectedCategory!,
      location:     _locationCtrl.text.trim(),
      neighborhood: _neighCtrl.text.trim().isEmpty
          ? null
          : _neighCtrl.text.trim(),
      urgency:      _selectedUrgency,
      budget:       double.tryParse(_budgetCtrl.text),
      latitude:     _latitude,
      longitude:    _longitude,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('request_success'.tr()),
          backgroundColor: AppColors.green,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isLoading       = ref.watch(requestNotifierProvider).isLoading;

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
          'request_create_title'.tr(),
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _StepIndicator(
            currentStep: _currentStep,
            totalSteps: 3,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                step: 1,
                title: 'request_step1_title'.tr(),
                isActive: _currentStep >= 0,
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.amber, strokeWidth: 2),
                ),
                error: (e, _) => Text(
                  'request_load_error'.tr(),
                  style: const TextStyle(color: AppColors.red),
                ),
                data: (categories) {
                  final baseCategories =
                  categories.where((c) => !c.isCustom).toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.8,
                    ),
                    itemCount: baseCategories.length,
                    itemBuilder: (context, i) {
                      final cat        = baseCategories[i];
                      final isSelected = _selectedCategory == cat.slug;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat.slug;
                            if (_currentStep < 1) _currentStep = 1;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.amberSoft
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.amber
                                  : AppColors.line2,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(cat.emoji,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.amber
                                        : AppColors.textDim,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              if (_selectedCategory == 'other')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'request_custom_category_label'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDim,
                          ),
                        ),
                        const SizedBox(height: 10),
                        categoriesAsync.maybeWhen(
                          data: (categories) {
                            final customCats = categories
                                .where((c) => c.isCustom)
                                .toList();
                            if (customCats.isEmpty) {
                              return const Text(
                                'Aucune catégorie personnalisée encore.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMute),
                              );
                            }
                            return DropdownButtonFormField<String>(
                              value: customCats.any(
                                      (c) => c.slug == _selectedCategory)
                                  ? _selectedCategory
                                  : null,
                              dropdownColor: AppColors.surface2,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.amber),
                              style: const TextStyle(
                                  color: AppColors.text, fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surface2,
                                hintText:
                                'request_custom_category_dropdown'.tr(),
                                hintStyle: const TextStyle(
                                    color: AppColors.textMute, fontSize: 13),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                  const BorderSide(color: AppColors.line2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                  const BorderSide(color: AppColors.line2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                  const BorderSide(color: AppColors.amber, width: 1.5),
                                ),
                              ),
                              items: customCats
                                  .map((cat) => DropdownMenuItem(
                                value: cat.slug,
                                child: Text('${cat.emoji}  ${cat.label}'),
                              ))
                                  .toList(),
                              onChanged: (slug) {
                                if (slug != null) {
                                  setState(() {
                                    _selectedCategory = slug;
                                    if (_currentStep < 1) _currentStep = 1;
                                  });
                                }
                              },
                            );
                          },
                          orElse: () => const SizedBox(),
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: AppColors.line2),
                        const SizedBox(height: 10),
                        Text(
                          'request_custom_category_new'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDim,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _customCategoryCtrl,
                          style: const TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            hintText: 'request_custom_category_hint'.tr(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                            _addingCategory ? null : _addCustomCategory,
                            icon: _addingCategory
                                ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.amber),
                            )
                                : const Icon(Icons.add_rounded, size: 16),
                            label: Text('request_add_category_btn'.tr()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.amber,
                              side: const BorderSide(color: AppColors.amber),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              _SectionTitle(
                step: 2,
                title: 'request_step2_title'.tr(),
                isActive: _currentStep >= 1,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppColors.text),
                onChanged: (_) {
                  if (_currentStep < 1) setState(() => _currentStep = 1);
                },
                decoration: InputDecoration(
                  labelText: 'request_title_label'.tr(),
                  hintText: 'request_title_hint'.tr(),
                  prefixIcon: const Icon(Icons.title_rounded,
                      color: AppColors.textMute),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'field_required'.tr();
                  if (v.trim().length < 10) return 'request_min_10'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: AppColors.text),
                maxLines: 4,
                onChanged: (_) {
                  if (_currentStep < 1) setState(() => _currentStep = 1);
                },
                decoration: InputDecoration(
                  labelText: 'request_desc_label'.tr(),
                  hintText: 'request_desc_hint'.tr(),
                  prefixIcon: const Icon(Icons.description_outlined,
                      color: AppColors.textMute),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'field_required'.tr();
                  if (v.trim().length < 20) return 'request_min_20'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _SectionTitle(
                step: 3,
                title: 'request_step3_title'.tr(),
                isActive: _currentStep >= 2,
              ),
              const SizedBox(height: 16),
              Text(
                'request_urgency_label'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: kUrgencies.map((u) {
                  final isSelected = _selectedUrgency == u['id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedUrgency = u['id']!;
                          if (_currentStep < 2) _currentStep = 2;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.amberSoft
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.amber
                                : AppColors.line2,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(u['emoji']!,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              u['label']!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.amber
                                    : AppColors.textMute,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationCtrl,
                style: const TextStyle(color: AppColors.text),
                onChanged: (_) {
                  if (_currentStep < 2) setState(() => _currentStep = 2);
                },
                decoration: InputDecoration(
                  labelText: 'request_city_label'.tr(),
                  hintText: 'request_city_hint'.tr(),
                  prefixIcon: const Icon(Icons.location_city_rounded,
                      color: AppColors.textMute),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'field_required'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _neighCtrl,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'request_neighborhood_label'.tr(),
                  hintText: 'request_neighborhood_hint'.tr(),
                  prefixIcon: const Icon(Icons.map_outlined,
                      color: AppColors.textMute),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _locating ? null : _useMyLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _latitude != null
                        ? AppColors.greenSoft
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _latitude != null
                          ? AppColors.green
                          : AppColors.line2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _latitude != null
                            ? Icons.check_circle_rounded
                            : Icons.my_location_rounded,
                        size: 18,
                        color: _latitude != null
                            ? AppColors.green
                            : AppColors.textMute,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _locating
                              ? 'profile_locating'.tr()
                              : _latitude != null
                              ? 'request_location_obtained'.tr()
                              : 'profile_location_use'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: _latitude != null
                                ? AppColors.green
                                : AppColors.textDim,
                          ),
                        ),
                      ),
                      if (_locating)
                        const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.amber),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetCtrl,
                style: const TextStyle(color: AppColors.text),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'request_budget_label'.tr(),
                  hintText: 'request_budget_hint'.tr(),
                  prefixIcon: const Icon(Icons.attach_money_rounded,
                      color: AppColors.textMute),
                  suffixText: '\$',
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (double.tryParse(v) == null) {
                      return 'request_budget_invalid'.tr();
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 16, color: AppColors.cyan),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'request_escrow_note'.tr(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDim,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.bg,
                          ),
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 18),
                            const SizedBox(width: 8),
                            Text('request_publish_btn'.tr()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i <= currentStep;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColors.amber : AppColors.line2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final int step;
  final String title;
  final bool isActive;

  const _SectionTitle({
    required this.step,
    required this.title,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.amber : AppColors.surface2,
            border: Border.all(
              color: isActive ? AppColors.amber : AppColors.line2,
            ),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.bg : AppColors.textMute,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.text : AppColors.textMute,
          ),
        ),
      ],
    );
  }
}