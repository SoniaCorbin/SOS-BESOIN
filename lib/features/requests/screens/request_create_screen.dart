import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/request_model.dart';
import '../providers/request_provider.dart';

class RequestCreateScreen extends ConsumerStatefulWidget {
  const RequestCreateScreen({super.key});

  @override
  ConsumerState<RequestCreateScreen> createState() =>
      _RequestCreateScreenState();
}

class _RequestCreateScreenState extends ConsumerState<RequestCreateScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _titleCtrl     = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _locationCtrl  = TextEditingController();
  final _neighCtrl     = TextEditingController();
  final _budgetCtrl    = TextEditingController();

  String? _selectedCategory;
  String  _selectedUrgency = 'today';
  int     _currentStep     = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _neighCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une catégorie.')),
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
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Demande publiée ! Les pros vont répondre.'),
          backgroundColor: AppColors.green,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isLoading = ref.watch(requestNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDim, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Lancer un SOS',
          style: TextStyle(
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
              // ── Étape 1 : Catégorie ──────────────────
              _SectionTitle(
                step: 1,
                title: 'Quelle catégorie ?',
                isActive: _currentStep >= 0,
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.amber,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => Text(
                  'Erreur de chargement',
                  style: const TextStyle(color: AppColors.red),
                ),
                data: (categories) => GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final cat = categories[i];
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
                ),
              ),
              const SizedBox(height: 32),

              // ── Étape 2 : Description ────────────────
              _SectionTitle(
                step: 2,
                title: 'Décrivez votre besoin',
                isActive: _currentStep >= 1,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppColors.text),
                onChanged: (_) {
                  if (_currentStep < 1) setState(() => _currentStep = 1);
                },
                decoration: const InputDecoration(
                  labelText: 'Titre court',
                  hintText: 'ex: Lave-vaisselle Bosch qui fuit, urgent',
                  prefixIcon: Icon(Icons.title_rounded,
                      color: AppColors.textMute),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  if (v.trim().length < 10) return 'Minimum 10 caractères';
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
                decoration: const InputDecoration(
                  labelText: 'Description détaillée',
                  hintText:
                  'Décrivez le problème, le contexte, ce dont vous avez besoin...',
                  prefixIcon: Icon(Icons.description_outlined,
                      color: AppColors.textMute),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  if (v.trim().length < 20) return 'Minimum 20 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ── Étape 3 : Détails ────────────────────
              _SectionTitle(
                step: 3,
                title: 'Où, quand et combien ?',
                isActive: _currentStep >= 2,
              ),
              const SizedBox(height: 16),
              // Urgence
              const Text(
                'Quand en avez-vous besoin ?',
                style: TextStyle(
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
              // Ville
              TextFormField(
                controller: _locationCtrl,
                style: const TextStyle(color: AppColors.text),
                onChanged: (_) {
                  if (_currentStep < 2) setState(() => _currentStep = 2);
                },
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  hintText: 'ex: Montréal',
                  prefixIcon: Icon(Icons.location_city_rounded,
                      color: AppColors.textMute),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Quartier
              TextFormField(
                controller: _neighCtrl,
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(
                  labelText: 'Quartier (optionnel)',
                  hintText: 'ex: Plateau, Outremont, Mile End...',
                  prefixIcon: Icon(Icons.map_outlined,
                      color: AppColors.textMute),
                ),
              ),
              const SizedBox(height: 16),
              // Budget
              TextFormField(
                controller: _budgetCtrl,
                style: const TextStyle(color: AppColors.text),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget estimé (optionnel)',
                  hintText: 'ex: 150',
                  prefixIcon: Icon(Icons.attach_money_rounded,
                      color: AppColors.textMute),
                  suffixText: '\$',
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (double.tryParse(v) == null) {
                      return 'Montant invalide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // ── Bouton soumettre ─────────────────────
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
                        const Expanded(
                          child: Text(
                            'Paiement séquestré — vous ne payez qu\'après validation.',
                            style: TextStyle(
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
                            : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Publier ma demande'),
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

// ── Indicateur d'étapes ───────────────────────────────────
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

// ── Titre de section ──────────────────────────────────────
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