import 'dart:async';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_app/pages/initial%20pages/signup_screen.dart';
import 'package:nutricare_app/reusable_widget/loading_dots.dart';
import 'package:nutricare_app/reusable_widget/textfield_v2.dart';
import '../../reusable_widget/button.dart';
import '../../reusable_widget/snack_bar.dart';
import '../../services/database.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  Timer? _hideSystemUiTimer;
  bool _isAppBarVisible = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _hideSystemUI();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _hideSystemUiTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _scheduleHideSystemUI() {
    _hideSystemUiTimer?.cancel();
    _hideSystemUiTimer = Timer(const Duration(seconds: 3), () {
      _hideSystemUI();
    });
  }

  void _scrollListener() {
    if (_scrollController.offset > 10 && _isAppBarVisible) {
      setState(() {
        _isAppBarVisible = false;
      });
    } else if (_scrollController.offset <= 10 && !_isAppBarVisible) {
      setState(() {
        _isAppBarVisible = true;
      });
    }
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Email Verification Required",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Please check your email and verify your account before logging in.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 15),
              Text(
                "If you didn't receive the email:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text("• Check your spam/junk folder", style: TextStyle(fontSize: 14)),
              Text("• Wait a few minutes for delivery", style: TextStyle(fontSize: 14)),
              Text("• Try resending the verification email", style: TextStyle(fontSize: 14)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                String result = await AuthServices().resendEmailVerification();
                showSnackBar(context, result);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text("Resend Email"),
            ),
          ],
        );
      },
    );
  }

  Future<void> loginUsers() async {
    try {
      setState(() {
        isLoading = true;
      });

      String res = await AuthServices().loginUser(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      setState(() {
        isLoading = false;
      });

      if (res == "success") {
        Navigator.pushReplacementNamed(context, '/home-screen');
        showSnackBar(context, 'Login successful!');
      } else if (res == "admin") {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
        showSnackBar(context, 'Admin login successful!');
      } else if (res == "Please verify your email before logging in.") {
        Navigator.pushReplacementNamed(context, '/email-verification');
      } else {
        showSnackBar(context, res);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, 'An unknown error occurred');
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _scheduleHideSystemUI,
      onPanDown: (_) => _scheduleHideSystemUI(),
      child: Scaffold(
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
          child: Stack(
            children: [
              SingleChildScrollView(
                child: SafeArea(
                  child: SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 100,
                        ),
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Login to your NutriCare Account',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: height * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                          child: InputTextV2(
                              textEditingController: emailController,
                              hintText: 'Enter your Email',
                              icon: Icons.email_outlined),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                          child: InputTextV2(
                              isPass: true,
                              textEditingController: passwordController,
                              hintText: 'Enter your Password',
                              icon: Icons.lock_outline_rounded),
                        ),
                        SizedBox(
                          height: 150,
                        ),
                        isLoading
                            ? const LoadingDots()
                            : Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: width * 0.1),
                                child: MyButton(
                                  onTab: loginUsers,
                                  text: 'Log In',
                                ),
                              ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account?",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                ' Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: height * 0.02,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
