import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';
import 'package:muscleup/presentation/onboarding/widgets/onboarding_base.dart';

class WeightScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const WeightScreen({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.controller.initialWeight?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final weight = double.tryParse(_weightController.text);
    if (weight != null && weight >= 30 && weight <= 300) {
      widget.controller.initialWeight = weight;
      widget.onNext();
    }
  }

  bool get _isValid {
    final weight = double.tryParse(_weightController.text);
    return weight != null && weight >= 30 && weight <= 300;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingBase(
      currentStep: 5,
      totalSteps: 8,
      title: 'What\'s your weight?',
      subtitle: 'Enter your current weight in kilograms',
      onBack: widget.onBack,
      onNext: _handleNext,
      isNextEnabled: _isValid,
      child: Column(
        children: [
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'e.g., 70',
              prefixIcon: Icon(Icons.monitor_weight),
              suffixText: 'kg',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
            ],
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: (_) => _handleNext(),
          ),
          const SizedBox(height: 16),
          Text(
            'Valid range: 30-300 kg',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}
