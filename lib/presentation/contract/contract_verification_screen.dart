import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:muscleup/presentation/onboarding/contract_screen.dart';
import 'package:muscleup/data/services/firestore_service.dart';

class ContractVerificationScreen extends StatefulWidget {
  final User firebaseUser;
  final UserModel userModel;

  const ContractVerificationScreen({
    super.key,
    required this.firebaseUser,
    required this.userModel,
  });

  @override
  State<ContractVerificationScreen> createState() => _ContractVerificationScreenState();
}

class _ContractVerificationScreenState extends State<ContractVerificationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('אימות חוזה'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.userModel.hasSignedContract 
                ? Icons.pending_actions
                : Icons.description_outlined,
              size: 80,
              color: widget.userModel.hasSignedContract 
                ? Colors.orange 
                : Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            
            Text(
              widget.userModel.hasSignedContract 
                ? 'ממתין לאישור'
                : 'נדרש לחתום על חוזה',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Text(
              widget.userModel.hasSignedContract
                ? 'החוזה שלך נמצא בבדיקה. נודיע לך כאשר החשבון יאושר.'
                : 'כדי להמשיך להשתמש באפליקציה, עליך לחתום על חוזה החברות.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            if (!widget.userModel.hasSignedContract) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _navigateToContractScreen,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.description),
                  label: const Text(
                    'חתום על החוזה',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            
            const SizedBox(height: 24),
            
            Text(
              'אם יש לך שאלות, אנא פנה לתמיכה.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToContractScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContractScreen(
          userGender: widget.userModel.gender ?? 'male',
          userName: widget.userModel.name.isNotEmpty ? widget.userModel.name : widget.firebaseUser.displayName ?? '',
          userId: widget.firebaseUser.uid,
          onContractSigned: _handleContractSigned,
        ),
      ),
    );
  }

  Future<void> _handleContractSigned(String fullName, String signatureUrl) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update user with contract signature
      await _firestoreService.updateUser(widget.firebaseUser.uid, {
        'hasSignedContract': true,
        'contract_signed_at': DateTime.now(),
        'contract_signature_url': signatureUrl,
        'contract_full_name': fullName,
        'contract_commitments': ['אני מתחייב לעמוד בתנאי החוזה'],
      });

      // Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בחתימה על החוזה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh user data from Firestore
      final updatedUser = await _firestoreService.getUser(widget.firebaseUser.uid);
      
      if (updatedUser != null && 
          updatedUser.hasSignedContract) {
        // User has signed contract, trigger a rebuild of the AuthWrapper
        if (mounted) {
          // This will cause the AuthWrapper to rebuild and check the new status
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        // Update the current screen with new data
        if (mounted) {
          setState(() {
            // The widget will rebuild with the current data
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ברענון הסטטוס: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
