
import 'package:firebase_core/firebase_core.dart';
import 'package:fitness_tracking_app/Auth/welcomePage.dart';
import 'package:fitness_tracking_app/BottomBar/exercise/exerciseAnalysisService.dart';
import 'package:fitness_tracking_app/notificationService.dart';
import 'package:fitness_tracking_app/preLogin/SplashScreen.dart';
import 'package:fitness_tracking_app/firebase_options.dart';
import 'package:fitness_tracking_app/provider/analysisFlowProvider.dart';
import 'package:fitness_tracking_app/provider/socialProvider.dart';
import 'package:fitness_tracking_app/provider/userProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService().init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseAnalysisService()),
        ChangeNotifierProvider(create: (_) => AnalysisFlowProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:  InitializerWidget(),
    );
  }
}

class InitializerWidget extends StatefulWidget {
  @override
  _InitializerWidgetState createState() => _InitializerWidgetState();
}

class _InitializerWidgetState extends State<InitializerWidget> {
  Future<bool> _checkOnboardingStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboardingComplete') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOnboardingStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Yükleniyor durumu
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Hata durumu
          return Center(child: Text('Bir hata oluştu.'));
        } else {
          // Onboarding durumu
          bool onboardingComplete = snapshot.data ?? false;
          return onboardingComplete ? WelcomeScreen() : SplashScreen();
        }
      },
    );
  }
}

