import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';
import 'package:muscleup/presentation/onboarding/widgets/onboarding_base.dart';

class HeightScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const HeightScreen({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(
      text: widget.controller.data.height?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final height = double.tryParse(_heightController.text);
    if (height != null && height >= 100 && height <= 250) {
      widget.controller.data.height = height;
      widget.onNext();
    }
  }

  bool get _isValid {
    final height = double.tryParse(_heightController.text);
    return height != null && height >= 100 && height <= 250;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingBase(
      currentStep: 4,
      totalSteps: 8,
      title: 'How tall are you?',
      subtitle: 'Enter your height in centimeters',
      onBack: widget.onBack,
      onNext: _handleNext,
      isNextEnabled: _isValid,
      child: Column(
        children: [
          TextField(
            controller: _heightController,
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              hintText: 'e.g., 175',
              prefixIcon: Icon(Icons.height),
              suffixText: 'cm',
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
            'Valid range: 100-250 cm',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

