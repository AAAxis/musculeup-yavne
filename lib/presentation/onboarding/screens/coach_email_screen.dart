import 'package:flutter/material.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';
import 'package:muscleup/presentation/onboarding/widgets/onboarding_base.dart';

class CoachEmailScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CoachEmailScreen({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<CoachEmailScreen> createState() => _CoachEmailScreenState();
}

class _CoachEmailScreenState extends State<CoachEmailScreen> {
  late TextEditingController _coachEmailController;

  @override
  void initState() {
    super.initState();
    _coachEmailController = TextEditingController(
      text: widget.controller.coachEmail ?? '',
    );
  }

  @override
  void dispose() {
    _coachEmailController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_isValid) {
      widget.controller.coachEmail = _coachEmailController.text.trim();
      widget.onNext();
    }
  }

  bool get _isValid {
    final email = _coachEmailController.text.trim();
    return email.isNotEmpty && email.contains('@');
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingBase(
      currentStep: 7,
      totalSteps: 8,
      title: 'Coach\'s email?',
      subtitle: 'We\'ll use this to connect you with your coach',
      onBack: widget.onBack,
      onNext: _handleNext,
      isNextEnabled: _isValid,
      child: TextField(
        controller: _coachEmailController,
        decoration: const InputDecoration(
          labelText: 'Coach Email',
          hintText: 'coach@example.com',
          prefixIcon: Icon(Icons.email),
        ),
        keyboardType: TextInputType.emailAddress,
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: (_) => _handleNext(),
      ),
    );
  }
}

