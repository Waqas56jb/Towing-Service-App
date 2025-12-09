import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../widgets/custom_button.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 9, 4, 34),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Column(
              children: [
                Image.asset('assets/plane_wing.png', height: 180),
                const SizedBox(height: 10),
                const Text(
                  'REV UP YOUR RIDE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Image.asset(
                  'assets/plane_window.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Your Gateway to Auto Care Excellence',
                textAlign: TextAlign.center,
                style: headingStyle,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Book Services, Track\nMaintenance, Ask Experts & More',
                textAlign: TextAlign.center,
                style: subHeadingStyle,
              ),
            ),
            const SizedBox(height: 30),

            CustomButton(
              text: 'Get Started',
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
            ),

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Your All-in-One Auto Maintenance Hub © 2025 TuneUp\nApp Design by Rovaid and Hassan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
