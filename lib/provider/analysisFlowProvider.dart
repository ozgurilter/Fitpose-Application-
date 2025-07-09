
import 'package:fitness_tracking_app/BottomBar/exercise/exerciseAnalysisService.dart';
import 'package:flutter/foundation.dart';

class AnalysisFlowProvider extends ChangeNotifier {

  String? _selectedExercise;
  String? _exerciseDisplayName;
  bool _isAnalysisInProgress = false;
  bool _isAnalysisComplete = false;

  // Getters
  String? get selectedExercise => _selectedExercise;
  String? get exerciseDisplayName => _exerciseDisplayName;
  bool get isAnalysisInProgress => _isAnalysisInProgress;
  bool get isAnalysisComplete => _isAnalysisComplete;

  // Provider'ı başlat
  void initialize() {
    _selectedExercise = null;
    _exerciseDisplayName = null;
    _isAnalysisInProgress = false;
    _isAnalysisComplete = false;
    notifyListeners();
  }

  // Egzersiz seçildiğinde
  void setSelectedExercise(String exercise, String displayName) {
    _selectedExercise = exercise;
    _exerciseDisplayName = displayName;
    _isAnalysisComplete = false;
    notifyListeners();
  }

  // Analiz başlatıldığında
  void startAnalysis() {
    _isAnalysisInProgress = true;
    _isAnalysisComplete = false;
    notifyListeners();
  }

  // Analiz tamamlandığında
  void completeAnalysis() {
    _isAnalysisComplete = true;
    notifyListeners();
  }

  // Analiz akışını sıfırla (yeni analize başlamak için)
  void resetAnalysisFlow() {
    _selectedExercise = null;
    _exerciseDisplayName = null;
    _isAnalysisInProgress = false;
    _isAnalysisComplete = false;

    // ExerciseAnalysisService'i de sıfırla
    ExerciseAnalysisService().reset();

    notifyListeners();
  }
}