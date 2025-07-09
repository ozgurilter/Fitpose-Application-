
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_tracking_app/notificationService.dart';
import 'package:fitness_tracking_app/BottomBar/exercise/exerciseAnalysisService.dart';
import 'package:fitness_tracking_app/provider/analysisFlowProvider.dart';
import 'package:fitness_tracking_app/realTimeAnalysisPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:fitness_tracking_app/models/userModel.dart';

class VideoAnalysisPage extends StatefulWidget {
  final UserModel currentUser;
  final String selectedExercise;
  final String exerciseDisplayName;
  final VoidCallback? onNewAnalysis; // Yeni analiz başlatmak için callback

  const VideoAnalysisPage({
    Key? key,
    required this.currentUser,
    required this.selectedExercise,
    required this.exerciseDisplayName,
    this.onNewAnalysis,
  }) : super(key: key);

  @override
  State<VideoAnalysisPage> createState() => _VideoAnalysisPageState();
}

class _VideoAnalysisPageState extends State<VideoAnalysisPage> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  VideoPlayerController? _resultVideoController;

  double _videoDuration = 0.0;
  bool _isLongVideo = false;
  bool _isResultVideoLoading = false;
  bool _analysisCompleted = false;

  // Video control states
  bool _showControls = true;
  bool _showResultControls = true;
  Timer? _controlsTimer;
  Timer? _resultControlsTimer;

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideoIfNeeded();
      _initializeResultVideoIfNeeded();

      // AnalysisFlowProvider'a analiz başladığını bildir
      final provider = Provider.of<AnalysisFlowProvider>(context, listen: false);
      provider.startAnalysis();
    });
  }

  void _initializeVideoIfNeeded() {
    try {
      final analysisService = Provider.of<ExerciseAnalysisService>(context, listen: false);
      if (analysisService.isVideoUploaded && analysisService.videoFile != null) {
        _initVideoController(analysisService.videoFile);
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _initializeResultVideoIfNeeded() {
    final analysisService = Provider.of<ExerciseAnalysisService>(context, listen: false);
    if (analysisService.analysisResults != null &&
        analysisService.analysisResults!.containsKey('video_url')) {
      final videoUrl = analysisService.analysisResults!['video_url'];
      if (videoUrl != null && videoUrl.toString().isNotEmpty) {
        _initResultVideoController(videoUrl.toString());
      }
    }
  }

  Future<void> _initVideoController(dynamic videoFile) async {
    if (_videoController != null) {
      await _videoController!.dispose();
    }

    try {
      if (kIsWeb) {
        _videoController = VideoPlayerController.network((videoFile as XFile).path);
      } else {
        _videoController = VideoPlayerController.file(File((videoFile as XFile).path));
      }

      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _videoDuration = _videoController!.value.duration.inSeconds.toDouble();
          _isLongVideo = _videoDuration > 120;
        });

        // Video state değişikliklerini dinle
        _videoController!.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
      }
    } catch (e) {
      print('Error initializing video controller: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initResultVideoController(String videoUrl) async {
    if (_resultVideoController != null) {
      await _resultVideoController!.dispose();
    }

    print('Initializing result video controller with URL: $videoUrl');

    try {
      setState(() {
        _isResultVideoLoading = true;
      });

      _resultVideoController = VideoPlayerController.network(videoUrl);
      await _resultVideoController!.initialize();

      if (mounted) {
        setState(() {
          _isResultVideoLoading = false;
        });

        // Result video state değişikliklerini dinle
        _resultVideoController!.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });

        print('Result video controller initialized successfully');
      }
    } catch (e) {
      print('Error initializing result video controller: $e');
      if (mounted) {
        setState(() {
          _isResultVideoLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz videosu yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _toggleResultControls() {
    setState(() {
      _showResultControls = !_showResultControls;
    });

    if (_showResultControls) {
      _startResultControlsTimer();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(Duration(seconds: 3), () {
      if (mounted && _videoController != null && _videoController!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _startResultControlsTimer() {
    _resultControlsTimer?.cancel();
    _resultControlsTimer = Timer(Duration(seconds: 3), () {
      if (mounted && _resultVideoController != null && _resultVideoController!.value.isPlaying) {
        setState(() {
          _showResultControls = false;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _resultControlsTimer?.cancel();

    if (_videoController != null) {
      _videoController!.dispose();
    }
    if (_resultVideoController != null) {
      _resultVideoController!.dispose();
    }
    _notificationService.cancelAllNotifications();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video == null) return;

      final analysisService = Provider.of<ExerciseAnalysisService>(context, listen: false);
      final isValid = await analysisService.setVideoFile(video);

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(analysisService.apiError),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _initVideoController(video);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video seçerken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startAnalysis() async {
    final analysisService = Provider.of<ExerciseAnalysisService>(context, listen: false);
    final analysisFlowProvider = Provider.of<AnalysisFlowProvider>(context, listen: false);

    try {
      await _notificationService.showBackgroundProcessingNotification();
      final results = await analysisService.analyzeVideoWithExerciseType(widget.selectedExercise);
      await _notificationService.cancelAllNotifications();
      await _notificationService.showCompletedNotification();

      if (analysisService.apiError.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz sırasında hata: ${analysisService.apiError}'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (results == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Videoda egzersiz hareketi analiz edilemedi.'),
            backgroundColor: Color(0xFFFF7D33),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analiz başarıyla tamamlandı.'),
            backgroundColor: Colors.green,
          ),
        );

        // Analiz tamamlandı
        setState(() {
          _analysisCompleted = true;
        });

        // AnalysisFlowProvider'a analiz tamamlandığını bildir
        analysisFlowProvider.completeAnalysis();

        // Result video'yu initialize et
        if (results.containsKey('video_url')) {
          final videoUrl = results['video_url'];
          if (videoUrl != null && videoUrl.toString().isNotEmpty) {
            await _initResultVideoController(videoUrl.toString());
          }
        }
      }
    } catch (e) {
      await _notificationService.cancelAllNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analiz sırasında beklenmeyen hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveResults() async {
    final analysisService = Provider.of<ExerciseAnalysisService>(context, listen: false);
    final analysisResults = analysisService.analysisResults;

    if (analysisResults == null) return;

    try {
      final timestamp = DateTime.now();
      final analysisId = 'analysis_${timestamp.millisecondsSinceEpoch}';

      String exerciseName = analysisResults['exercise_name'] ?? widget.exerciseDisplayName ?? 'Bilinmeyen Egzersiz';
      String bodyRegion = _determineBodyRegion(exerciseName);


      final analysisData = {
        'timestamp': timestamp,
        'exerciseName': exerciseName,
        'bodyRegion': bodyRegion,
        'repCount': analysisResults['rep_count'] ?? 0,
        'durationSeconds': analysisResults['duration_sec'] ?? 0.0,
        'accuracyPercent': analysisResults['accuracy_percent'] ?? 0.0,
        'videoUrl': analysisResults['video_url'] ?? '',
      };

      final userAnalysisRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.userId)
          .collection('analysisResults')
          .doc(analysisId);

      await userAnalysisRef.set(analysisData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Egzersiz analizi profilinize kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analiz sonuçları kaydedilemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  String _determineBodyRegion(String exerciseName) {
    // Exact match for exercise names from ExerciseSelectionPage
    switch (exerciseName.toLowerCase()) {
    // Bacak egzersizleri
      case 'squat':
        return 'Bacaklar';
      case 'lunge':
        return 'Bacaklar';
      case 'wall sit':
      case 'wall_sit':
        return 'Bacaklar';

    // Göğüs egzersizleri
      case 'push up':
      case 'pushup':
        return 'Göğüs';

    // Kol egzersizleri
      case 'barbell curl':
      case 'barbell_curl':
        return 'Kollar';
      case 'hammer curl':
      case 'hammer_curl':
        return 'Kollar';

    // Omuz egzersizleri
      case 'shoulder press':
      case 'shoulder_press':
        return 'Omuzlar';
      case 'lateral raise':
      case 'lateral_raise':
        return 'Omuzlar';

    // Sırt egzersizleri
      case 'romanian deadlift':
      case 'romanian_deadlift':
        return 'Sırt';

    // Karın egzersizleri
      case 'situp':
      case 'sit up':
        return 'Karın';

    // Egzersiz adı tanımlanmadıysa (varsayılan olarak 'Diğer')
      default:
        return 'Diğer';
    }
  }


  // Yeni analiz başlat
  void _startNewAnalysis() {

    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
    }
    if (_resultVideoController != null) {
      _resultVideoController!.dispose();
      _resultVideoController!.dispose();
      _resultVideoController = null;
    }
    // Analiz verilerini temizle
    final analysisService = Provider.of<ExerciseAnalysisService>(context, listen: false);
    analysisService.reset();

    // Callback aracılığıyla egzersiz seçim sayfasına dön
    if (widget.onNewAnalysis != null) {
      widget.onNewAnalysis!();
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy < 60) return Color(0xFFE74C3C);
    else if (accuracy < 75) return Color(0xFFFF7D33);
    else if (accuracy < 90) return Color(0xFFF39C12);
    else return Color(0xFF00B894);
  }

  String _getPerformanceFeedback(double accuracy) {
    if (accuracy < 60) {
      return "Form geliştirmeye ihtiyacınız var. Hareketi doğru şekilde yapmak için teknik detaylara dikkat edin.";
    } else if (accuracy < 75) {
      return "Ortalama bir performans gösterdiniz. Birkaç teknik düzeltme ile formunuzu geliştirebilirsiniz.";
    } else if (accuracy < 90) {
      return "İyi bir performans! Küçük ince ayarlar ile mükemmel forma ulaşabilirsiniz.";
    } else {
      return "Mükemmel form! Hareketi doğru teknikle gerçekleştiriyorsunuz. Bu şekilde devam edin.";
    }
  }

  Widget _buildVideoControls(VideoPlayerController controller, bool showControls) {
    if (!controller.value.isInitialized) return SizedBox.shrink();

    final position = controller.value.position;
    final duration = controller.value.duration;
    final isPlaying = controller.value.isPlaying;

    return AnimatedOpacity(
      opacity: showControls ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Progress bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: Color(0xFF5046E5),
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: Color(0xFF5046E5),
                        overlayColor: Color(0xFF5046E5).withOpacity(0.3),
                      ),
                      child: Slider(
                        value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          controller.seekTo(Duration(milliseconds: value.toInt()));
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Control buttons
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Geri 10 saniye
                  IconButton(
                    onPressed: () {
                      final newPosition = position - Duration(seconds: 10);
                      controller.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                    },
                    icon: Icon(Icons.replay_10, color: Colors.white, size: 28),
                  ),
                  SizedBox(width: 20),
                  // Play/Pause
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF5046E5).withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF5046E5).withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          isPlaying ? controller.pause() : controller.play();
                        });
                      },
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  // İleri 10 saniye
                  IconButton(
                    onPressed: () {
                      final newPosition = position + Duration(seconds: 10);
                      controller.seekTo(newPosition > duration ? duration : newPosition);
                    },
                    icon: Icon(Icons.forward_10, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF5046E5)),
          onPressed: () {
            // Analiz verilerini temizle
            final analysisService = Provider.of<ExerciseAnalysisService>(context, listen: false);
            analysisService.reset();

            // Egzersiz seçim sayfasına dön
            if (widget.onNewAnalysis != null) {
              widget.onNewAnalysis!();
            }
          },
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFEBEEFF),
              child: Text(
                widget.currentUser.nameSurname.isNotEmpty
                    ? widget.currentUser.nameSurname[0].toUpperCase()
                    : "U",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5046E5),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 80),
        child: _buildVideoUploadView(),
      ),
    );
  }

  void _startRealTimeAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RealTimeAnalysisPage(
          currentUser: widget.currentUser,
          selectedExercise: widget.selectedExercise,
          exerciseDisplayName: widget.exerciseDisplayName,
          onBack: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildVideoUploadView() {
    return Consumer<ExerciseAnalysisService>(
      builder: (context, analysisService, child) {
        final bool isAnalyzing = analysisService.isAnalyzing;
        final bool isProcessing = analysisService.isProcessing;
        final double progress = analysisService.analysisProgress;
        final bool canAnalyze = analysisService.isVideoUploaded && !isAnalyzing && !isProcessing && !_analysisCompleted;
        final analysisResults = analysisService.analysisResults;
        final bool hasResults = analysisResults != null && analysisResults.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Video Analizi",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Seçilen egzersiz: ${widget.exerciseDisplayName}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9aa0a6),
                    ),
                  ),
                ],
              ),
            ),

            // Video viewer - Kontroller ile
            if (_videoController != null && _videoController!.value.isInitialized)
              Container(
                margin: EdgeInsets.all(16),
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () {
                      _toggleControls();
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        _buildVideoControls(_videoController!, _showControls),
                      ],
                    ),
                  ),
                ),
              )
            else if (!hasResults)
              Container(
                margin: EdgeInsets.all(16),
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 48,
                        color: Color(0xFF9aa0a6),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Analiz için video yükleyin",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF9aa0a6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Video warnings
            if (_isLongVideo && _videoController != null && _videoController!.value.isInitialized && !hasResults)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFF7D33).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFFF7D33).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFFF7D33), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Bu video ${(_videoDuration / 60).toStringAsFixed(1)} dakika uzunluğunda. Analiz işlemi zaman alabilir.",
                        style: TextStyle(fontSize: 14, color: Color(0xFFFF7D33)),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            // Video upload button - Sadece analiz tamamlanmadıysa göster
            // Video upload button - Sadece analiz tamamlanmadıysa göster kısmını değiştir
            if (!hasResults)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(  // SizedBox yerine Row kullan
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (isAnalyzing || isProcessing) ? null : _pickVideo,
                        icon: Icon(Icons.photo_library),
                        label: Text("Galeriden Seç"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5046E5),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),  // Butonlar arasında boşluk

                  ],
                ),
              ),// Video upload button - Sadece analiz tamamlanmadıysa göster kısmını değiştir

            // Analyze button - Sadece analiz tamamlanmadıysa göster
            if (!hasResults)
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAnalyze ? _startAnalysis : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5046E5),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: isProcessing
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Video Hazırlanıyor...",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                        : isAnalyzing
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Analiz Ediliyor...",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                        : Text(
                      "Egzersizi Analiz Et",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

            // Progress indicator
            if (isAnalyzing || isProcessing)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProcessing ? "Video hazırlanıyor..." : "Hareketler analiz ediliyor...",
                      style: TextStyle(color: Color(0xFF9aa0a6), fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5046E5)),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),

            // Error message
            if (analysisService.apiError.isNotEmpty)
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        analysisService.apiError,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),

            // Analysis results
            if (hasResults)
              _buildAnalysisResults(analysisResults),

            // Yeni Analiz Butonu - Sadece analiz sonuçları varsa göster
            if (hasResults)
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startNewAnalysis,
                    icon: Icon(Icons.add_circle_outline),
                    label: Text("Yeni Analiz Başlat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5046E5),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnalysisResults(Map<String, dynamic> analysisResults) {
    // Güvenli veri çekme
    final double accuracy = (analysisResults['accuracy_percent'] ?? 0.0).toDouble();
    final int repCount = (analysisResults['rep_count'] ?? 0).toInt();
    final double duration = (analysisResults['duration_sec'] ?? 0.0).toDouble();
    final String exerciseName = analysisResults['exercise_name'] ?? 'Bilinmeyen Egzersiz';
    final String videoUrl = analysisResults['video_url'] ?? '';

    final Color primaryColor = Color(0xFF5046E5);
    final Color accentColor = _getAccuracyColor(accuracy);

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Analiz Tamamlandı",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        exerciseName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Result Video Section - Kontroller ile
                if (videoUrl.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 24),
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _isResultVideoLoading
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: primaryColor),
                            SizedBox(height: 16),
                            Text(
                              "Analiz videosu yükleniyor...",
                              style: TextStyle(color: Color(0xFF9aa0a6), fontSize: 16),
                            ),
                          ],
                        ),
                      )
                          : (_resultVideoController != null && _resultVideoController!.value.isInitialized)
                          ? GestureDetector(
                        onTap: () {
                          _toggleResultControls();
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: _resultVideoController!.value.aspectRatio,
                              child: VideoPlayer(_resultVideoController!),
                            ),
                            _buildVideoControls(_resultVideoController!, _showResultControls),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: AnimatedOpacity(
                                opacity: _showResultControls ? 1.0 : 0.7,
                                duration: Duration(milliseconds: 300),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.smart_display_rounded, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        "Analiz Sonucu",
                                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Color(0xFF9aa0a6), size: 48),
                            SizedBox(height: 16),
                            Text(
                              "Video yüklenemedi",
                              style: TextStyle(color: Color(0xFF9aa0a6), fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                if (videoUrl.isNotEmpty) {
                                  _initResultVideoController(videoUrl);
                                }
                              },
                              child: Text("Tekrar dene", style: TextStyle(color: primaryColor)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Stats Row - Sadece Accuracy ve Rep Count
                Row(
                  children: [
                    // Accuracy
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentColor.withOpacity(0.15), accentColor.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accentColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: CircularProgressIndicator(
                                    value: accuracy / 100,
                                    strokeWidth: 14,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "${accuracy.toStringAsFixed(1)}%",
                                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accentColor),
                                    ),
                                    Text(
                                      "Doğruluk",
                                      style: TextStyle(fontSize: 14, color: Color(0xFF9aa0a6), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 16),

                    // Rep Count
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor.withOpacity(0.15), primaryColor.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor.withOpacity(0.4), width: 4),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "$repCount",
                                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: primaryColor),
                                    ),
                                    Text(
                                      "Tekrar",
                                      style: TextStyle(fontSize: 14, color: Color(0xFF9aa0a6), fontWeight: FontWeight.w600),
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

                SizedBox(height: 24),

                // Duration Info - Tek kart olarak
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF7D33).withOpacity(0.15), Color(0xFFFF7D33).withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFFF7D33).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF7D33).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.timer_outlined, color: Color(0xFFFF7D33), size: 32),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Toplam Egzersiz Süresi",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF9aa0a6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${duration.toStringAsFixed(1)} saniye",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF7D33),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Feedback Section - Daha güzel tasarım
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.08), primaryColor.withOpacity(0.03)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.psychology_rounded, color: primaryColor, size: 24),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "Performans Değerlendirmesi",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getPerformanceFeedback(accuracy),
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Action Buttons - Daha güzel tasarım
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _saveResults,
                          icon: Icon(Icons.save_alt_rounded, size: 22),
                          label: Text(
                            "Sonuçları Kaydet",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }}