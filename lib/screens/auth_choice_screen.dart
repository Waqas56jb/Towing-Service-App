import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/custom_button.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Welcome!", style: headingStyle),
              const SizedBox(height: 8),
              const Text(
                "Choose an option to continue",
                style: subHeadingStyle,
              ),
              const SizedBox(height: 40),

              CustomButton(
                text: "Login",
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Signup",
                onPressed: () => Navigator.pushNamed(context, '/signup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
