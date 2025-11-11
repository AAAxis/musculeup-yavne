import 'package:flutter/material.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';
import 'package:muscleup/presentation/onboarding/widgets/onboarding_base.dart';

class CoachPhoneScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CoachPhoneScreen({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<CoachPhoneScreen> createState() => _CoachPhoneScreenState();
}

class _CoachPhoneScreenState extends State<CoachPhoneScreen> {
  late TextEditingController _coachPhoneController;

  @override
  void initState() {
    super.initState();
    _coachPhoneController = TextEditingController(
      text: widget.controller.data.coachPhone ?? '',
    );
  }

  @override
  void dispose() {
    _coachPhoneController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final phone = _coachPhoneController.text.trim();
    widget.controller.data.coachPhone = phone.isEmpty ? null : phone;
    widget.onNext();
  }

  void _handleSkip() {
    widget.controller.data.coachPhone = null;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingBase(
      currentStep: 8,
      totalSteps: 8,
      title: 'Coach\'s phone? (Optional)',
      subtitle: 'You can skip this if you don\'t have it',
      onBack: widget.onBack,
      onNext: _handleNext,
      nextButtonText: _coachPhoneController.text.trim().isEmpty
          ? 'Skip'
          : 'Continue',
      child: Column(
        children: [
          TextField(
            controller: _coachPhoneController,
            decoration: const InputDecoration(
              labelText: 'Coach Phone',
              hintText: '+1234567890',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: (_) => _handleNext(),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleSkip,
            child: const Text('Skip this step'),
          ),
        ],
      ),
    );
  }
}

