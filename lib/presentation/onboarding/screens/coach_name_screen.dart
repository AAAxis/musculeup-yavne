import 'package:flutter/material.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';
import 'package:muscleup/presentation/onboarding/widgets/onboarding_base.dart';

class CoachNameScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CoachNameScreen({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<CoachNameScreen> createState() => _CoachNameScreenState();
}

class _CoachNameScreenState extends State<CoachNameScreen> {
  late TextEditingController _coachNameController;

  @override
  void initState() {
    super.initState();
    _coachNameController = TextEditingController(
      text: widget.controller.coachName ?? '',
    );
  }

  @override
  void dispose() {
    _coachNameController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_coachNameController.text.trim().isNotEmpty) {
      widget.controller.coachName = _coachNameController.text.trim();
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingBase(
      currentStep: 6,
      totalSteps: 8,
      title: 'Who\'s your coach?',
      subtitle: 'Enter your coach\'s name',
      onBack: widget.onBack,
      onNext: _handleNext,
      isNextEnabled: _coachNameController.text.trim().isNotEmpty,
      child: TextField(
        controller: _coachNameController,
        decoration: const InputDecoration(
          labelText: 'Coach Name',
          hintText: 'Enter coach name',
          prefixIcon: Icon(Icons.person_pin),
        ),
        textCapitalization: TextCapitalization.words,
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: (_) => _handleNext(),
      ),
    );
  }
}
