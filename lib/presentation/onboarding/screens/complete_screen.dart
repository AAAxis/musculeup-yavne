import 'package:flutter/material.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';

class CompleteScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onBack;

  const CompleteScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  State<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends State<CompleteScreen> {
  final _firestoreService = FirestoreService();
  bool _isSaving = false;

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _complete() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = UserModel(
        email: widget.controller.firebaseUser.email!,
        name: widget.controller.data.name!,
        photoUrl: widget.controller.firebaseUser.photoURL,
        gender: widget.controller.data.gender!,
        birthDate: _formatDate(widget.controller.data.birthDate!),
        height: widget.controller.data.height!,
        initialWeight: widget.controller.data.weight!,
        coachName: widget.controller.data.coachName!,
        coachEmail: widget.controller.data.coachEmail!,
        coachPhone: widget.controller.data.coachPhone,
        role: 'user',
        status: 'active',
      );

      await _firestoreService.setUser(
        widget.controller.firebaseUser.uid,
        user,
        isNewUser: true,
      );

      if (mounted) {
        // This will trigger a rebuild in AuthWrapper which will navigate to main app
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    Icon(
                      Icons.check_circle,
                      size: 100,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'All Set!',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your profile is ready. Let\'s start your fitness journey!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Summary Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Profile',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _SummaryRow(
                              icon: Icons.person,
                              label: 'Name',
                              value: widget.controller.data.name!,
                            ),
                            _SummaryRow(
                              icon: Icons.wc,
                              label: 'Gender',
                              value: widget.controller.data.gender!
                                  .capitalize(),
                            ),
                            _SummaryRow(
                              icon: Icons.height,
                              label: 'Height',
                              value: '${widget.controller.data.height} cm',
                            ),
                            _SummaryRow(
                              icon: Icons.monitor_weight,
                              label: 'Weight',
                              value: '${widget.controller.data.weight} kg',
                            ),
                            _SummaryRow(
                              icon: Icons.person_pin,
                              label: 'Coach',
                              value: widget.controller.data.coachName!,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _complete,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Start Training'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSaving ? null : widget.onBack,
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

