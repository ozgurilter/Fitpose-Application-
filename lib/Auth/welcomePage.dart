import 'package:fitness_tracking_app/Auth/LoginScreen.dart';
import 'package:fitness_tracking_app/Auth/registerScreen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    final screenWidth = size.width;


    final horizontalPadding = screenWidth * 0.08;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAFA),
              Color(0xFFF0F4FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                // Üst boşluk - duyarlı
                SizedBox(height: screenHeight * 0.08),

                // Uygulama logosu/illüstrasyonu - duyarlı
                Container(
                  height: screenHeight * 0.35,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Arka plan efekti
                      Container(
                        width: screenWidth * 0.7,
                        height: screenWidth * 0.7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0x156366F1),  // Şeffaflık ile çok açık indigo
                              Colors.transparent,
                            ],
                            stops: [0.2, 1.0],
                          ),
                        ),
                      ),
                      // SVG Görüntüsü
                      SvgPicture.asset(
                        'assets/images/fitness_pose.svg',
                        height: screenHeight * 0.3,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          Color(0xFF5046E5), // İndigo
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),

                // Uygulama adı
                Text(
                  'FitPose',
                  style: TextStyle(
                    fontSize: screenWidth * 0.12, // Duyarlı yazı tipi boyutu
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5046E5), // İndigo
                    letterSpacing: 0.5,
                    fontFamily: 'Poppins', // Modern yazı tipi
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Slogan
                Text(
                  'Formunu Mükemmelleştir, Fitnesını Yükselt',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04, // Duyarlı yazı tipi boyutu
                    color: Color(0xFF6B7280), // Modern gri
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                ),

                // Esnek ara boşluk
                Spacer(),

                // Giriş Yap Butonu - duyarlı
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.07,
                  decoration: BoxDecoration(
                    color: Color(0xFF5046E5), // İndigo
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF5046E5).withOpacity(0.2),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: LoginPage(),
                          duration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'GİRİŞ YAP',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.025),

                // Hesap Oluştur Butonu - duyarlı
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.07,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFFE5E7EB), // Çok açık gri kenar
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.rightToLeft,
                          child: RegisterScreen(),
                          duration: const Duration(milliseconds: 400),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF5046E5),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'HESAP OLUŞTUR',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5046E5), // İndigo
                        letterSpacing: 0.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.08),
              ],
            ),
          ),
        ),
      ),
    );
  }
}