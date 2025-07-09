import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fitness_tracking_app/notificationService.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

class ExerciseAnalysisService extends ChangeNotifier {
  static final ExerciseAnalysisService _instance = ExerciseAnalysisService._internal();

  // Singleton pattern
  factory ExerciseAnalysisService() {
    return _instance;
  }

  ExerciseAnalysisService._internal();

  // Analysis state
  bool _isAnalyzing = false;
  bool _isVideoUploaded = false;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _exerciseSegments = [];
  Map<String, dynamic> _videoInfo = {};
  Map<String, dynamic> _processingInfo = {};
  String _apiError = "";
  double _analysisProgress = 0.0;
  double _preprocessingProgress = 0.0;

  // Video file
  dynamic _videoFile;
  dynamic _processedVideoFile;
  double _videoDuration = 0.0;

  // Video settings
  final int _maxVideoDurationSeconds = 750; // 12.5 dakika
  final int _maxFileSizeMB = 200; // 200 MB

  // Connection settings
  final Duration _connectionTimeout = Duration(minutes: 10);

  // Analysis results - Bu önemli!
  Map<String, dynamic>? _analysisResults;

  // Computed properties
  String _primaryExercise = "";
  double _totalDuration = 0;
  int _exerciseCount = 0;

  // Getters
  bool get isAnalyzing => _isAnalyzing;
  bool get isVideoUploaded => _isVideoUploaded;
  bool get isProcessing => _isProcessing;
  List<Map<String, dynamic>> get exerciseSegments => _exerciseSegments;
  Map<String, dynamic> get videoInfo => _videoInfo;
  Map<String, dynamic> get processingInfo => _processingInfo;
  String get apiError => _apiError;
  double get analysisProgress => _isProcessing ? _preprocessingProgress : _analysisProgress;
  dynamic get videoFile => _videoFile;
  String get primaryExercise => _primaryExercise;
  double get totalDuration => _totalDuration;
  int get exerciseCount => _exerciseCount;
  double get videoDuration => _videoDuration;

  // Analysis results getter - Bu eksikti!
  Map<String, dynamic>? get analysisResults => _analysisResults;

  // Set video file and perform initial validation
  Future<bool> setVideoFile(dynamic videoFile) async {
    _videoFile = videoFile;
    _processedVideoFile = null;
    _isVideoUploaded = true;
    _exerciseSegments = [];
    _apiError = "";
    _analysisResults = null; // Reset analysis results

    // Check video duration and size
    bool isValid = await _validateVideo();

    notifyListeners();
    return isValid;
  }

  // Validate video duration and size
  Future<bool> _validateVideo() async {
    if (_videoFile == null) return false;

    try {
      // Check file size
      late int fileSize;
      if (kIsWeb) {
        // For web, get size from XFile
        fileSize = await (_videoFile as XFile).length();
      } else {
        // For mobile, get size from File
        fileSize = await File((_videoFile as XFile).path).length();
      }

      final fileSizeMB = fileSize / (1024 * 1024);
      if (fileSizeMB > _maxFileSizeMB) {
        _apiError = "Video dosyası çok büyük. Maksimum dosya boyutu: $_maxFileSizeMB MB";
        return false;
      }

      // Initialize VideoPlayerController to get duration
      VideoPlayerController controller;

      try {
        if (kIsWeb) {
          controller = VideoPlayerController.network((_videoFile as XFile).path);
        } else {
          controller = VideoPlayerController.file(File((_videoFile as XFile).path));
        }

        // Initialize and get duration
        await controller.initialize();
        _videoDuration = controller.value.duration.inSeconds.toDouble();
        controller.dispose();

        // Check if video is too long
        if (_videoDuration > _maxVideoDurationSeconds) {
          _apiError = "Video çok uzun. Maksimum süre: ${_maxVideoDurationSeconds ~/ 60} dakika";
          return false;
        }

        return true;
      } catch (e) {
        print("Error initializing video player: $e");
        // If video player initialization fails, we'll still accept the video
        // This allows non-MP4 videos to be processed
        return true;
      }
    } catch (e) {
      _apiError = "Video doğrulanırken hata oluştu: $e";
      print("Video validation error: $e");
      return false;
    }
  }

