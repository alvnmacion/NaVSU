import 'package:flutter/material.dart';
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
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: fontSizeTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageTransition(
                            child: const MapScreen(),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
                      },
                      child: Container(
                        width: size.width,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: paddingVertical / 2,
                        ),
                        child: Center(
                          child: Text(
                            'Login as Guest',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSizeButton,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR',
                            style: TextStyle(fontSize: fontSizeButton),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        await _handleSignIn(context);
                      },
                      child: Container(
                        width: size.width,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 55,
                          vertical: paddingVertical / 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: isSmall ? 20 : isMedium ? 25 : 30,
                              child: Image.asset('assets/images/google.png'),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Login with Google',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: fontSizeButton,
                              ),
                            ),
                          ],
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

    Navigator.pushReplacement(
                          context,
                          PageTransition(
                            child: const MapScreen(),
                            type: PageTransitionType.bottomToTop,
                          ),
                        );
   
  }

}