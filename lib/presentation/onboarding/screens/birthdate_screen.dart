import 'package:flutter/material.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';
import 'package:muscleup/presentation/onboarding/widgets/onboarding_base.dart';

class BirthdateScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const BirthdateScreen({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<BirthdateScreen> createState() => _BirthdateScreenState();
}

class _BirthdateScreenState extends State<BirthdateScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.controller.data.birthDate;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      widget.controller.data.birthDate = picked;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingBase(
      currentStep: 3,
      totalSteps: 8,
      title: 'When were you born?',
      subtitle: 'We need this to personalize your fitness plan',
      onBack: widget.onBack,
      onNext: _selectedDate != null ? widget.onNext : null,
      isNextEnabled: _selectedDate != null,
      child: InkWell(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                _selectedDate == null
                    ? 'Select your birth date'
                    : _formatDate(_selectedDate!),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _selectedDate == null
                          ? Colors.grey[600]
                          : Colors.black87,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

