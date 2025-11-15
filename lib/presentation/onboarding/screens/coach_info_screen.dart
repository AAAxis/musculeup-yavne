import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:muscleup/presentation/onboarding/onboarding_controller.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/models/user_model.dart';

class CoachInfoScreen extends StatefulWidget {
  final OnboardingController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const CoachInfoScreen({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<CoachInfoScreen> createState() => _CoachInfoScreenState();
}

class _CoachInfoScreenState extends State<CoachInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coachNameController = TextEditingController();
  final _coachEmailController = TextEditingController();
  final _coachPhoneController = TextEditingController();
  final _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  List<UserModel> _coaches = [];
  List<UserModel> _filteredCoaches = [];
  UserModel? _selectedCoach;
  bool _isLoadingCoaches = false;
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _coachNameController.text = widget.controller.coachName ?? '';
    _coachEmailController.text = widget.controller.coachEmail ?? '';
    _coachPhoneController.text = widget.controller.coachPhone ?? '';
    _loadCoaches();
    
    // Add listener for search
    _searchController.addListener(_filterCoaches);
  }
  
  Future<void> _loadCoaches() async {
    setState(() {
      _isLoadingCoaches = true;
    });
    
    try {
      final coaches = await _firestoreService.getCoaches();
      setState(() {
        _coaches = coaches;
        _filteredCoaches = coaches;
        
        // Try to find and select the coach if email matches
        if (widget.controller.coachEmail != null) {
          final foundCoach = coaches.firstWhere(
            (coach) => coach.email == widget.controller.coachEmail,
            orElse: () => coaches.isNotEmpty ? coaches.first : UserModel(email: '', name: ''),
          );
          if (foundCoach.email.isNotEmpty) {
            _selectedCoach = foundCoach;
            _coachNameController.text = foundCoach.name;
            _coachEmailController.text = foundCoach.email;
            // Keep existing phone from controller if already set
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת המאמנים: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCoaches = false;
        });
      }
    }
  }
  
  void _filterCoaches() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCoaches = _coaches;
      } else {
        _filteredCoaches = _coaches.where((coach) {
          return coach.name.toLowerCase().contains(query) ||
                 coach.email.toLowerCase().contains(query);
        }).toList();
      }
    });
  }
  
  void _selectCoach(UserModel coach) {
    setState(() {
      _selectedCoach = coach;
      _coachNameController.text = coach.name;
      _coachEmailController.text = coach.email;
      // Keep existing phone if user already entered one, otherwise leave empty
      if (_coachPhoneController.text.trim().isEmpty) {
        _coachPhoneController.text = '';
      }
      _isSearchOpen = false;
      _searchController.clear();
      _filteredCoaches = _coaches;
    });
  }

  @override
  void dispose() {
    _coachNameController.dispose();
    _coachEmailController.dispose();
    _coachPhoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleNext() {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    
    // Check if coach is selected
    if (_selectedCoach == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אנא בחר מאמן מהרשימה')),
      );
      return;
    }
    
    // Wait a bit for keyboard to dismiss, then validate
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_formKey.currentState!.validate()) {
        widget.controller.coachName = _coachNameController.text.trim();
        widget.controller.coachEmail = _coachEmailController.text.trim();
        // Coach phone is not required (matching web version)
        widget.controller.coachPhone = null;
        widget.onNext();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('מידע על המאמן'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack,
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Progress Indicator
                LinearProgressIndicator(
                  value: 3 / 4, // Step 3 of 4
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'פרטי המאמן שלך',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'מי ילווה אותך במסע הכושר שלך?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 32),

              // Coach Selection Field
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'בחר מאמן *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isSearchOpen = !_isSearchOpen;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_pin, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _isLoadingCoaches
                                  ? const Text(
                                      'טוען מאמנים...',
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  : _selectedCoach != null
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedCoach!.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              _selectedCoach!.email,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          'בחר מאמן מהרשימה',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                            ),
                            Icon(
                              _isSearchOpen ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isSearchOpen) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => _filterCoaches(),
                                decoration: InputDecoration(
                                  hintText: 'חפש מאמן לפי שם או אימייל...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.green[600]!, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: _filteredCoaches.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'לא נמצא מאמן',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _filteredCoaches.length,
                                      itemBuilder: (context, index) {
                                        final coach = _filteredCoaches[index];
                                        final isSelected = _selectedCoach?.email == coach.email;
                                        return InkWell(
                                          onTap: () => _selectCoach(coach),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.green[50]
                                                  : Colors.transparent,
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey[200]!,
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green[600],
                                                    size: 20,
                                                  )
                                                else
                                                  const SizedBox(width: 20),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        coach.name,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w600
                                                              : FontWeight.normal,
                                                          color: isSelected
                                                              ? Colors.green[700]
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                      Text(
                                                        coach.email,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_selectedCoach != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'שם: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(_coachNameController.text),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'אימייל: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Expanded(child: Text(_coachEmailController.text)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'המשך',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

