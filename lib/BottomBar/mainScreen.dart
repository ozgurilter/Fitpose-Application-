

import 'package:fitness_tracking_app/BottomBar/anasayfa/anasayfa.dart';
import 'package:fitness_tracking_app/BottomBar/exercise/videoAnalysisPage.dart';
import 'package:fitness_tracking_app/BottomBar/profilePage.dart';
import 'package:fitness_tracking_app/BottomBar/analiz/analysisPage.dart';
import 'package:fitness_tracking_app/BottomBar/exercise/exerciseSelectionPage.dart';
import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:fitness_tracking_app/BottomBar/social/socialPage.dart';
import 'package:fitness_tracking_app/provider/analysisFlowProvider.dart';
import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:provider/provider.dart';
import 'package:fitness_tracking_app/provider/socialProvider.dart';

class MainScreen extends StatefulWidget {
  final UserModel user;

  const MainScreen({Key? key, required this.user}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _pageController = PageController(initialPage: 0);
  final _controller = NotchBottomBarController(index: 0);
  int maxCount = 5;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SocialProvider>(context, listen: false).initialize(widget.user.userId);

      // AnalysisFlowProvider'ı başlat
      Provider.of<AnalysisFlowProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildActivityPage();
      case 2:
        return _buildFitnessOrAnalysisPage();
      case 3:
        return _buildSocialPage();
      case 4:
        return _buildProfilePage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return HomePage(currentUser: widget.user);
  }

  Widget _buildActivityPage() {
    return AnalysisPage(
      currentUser: widget.user,
      bottomBarController: _controller,
      pageController: _pageController,
    );
  }

  Widget _buildFitnessOrAnalysisPage() {
    // AnalysisFlowProvider'dan durumu kontrol et
    return Consumer<AnalysisFlowProvider>(
      builder: (context, provider, child) {
        // Eğer egzersiz seçilmişse ve analiz devam ediyorsa
        if (provider.selectedExercise != null && provider.isAnalysisInProgress) {
          return VideoAnalysisPage(
            currentUser: widget.user,
            selectedExercise: provider.selectedExercise!,
            exerciseDisplayName: provider.exerciseDisplayName!,
            onNewAnalysis: () {
              // Yeni analiz için flow'u sıfırla
              provider.resetAnalysisFlow();
            },
          );
        }
        // Eğer egzersiz seçilmemişse veya analiz tamamlanmışsa
        else {
          return ExerciseSelectionPage(
            currentUser: widget.user,
            onExerciseSelected: (exercise, displayName) {
              // Seçilen egzersizi kaydet
              provider.setSelectedExercise(exercise, displayName);
              // Analiz durumunu başlat
              provider.startAnalysis();
            },
          );
        }
      },
    );
  }

  Widget _buildSocialPage() {
    return SocialPage(currentUser: widget.user);
  }

  Widget _buildProfilePage() {
    return ProfilePage(user: widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          maxCount,
              (index) => _getPage(index),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: AnimatedNotchBottomBar(
        kBottomRadius: 28.0,
        removeMargins: true,
        color: Colors.white,
        notchBottomBarController: _controller,
        textOverflow: TextOverflow.visible,
        notchColor: Color(0xFF5046E5),
        bottomBarWidth: 350,
        showLabel: false,
        notchShader: SweepGradient(
          startAngle: 0,
          endAngle: 2 * 3.1416,
          colors: [
            Color(0xFFFF7D30), // Turuncu
            Color(0xFF5046E5), // Mevcut mor tonu
            Color(0xFF5B86E5), // Mavi tonu
            Color(0xFFFF7D30), // Turuncuya geri dön, döngü tamamlansın
          ],
          stops: [0.0, 0.2, 0.75, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(0, 0), radius: 100)),

        durationInMilliSeconds: 300,
        bottomBarItems: [
          BottomBarItem(
            inActiveItem: Icon(Icons.home_outlined, color: Colors.blueGrey),
            activeItem: Icon(Icons.home, color: Colors.white),
            itemLabel: 'Ana Sayfa',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.run_circle_outlined, color: Colors.blueGrey),
            activeItem: Icon(Icons.run_circle, color: Colors.white),
            itemLabel: 'Aktiviteler',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.add_box, color: Colors.blueGrey),
            activeItem: Icon(Icons.add_box, color: Colors.white),
            itemLabel: 'Fitness',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.people_outline, color: Colors.blueGrey),
            activeItem: Icon(Icons.people, color: Colors.white),
            itemLabel: 'Sosyal',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.person_outline, color: Colors.blueGrey),
            activeItem: Icon(Icons.person, color: Colors.white),
            itemLabel: 'Profil',
          ),
        ],
        onTap: (index) {
          _pageController.jumpToPage(index);
        },
        kIconSize: 24.0,
      ),
    );
  }
}