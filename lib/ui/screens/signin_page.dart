import 'package:flutter/material.dart';
import 'package:navsu/backend/firebaseauth.dart';
import 'package:navsu/ui/screens/map_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Import this

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Define breakpoints
    final isSmall = size.width < 600;
    final isMedium = size.width >= 600 && size.width < 1024;

    // Adjustments based on screen size
    double logoHeight = isSmall ? 400 : isMedium ? 500 : 500;
    double fontSizeTitle = isSmall ? 28 : isMedium ? 32 : 35;
    double fontSizeButton = isSmall ? 16 : isMedium ? 18 : 20;
    double paddingHorizontal = isSmall ? 20 : isMedium ? 40 : 60;
    double paddingVertical = isSmall ? 20 : isMedium ? 30 : 40;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent, // Make status bar transparent
        statusBarIconBrightness: Brightness.light, // Set icon brightness
      ),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: size.width,
                  height: logoHeight,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: paddingVertical,
                horizontal: paddingHorizontal,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: logoHeight + 20,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome to NaVSU',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your ultimate navigation companion for Visayas State University. Find your way around campus with ease.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSizeButton,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.08),
                    Container(
                      width: size.width,
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _handleSignIn(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/google.png',
                                  height: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: fontSizeButton,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'By continuing, you agree to our Terms of Service',
                        style: TextStyle(
                          fontSize: fontSizeButton - 2,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context) async {
    FirebaseAuthService authService = FirebaseAuthService();
    User? user = await authService.signInWithGoogle();
    
    if (user != null) {
      await authService.saveUserDetails(user);
      Navigator.pushReplacement(
        context,
        PageTransition(
          child: const MapScreen(),
          type: PageTransitionType.bottomToTop,
        ),
      );
    }
  }

}