import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_app/services/database.dart';
import 'package:nutricare_app/reusable_widget/snack_bar.dart';
import 'package:nutricare_app/reusable_widget/button.dart';
import 'package:nutricare_app/reusable_widget/textfield_v2.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  bool isEmailVerified = false;
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email ?? '';
        emailController.text = userEmail;
      });
      
      await user.reload();
      setState(() {
        isEmailVerified = user.emailVerified;
      });
    }
  }

  Future<void> _resendVerification() async {
    setState(() {
      isLoading = true;
    });

    String result = await AuthServices().resendEmailVerification();
    
    setState(() {
      isLoading = false;
    });

    showSnackBar(context, result);
    
    // Refresh verification status after a delay
    Future.delayed(Duration(seconds: 2), () {
      _checkVerificationStatus();
    });
  }

  Future<void> _sendPasswordReset() async {
    if (emailController.text.isEmpty) {
      showSnackBar(context, 'Please enter your email address');
      return;
    }

    setState(() {
      isLoading = true;
    });

    String result = await AuthServices().sendVerificationToEmail(emailController.text.trim());
    
    setState(() {
      isLoading = false;
    });

    showSnackBar(context, result);
  }

  Future<void> _refreshStatus() async {
    setState(() {
      isLoading = true;
    });

    await _checkVerificationStatus();
    
    setState(() {
      isLoading = false;
    });

    if (isEmailVerified) {
      showSnackBar(context, 'Email verified successfully! You can now log in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Colors.black,
              Color(0xFF0A3D00),
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                
                // Icon
                Icon(
                  isEmailVerified ? Icons.verified : Icons.email_outlined,
                  size: 60,
                  color: isEmailVerified ? Colors.green : Colors.orange,
                ),
                
                SizedBox(height: 20),
                
                // Title
                Text(
                  isEmailVerified ? 'Email Verified!' : 'Email Verification Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 20),
                
                // Status message
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isEmailVerified ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isEmailVerified ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isEmailVerified 
                          ? 'Your email has been verified successfully!'
                          : 'Please verify your email to continue using NutriCare.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!isEmailVerified) ...[
                        SizedBox(height: 10),
                        Text(
                          'Email: $userEmail',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                if (!isEmailVerified) ...[
                  // Instructions
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'If you didn\'t receive the email:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('• Check your spam/junk folder', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('• Wait 2-3 minutes for delivery', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('• Make sure the email address is correct', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('• Try resending the verification email', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Email input for password reset
                  InputTextV2(
                    textEditingController: emailController,
                    hintText: 'Enter your email address',
                    icon: Icons.email_outlined,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Action buttons
                  isLoading
                      ? CircularProgressIndicator(color: Colors.green)
                      : Column(
                          children: [
                            MyButton(
                              onTab: _resendVerification,
                              text: 'Resend Verification Email',
                            ),
                          ],
                        ),
                ] else ...[
                  // Verified state
                  MyButton(
                    onTab: () {
                      Navigator.pushReplacementNamed(context, '/home-screen');
                    },
                    text: 'Continue to App',
                  ),
                ],
                
                SizedBox(height: 20),
                
                // Back to login
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login-screen');
                  },
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


