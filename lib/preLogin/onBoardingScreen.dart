
import 'package:flutter/material.dart';
import 'package:concentric_transition/concentric_transition.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_tracking_app/Auth/welcomePage.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  // Uygulama genelinde tutarlı renkler
  static const Color primaryBlue = Color(0xFF416FDF);
  static const Color secondaryBlue = Color(0xFF5046E5);
  static const Color lightPurple = Color(0xFF7C3AED);
  static const Color teal = Color(0xFF06B6D4);
  static const Color secondaryTeal = Color(0xFF00BFA6);
  static const Color darkBackground = Color(0xFF1A1D2E);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final isSmallScreen = screenWidth < 375;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Ana içerik - PageView
            PageView.builder(
              controller: _pageController,
              itemCount: _onboardingData.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _isLastPage = index == _onboardingData.length - 1;
                });
              },
              itemBuilder: (context, index) {
                final page = _onboardingData[index];
                return _buildPage(page, isLandscape, size);
              },
            ),

            // Üst kısım - Skip butonu
            Positioned(
              top: 16,
              right: 16,
              child: !_isLastPage
                  ? TextButton(
                onPressed: () => _finishIntro(context),
                child: Text(
                  'Atla',
                  style: GoogleFonts.poppins(
                    color: OnboardingScreen.primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),

            // Alt kısım - İndikatörler ve butonlar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Sayfa indikatörleri
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingData.length,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? _getPageColor(index)
                                : _getPageColor(index).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Navigation butonları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Geri butonu
                        _currentPage > 0
                            ? IconButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.ease,
                            );
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: OnboardingScreen.primaryBlue,
                            ),
                          ),
                        )
                            : const SizedBox(width: 48),

                        // İleri/Bitir butonu
                        _buildNavigationButton(context),
                      ],
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

  // Sayfa rengi seçimi
  Color _getPageColor(int index) {
    switch (index) {
      case 0:
        return OnboardingScreen.primaryBlue;
      case 1:
        return OnboardingScreen.lightPurple;
      case 2:
        return OnboardingScreen.teal;
      default:
        return OnboardingScreen.primaryBlue;
    }
  }

  // İleri/Bitir butonu widget'ı
  Widget _buildNavigationButton(BuildContext context) {
    return _isLastPage
        ? _buildPrimaryButton(
      context: context,
      text: 'BAŞLA',
      onPressed: () => _finishIntro(context),
      color: OnboardingScreen.teal,
      isFullWidth: true,
    )
        : _buildFloatingButton(
      onPressed: () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.ease,
        );
      },
      color: _getPageColor(_currentPage),
    );
  }

  // İleri butonu (yuvarlak)
  Widget _buildFloatingButton({
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  // Birincil buton (dikdörtgen, geniş)
  Widget _buildPrimaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required Color color,
    bool isFullWidth = false,
  }) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: isFullWidth ? size.width * 0.5 : null,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Onboarding sayfasını oluştur
  Widget _buildPage(_OnboardingPageData page, bool isLandscape, Size size) {
    if (isLandscape) {
      return _buildLandscapePage(page, size);
    } else {
      return _buildPortraitPage(page, size);
    }
  }

  // Dikey ekran düzeni
  Widget _buildPortraitPage(_OnboardingPageData page, Size size) {
    final screenHeight = size.height;
    final screenWidth = size.width;
    final isSmallScreen = screenWidth < 375;

    // Responsive ölçüler
    final animationSize = isSmallScreen ? screenWidth * 0.6 : screenWidth * 0.5;
    final titleSize = isSmallScreen ? 24.0 : 28.0;
    final descSize = isSmallScreen ? 14.0 : 16.0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            page.backgroundColor,
            page.backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Animasyon
          Container(
            width: animationSize,
            height: animationSize,
            decoration: BoxDecoration(
              color: page.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.accentColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Lottie.asset(
                page.animationPath,
                width: animationSize * 0.85,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const Spacer(flex: 1),

          // İçerik kartı
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık
                Text(
                  page.title,
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: page.accentColor,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Açıklama
                Text(
                  page.description,
                  style: GoogleFonts.poppins(
                    fontSize: descSize,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Alt boşluk (butonlar için yer)
          SizedBox(height: screenHeight * 0.16),
        ],
      ),
    );
  }

  // Yatay ekran düzeni
  Widget _buildLandscapePage(_OnboardingPageData page, Size size) {
    final screenHeight = size.height;
    final screenWidth = size.width;

    // Responsive ölçüler
    final animationSize = screenHeight * 0.5;
    final titleSize = 22.0;
    final descSize = 14.0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            page.backgroundColor,
            page.backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),

          // Animasyon - sol taraf
          Container(
            width: animationSize,
            height: animationSize,
            decoration: BoxDecoration(
              color: page.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.accentColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Lottie.asset(
                page.animationPath,
                width: animationSize * 0.85,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(width: 24),

          // İçerik - sağ taraf
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Başlık
                  Text(
                    page.title,
                    style: GoogleFonts.poppins(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: page.accentColor,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Açıklama
                  Text(
                    page.description,
                    style: GoogleFonts.poppins(
                      fontSize: descSize,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Onboarding'i bitir
  Future<void> _finishIntro(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  // Onboarding verileri
  static final List<_OnboardingPageData> _onboardingData = [
    _OnboardingPageData(
      title: 'Egzersizlerinizi Analiz Edin',
      description: 'Yapay zeka destekli kamera, egzersiz formunuzu gerçek zamanlı olarak analiz eder.',
      animationPath: 'assets/animations/fitness_animation.json',
      backgroundColor: Color(0xFFF8F9FA),
      accentColor: OnboardingScreen.primaryBlue,
    ),
    _OnboardingPageData(
      title: 'Anında Geri Bildirim Alın',
      description: 'Hareketlerinizin doğru olup olmadığını hemen öğrenin ve formunuzu geliştirin.',
      animationPath: 'assets/animations/fitness_animation.json',
      backgroundColor: Color(0xFFF5F3FF),
      accentColor: OnboardingScreen.lightPurple,
    ),
    _OnboardingPageData(
      title: 'İlerlemenizi Takip Edin',
      description: 'Zamanla gelişiminizi görerek motivasyonunuzu koruyun ve hedeflerinize ulaşın.',
      animationPath: 'assets/animations/fitness_animation.json',
      backgroundColor: Color(0xFFF0FDFB),
      accentColor: OnboardingScreen.teal,
    ),
  ];
}

class _OnboardingPageData {
  final String title;
  final String description;
  final String animationPath;
  final Color backgroundColor;
  final Color accentColor;

  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.animationPath,
    required this.backgroundColor,
    required this.accentColor,
  });
}