
import 'package:fitness_tracking_app/preLogin/onBoardingScreen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  // Modern renk paleti - Uygulamanın diğer kısımlarına uyumlu
  static const Color primaryBlue = Color(0xFF416FDF);
  static const Color secondaryTeal = Color(0xFF00BFA6);
  static const Color accentPink = Color(0xFFF857A6);
  static const Color darkBackground = Color(0xFF1A1D2E);
  static const Color lightText = Color(0xFFF5F6FA);

  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _loadingController.forward().whenComplete(() {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final isSmallScreen = size.width < 375;
    final isLandscape = size.width > size.height;
    final safeAreaPadding = mediaQuery.padding;

    // Responsive boyutlar
    final logoSize = isSmallScreen ? 150.0 : size.width * 0.4 > 240 ? 240.0 : size.width * 0.4;
    final titleSize = isSmallScreen ? 32.0 : 42.0;
    final subtitleSize = isSmallScreen ? 14.0 : 16.0;
    final progressWidth = isSmallScreen ? size.width * 0.6 : size.width * 0.4;

    return Scaffold(
      backgroundColor: SplashScreen.darkBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Gradient arka plan
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              SplashScreen.darkBackground,
              Color(0xFF2A2D40),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: isLandscape
                    ? _buildLandscapeLayout(logoSize, titleSize, subtitleSize, progressWidth)
                    : _buildPortraitLayout(logoSize, titleSize, subtitleSize, progressWidth),
              );
            },
          ),
        ),
      ),
    );
  }

  // Dikey ekran layout
  Widget _buildPortraitLayout(double logoSize, double titleSize, double subtitleSize, double progressWidth) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Üst boşluk
        const Spacer(flex: 1),

        // Logo animasyonu
        Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SplashScreen.primaryBlue.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Lottie.asset(
                    'assets/animations/fitness_animation.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 48),

        // Başlık ve alt başlık
        Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value * 0.7),
            child: Column(
              children: [
                // Başlık
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      SplashScreen.primaryBlue,
                      SplashScreen.accentPink,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'PoseFit',
                    style: GoogleFonts.montserrat(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      height: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Alt başlık
                Text(
                  'AI-Powered Fitness Tracking',
                  style: GoogleFonts.poppins(
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w400,
                    color: SplashScreen.lightText.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        const Spacer(flex: 1),

        // Yükleme çubuğu
        Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Yükleme çubuğu
              Container(
                width: progressWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: SplashScreen.primaryBlue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: _loadingController.value,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SplashScreen.primaryBlue,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Yükleme yüzdesi
              Text(
                '${(_loadingController.value * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w600,
                  color: SplashScreen.lightText.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  // Yatay ekran layout
  Widget _buildLandscapeLayout(double logoSize, double titleSize, double subtitleSize, double progressWidth) {
    // Yatay ekranda daha kompakt bir tasarım
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo kısmı
        Expanded(
          flex: 3,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(_slideAnimation.value * -1, 0),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: logoSize * 0.9,
                  height: logoSize * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SplashScreen.primaryBlue.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Lottie.asset(
                      'assets/animations/fitness_animation.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Metin ve progress kısmı
        Expanded(
          flex: 4,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(_slideAnimation.value, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        SplashScreen.primaryBlue,
                        SplashScreen.accentPink,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'PoseFit',
                      style: GoogleFonts.montserrat(
                        fontSize: titleSize * 0.9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Alt başlık
                  Text(
                    'AI-Powered Fitness Tracking',
                    style: GoogleFonts.poppins(
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w400,
                      color: SplashScreen.lightText.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Yükleme çubuğu
                  Container(
                    width: progressWidth * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: SplashScreen.primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: _loadingController.value,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          SplashScreen.primaryBlue,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Yükleme yüzdesi
                  Text(
                    '${(_loadingController.value * 100).toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w600,
                      color: SplashScreen.lightText.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}