  // Preprocess video if needed (reduce size, quality, etc.)
  Future<bool> preprocessVideo() async {
    if (_videoFile == null) return false;

    // Skip on web platform, as FFmpeg is not available
    if (kIsWeb) {
      _processedVideoFile = _videoFile;
      return true;
    }

    try {
      _isProcessing = true;
      _preprocessingProgress = 0.0;
      notifyListeners();

      // Get temporary directory to save processed video
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/processed_video.mp4';

      // Original video path
      final inputPath = (_videoFile as XFile).path;

      // Determine if video needs processing
      final originalFile = File(inputPath);
      final fileSizeMB = await originalFile.length() / (1024 * 1024);

      if (fileSizeMB <= 10 && _videoDuration <= 60) {
        // Small video, no need to process
        _processedVideoFile = _videoFile;
        _isProcessing = false;
        _preprocessingProgress = 1.0;
        notifyListeners();
        return true;
      }

      // Use FFmpeg to preprocess the video (lower resolution, bitrate)
      // Let's target 720p with moderate bitrate
      String ffmpegCommand;

      if (_videoDuration > 120) {
        // For very long videos, more aggressive compression
        ffmpegCommand = '-i $inputPath -vf "scale=640:360" -c:v libx264 -preset faster -crf 28 -c:a aac -b:a 96k $outputPath';
      } else {
        // For medium length videos, moderate compression
        ffmpegCommand = '-i $inputPath -vf "scale=1280:720" -c:v libx264 -preset faster -crf 23 -c:a aac -b:a 128k $outputPath';
      }

      // Start progress simulation for UI feedback
      _startPreprocessingSimulation();

      // Execute FFmpeg command
      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Processing successful
        _processedVideoFile = XFile(outputPath);
        _preprocessingProgress = 1.0;
        print("Video processing completed: ${outputPath}");
        return true;
      } else {
        // Processing failed, use original video
        _apiError = "Video işleme hatası, orijinal video kullanılacak.";
        _processedVideoFile = _videoFile;
        print("FFmpeg processing error: ${await session.getOutput()}");
        return true; // Still return true to continue with analysis
      }
    } catch (e) {
      _apiError = "Video işlenirken hata: $e";
      _processedVideoFile = _videoFile; // Use original as fallback
      print("Video preprocessing error: $e");
      return true; // Still return true to continue with analysis
    } finally {
      _isProcessing = false;
      _preprocessingProgress = 1.0;
      notifyListeners();
    }
  }

  // Simulate preprocessing progress for UI
  Timer? _preprocessingTimer;

  void _startPreprocessingSimulation() {
    _preprocessingTimer?.cancel();
    _preprocessingProgress = 0.0;

    _preprocessingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_preprocessingProgress < 0.95) {
        _preprocessingProgress += (0.95 - _preprocessingProgress) * 0.01;
        notifyListeners();
      } else if (!_isProcessing) {
        _preprocessingProgress = 1.0;
        timer.cancel();
        notifyListeners();
      }
    });
  }

  // Reset state
  void reset() {
    _progressTimer?.cancel();
    _preprocessingTimer?.cancel();
    _isAnalyzing = false;
    _isVideoUploaded = false;
    _isProcessing = false;
    _exerciseSegments = [];
    _videoInfo = {};
    _processingInfo = {};
    _apiError = "";
    _analysisProgress = 0.0;
    _preprocessingProgress = 0.0;
    _videoFile = null;
    _processedVideoFile = null;
    _primaryExercise = "";
    _totalDuration = 0;
    _exerciseCount = 0;
    _videoDuration = 0.0;
    _analysisResults = null;
    notifyListeners();
  }

  // Method to analyze video with specified exercise type
  Future<Map<String, dynamic>?> analyzeVideoWithExerciseType(String exerciseType) async {
    if (_videoFile == null) {
      _apiError = 'Lütfen önce bir video yükleyin.';
      notifyListeners();
      return null;
    }

    // Preprocess video if needed
    final processingSuccess = await preprocessVideo();
    if (!processingSuccess) {
      _apiError = _apiError.isEmpty ? "Video işlenirken hata oluştu" : _apiError;
      notifyListeners();
      return null;
    }

    _isAnalyzing = true;
    _apiError = '';
    _analysisProgress = 0.0;
    _analysisResults = null;
    notifyListeners();

    // Show background processing notification
    await NotificationService().showBackgroundProcessingNotification();

    // Start background progress animation
    _startProgressSimulation();

    try {
      // Get the file to upload (processed or original)
      final videoFileForUpload = _processedVideoFile ?? _videoFile;
      final apiUrl = 'http://127.0.0.1:8000/analyze'; // Update with your actual API URL

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add exercise type parameter
      request.fields['exercise_class'] = exerciseType;

      // Add video file
      if (kIsWeb) {
        // Web platform
        final bytes = await (videoFileForUpload as XFile).readAsBytes();
        request.files.add(
            http.MultipartFile.fromBytes(
              'video',
              bytes,
              filename: 'video.mp4',
            )
        );
      } else {
        // Mobile platforms
        final videoFilePath = (videoFileForUpload as XFile).path;
        request.files.add(
          await http.MultipartFile.fromPath(
            'video',
            videoFilePath,
          ),
        );
      }

      // Send request with extended timeout
      final response = await request.send().timeout(
        _connectionTimeout,
        onTimeout: () {
          throw Exception('İşlem zaman aşımına uğradı. Lütfen daha kısa bir video yükleyin veya ağ bağlantınızı kontrol edin.');
        },
      );

      // Read response
      final responseData = await response.stream.toBytes();
      final responseString = utf8.decode(responseData);

      print("API Response: $responseString"); // Debug için

      // Check response
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);

        // API'den gelen verileri kontrol edelim
        print("Parsed JSON: $jsonResponse");

        _analysisResults = Map<String, dynamic>.from(jsonResponse);

        // Sonuçları temizle ve kontrol et
        if (_analysisResults != null && _analysisResults!.isNotEmpty) {
          // Show completion notification
          await NotificationService().showCompletedNotification();

          print("Analysis results set: $_analysisResults"); // Debug için

          return _analysisResults;
        } else {
          throw Exception('API boş sonuç döndü');
        }
      } else {
        throw Exception('API error: ${response.statusCode} - $responseString');
      }
    } catch (e) {
      _apiError = 'Video analiz hatası: $e';
      print("Analysis error: $e");
      _analysisResults = null;
      return null;
    } finally {
      _isAnalyzing = false;
      _analysisProgress = 1.0;
      _progressTimer?.cancel();
      notifyListeners(); // Bu çok önemli - UI'yı günceller
    }
  }

  // Simulate progress for UX purposes
  Timer? _progressTimer;

  void _startProgressSimulation() {
    _progressTimer?.cancel();
    _analysisProgress = 0.0;

    // Simulate incremental progress to provide visual feedback
    _progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_analysisProgress < 0.95) {
        // Gradually increase progress but never reach 100% until actually complete
        _analysisProgress += (0.95 - _analysisProgress) * 0.01;
        notifyListeners();
      } else if (!_isAnalyzing) {
        // Analysis is complete
        _analysisProgress = 1.0;
        timer.cancel();
        notifyListeners();
      }
    });
  }

  // Calculate workout statistics from exercise segments
  void _calculateWorkoutStats() {
    if (_exerciseSegments.isEmpty) return;

    // Count exercises
    _exerciseCount = _exerciseSegments.length;

    // Calculate total duration
    _totalDuration = _exerciseSegments.fold(0, (sum, segment) => sum + (segment['duration'] as num));

    // Find primary exercise (most performed)
    final exerciseCounts = <String, int>{};
    for (var segment in _exerciseSegments) {
      final exercise = segment['exercise'] as String;
      exerciseCounts[exercise] = (exerciseCounts[exercise] ?? 0) + 1;
    }

    String mostFrequent = "";
    int highestCount = 0;

    exerciseCounts.forEach((exercise, count) {
      if (count > highestCount) {
        mostFrequent = exercise;
        highestCount = count;
      }
    });

    _primaryExercise = mostFrequent;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _preprocessingTimer?.cancel();
    super.dispose();
  }
}