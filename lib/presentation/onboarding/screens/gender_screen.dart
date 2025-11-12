import 'package:flutter/material.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';
import 'package:muscleup/presentation/onboarding/widgets/onboarding_base.dart';

class GenderScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const GenderScreen({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.controller.gender;
  }

  void _selectGender(String gender) {
    setState(() {
      _selectedGender = gender;
    });
    widget.controller.gender = gender;
    // Auto-advance after selection
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingBase(
      currentStep: 2,
      totalSteps: 8,
      title: 'What\'s your gender?',
      subtitle: 'This helps us personalize your experience',
      onBack: widget.onBack,
      child: Column(
        children: [
          _GenderCard(
            icon: Icons.male,
            label: 'Male',
            isSelected: _selectedGender == 'male',
            onTap: () => _selectGender('male'),
          ),
          const SizedBox(height: 16),
          _GenderCard(
            icon: Icons.female,
            label: 'Female',
            isSelected: _selectedGender == 'female',
            onTap: () => _selectGender('female'),
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 48,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
              ),
              const SizedBox(width: 24),
              Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                    ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

