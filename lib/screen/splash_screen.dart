import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:eventapp/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // navigate to loginpage after 6 sec
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return; // safety check

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = [Colors.blue, Colors.purple, Colors.black];

    return Scaffold(
      backgroundColor: Colors.brown.shade50,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image container
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                  gradient: const LinearGradient(
                    colors: [Colors.yellow, Colors.red],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    "assets/image/smart.png",
                    fit: BoxFit.contain,

                    //Prevent crash if image missing vayo vane
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 100);
                    },
                  ),
                ),
              ),

              const Gap(10),

              AnimatedTextKit(
                animatedTexts: [
                  ColorizeAnimatedText(
                    "SMART EVENT",
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    colors: textColor,
                  ),
                ],
                isRepeatingAnimation: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
