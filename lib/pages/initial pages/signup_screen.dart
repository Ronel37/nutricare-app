import 'package:flutter/material.dart';
import 'package:nutricare_app/pages/initial%20pages/login_screen.dart';
import 'package:nutricare_app/reusable_widget/loading_dots.dart';
import 'package:nutricare_app/reusable_widget/snack_bar.dart';
import 'package:nutricare_app/reusable_widget/textfield_v2.dart';
import 'package:nutricare_app/services/database.dart';
import 'package:nutricare_app/reusable_widget/button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isLoading = false;
  bool isAgreed = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
  }

  void signUpUser() async {
    setState(() {
      isLoading = true;
    });

    if (!isAgreed) {
      setState(() {
        isLoading = false;
      });
      showSnackBar(
          context, 'You must agree to the terms and conditions to sign up.');
      return;
    }

    String res = await AuthServices().signUpUser(
      email: emailController.text,
      password: passwordController.text,
      name: nameController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (res == "success") {
      showSnackBar(
        context,
        "Sign-up successful! Please check your email for verification and then login.",
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } else {
      setState(() {
        emailController.clear();
        passwordController.clear();
        nameController.clear();
      });
      showSnackBar(context, res);
    }
  }

  void showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Terms and Conditions",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome to NutriCare! Before you proceed, please read the following terms and conditions carefully.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                Text(
                  "1. **Acceptance of Terms**",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "By signing up and using NutriCare, you agree to comply with these terms and conditions. If you do not agree, you must not use the service.",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Text(
                  "2. **Privacy Policy**",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "We value your privacy. Your personal information will not be shared with third parties without your consent, except as required by law.",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Text(
                  "3. **Account Security**",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account.",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Text(
                  "4. **Use of Service**",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "You agree not to use NutriCare for any unlawful or harmful activities, including but not limited to spamming, fraud, and distribution of malware.",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Text(
                  "5. **Termination**",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "We reserve the right to suspend or terminate your account if you violate these terms. Upon termination, you may lose access to your account and data.",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Text(
                  "6. **Limitation of Liability**",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "NutriCare is not responsible for any loss, damage, or injury resulting from the use of our service, including data loss or financial loss.",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Text(
                  "7. **Changes to the Terms**",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "We may update these terms from time to time. Any changes will be communicated to you, and continued use of the service signifies your acceptance of the updated terms.",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 20),
                Text(
                  "By agreeing to these terms, you confirm that you have read, understood, and accepted the terms and conditions of NutriCare.",
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "Close",
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    height: 10,
                  ),
                  Text(
                    'Create your NutriCare Account',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15,),
                  InputTextV2(
                      textEditingController: nameController,
                      hintText: 'Enter your Full Name',
                      icon: Icons.person_outlined),
                  InputTextV2(
                      textEditingController: emailController,
                      hintText: 'Enter your Email',
                      icon: Icons.email_outlined),
                  InputTextV2(
                      isPass: true,
                      textEditingController: passwordController,
                      hintText: 'Enter your Password',
                      icon: Icons.lock_outline_rounded),
                  SizedBox(height: 70),
                  isLoading
                      ? const LoadingDots()
                      : Padding(
                          padding: const EdgeInsets.symmetric(),
                          child: MyButton(onTab: signUpUser, text: 'Sign Up'),
                        ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          ' Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Checkbox(
                          value: isAgreed,
                          onChanged: (bool? value) {
                            setState(() {
                              isAgreed = value!;
                            });
                          },
                          activeColor: Color(0xFF4CAF50),
                          checkColor: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const Text(
                              "I agree to the ",
                              style: TextStyle(color: Colors.grey),
                            ),
                            GestureDetector(
                              onTap: showTermsAndConditions,
                              child: const Text(
                                "Terms and Conditions",
                                style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
