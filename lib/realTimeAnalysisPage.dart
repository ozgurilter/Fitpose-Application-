import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:fitness_tracking_app/models/userModel.dart';

class RealTimeAnalysisPage extends StatefulWidget {
  final UserModel currentUser;
  final String selectedExercise;
  final String exerciseDisplayName;
  final VoidCallback? onBack;

  const RealTimeAnalysisPage({
    Key? key,
    required this.currentUser,
    required this.selectedExercise,
    required this.exerciseDisplayName,
    this.onBack,
  }) : super(key: key);

  @override
  State<RealTimeAnalysisPage> createState() => _RealTimeAnalysisPageState();
}

class _RealTimeAnalysisPageState extends State<RealTimeAnalysisPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isAnalyzing = false;
  Timer? _frameTimer;
  String _sessionId = '';
  bool _isProcessingFrame = false; // Frame işleme kontrolü

  // Real-time sonuçlar
  int _currentRepCount = 0;
  double _currentAccuracy = 0.0;
  String _currentFeedback = "Analizi başlatmak için play tuşuna basın";
  String _currentStage = "";

  // Pose overlay verileri
  List<dynamic> _posePoints = [];
  List<dynamic> _poseLines = [];
  List<dynamic> _exerciseLines = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        final frontCamera = _cameras!.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium, // Low -> Medium (daha iyi kalite)
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg, // JPEG format
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Kamera başlatma hatası: $e');
    }
  }

  void _startRealTimeAnalysis() {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentRepCount = 0;
      _currentAccuracy = 0.0;
      _currentFeedback = "Analiz başladı...";
      _posePoints = [];
      _poseLines = [];
      _exerciseLines = [];
    });

    // Frame gönderme aralığını 2 saniyeye çıkar (kasma önleme)
    _frameTimer = Timer.periodic(Duration(milliseconds: 2000), (timer) {
      if (!_isProcessingFrame) { // Önceki frame henüz işlenmediyse bekle
        _captureAndAnalyzeFrame();
      }
    });
  }

  void _stopRealTimeAnalysis() {
    _frameTimer?.cancel();
    setState(() {
      _isAnalyzing = false;
      _currentFeedback = "Analiz durduruldu";
      _posePoints = [];
      _poseLines = [];
      _exerciseLines = [];
      _isProcessingFrame = false;
    });
  }

  Future<void> _captureAndAnalyzeFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessingFrame) return;

    _isProcessingFrame = true;

    try {
      final XFile image = await _cameraController!.takePicture();
      await _sendFrameToBackend(image);
    } catch (e) {
      print('Frame yakalama hatası: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _sendFrameToBackend(XFile frame) async {
    try {
      var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://127.0.0.1:8000/analyze-frame')
      );

      request.fields['exercise_class'] = widget.selectedExercise;
      request.fields['session_id'] = _sessionId;

      final bytes = await frame.readAsBytes();
      request.files.add(
          http.MultipartFile.fromBytes(
            'frame',
            bytes,
            filename: 'frame.jpg',
          )
      );

      final response = await request.send().timeout(Duration(seconds: 5)); // Timeout artırıldı

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final jsonResponse = json.decode(utf8.decode(responseData));
        print('Backend response: $jsonResponse'); // Debug log
        _updateRealTimeResults(jsonResponse);
      } else {
        print('Backend error: ${response.statusCode}');
      }

    } catch (e) {
      print('Frame gönderme hatası: $e');
    }
  }

  void _updateRealTimeResults(Map<String, dynamic> results) {
    if (!mounted) return;

    print('Updating results: pose_points=${results['pose_points']?.length}, exercise_lines=${results['exercise_lines']?.length}');

    setState(() {
      _currentRepCount = results['rep_count'] ?? _currentRepCount;
      _currentAccuracy = (results['accuracy_percent'] ?? 0.0).toDouble();
      _currentFeedback = results['feedback'] ?? _currentFeedback;
      _currentStage = results['stage'] ?? _currentStage;

      // Pose overlay verilerini güncelle
      _posePoints = results['pose_points'] ?? [];
      _poseLines = results['pose_lines'] ?? [];
      _exerciseLines = results['exercise_lines'] ?? [];

      print('Updated UI: pose_points=${_posePoints.length}, exercise_lines=${_exerciseLines.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _stopRealTimeAnalysis();
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Canlı Analiz - ${widget.exerciseDisplayName}",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          // Debug info
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'P:${_posePoints.length} E:${_exerciseLines.length}',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: _buildCameraView(),
    );
  }

  Widget _buildCameraView() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(color: Color(0xFF5046E5)),
      );
    }

    return Stack(
      children: [
        // Kamera preview - tam ekran ama aspect ratio korunmuş
        Positioned.fill(
          child: Container(
            child: CameraPreview(_cameraController!),
          ),
        ),

        // Pose overlay - Kamera preview üzerine çiz
        Positioned.fill(
          child: CustomPaint(
            painter: PoseOverlayPainter(
              posePoints: _posePoints,
              poseLines: _poseLines,
              exerciseLines: _exerciseLines,
            ),
          ),
        ),

        // Mesafe uyarısı (üst ortada)
        Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "📏 Kameradan 1-2 metre uzakta durun ve tüm vücudunuz görünsün",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Real-time stats overlay - üst kısım
        Positioned(
          top: 150, // Mesafe uyarısının altına
          left: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Rep counter ve accuracy
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tekrar',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          '$_currentRepCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Doğruluk',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          '${_currentAccuracy.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _getAccuracyColor(_currentAccuracy),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (_currentStage.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    'Aşama: ${_currentStage}',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],

                SizedBox(height: 12),

                // Real-time feedback
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentFeedback,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Processing indicator
        if (_isProcessingFrame)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Analiz ediliyor...',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

        // Control buttons - alt kısım
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Start/Stop button
              Container(
                decoration: BoxDecoration(
                  color: _isAnalyzing ? Colors.red : Color(0xFF5046E5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isAnalyzing ? Colors.red : Color(0xFF5046E5)).withOpacity(0.4),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _isAnalyzing ? _stopRealTimeAnalysis : _startRealTimeAnalysis,
                  icon: Icon(
                    _isAnalyzing ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                  iconSize: 60,
                ),
              ),

              // Switch camera
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _switchCamera,
                  icon: Icon(Icons.flip_camera_ios, color: Colors.white),
                  iconSize: 50,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentCamera = _cameraController!.description;
    final newCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection != currentCamera.lensDirection,
      orElse: () => currentCamera,
    );

    await _cameraController!.dispose();

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();

    setState(() {});
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy < 60) return Color(0xFFE74C3C);
    else if (accuracy < 75) return Color(0xFFFF7D33);
    else if (accuracy < 90) return Color(0xFFF39C12);
    else return Color(0xFF00B894);
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }
}

// Basitleştirilmiş Pose Overlay Painter
class PoseOverlayPainter extends CustomPainter {
  final List<dynamic> posePoints;
  final List<dynamic> poseLines;
  final List<dynamic> exerciseLines;

  PoseOverlayPainter({
    required this.posePoints,
    required this.poseLines,
    required this.exerciseLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    print('🎨 PAINT CALLED - Canvas: ${size.width}x${size.height}');
    print('🎨 Data: ${posePoints.length} points, ${poseLines.length} skeleton lines, ${exerciseLines.length} exercise lines');

    // 1. Temel iskelet çizgileri (ince mavi)
    final skeletonPaint = Paint()
      ..color = Colors.lightBlue.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var line in poseLines) {
      try {
        final start = Offset(
          (line['start']['x'] as num).toDouble() * size.width,
          (line['start']['y'] as num).toDouble() * size.height,
        );
        final end = Offset(
          (line['end']['x'] as num).toDouble() * size.width,
          (line['end']['y'] as num).toDouble() * size.height,
        );

        canvas.drawLine(start, end, skeletonPaint);
        print('✅ Skeleton line: $start -> $end');
      } catch (e) {
        print('❌ Skeleton line error: $e');
      }
    }

    // 2. Egzersiz çizgileri (kalın, renkli) - ÖNEMLİ OLAN BUNLAR
    for (var line in exerciseLines) {
      try {
        Color lineColor = Colors.yellow;
        String colorName = line['color'] ?? 'yellow';

        switch (colorName.toLowerCase()) {
          case 'green':
            lineColor = Colors.green;
            break;
          case 'red':
            lineColor = Colors.red;
            break;
          case 'yellow':
            lineColor = Colors.yellow;
            break;
        }

        final exercisePaint = Paint()
          ..color = lineColor
          ..strokeWidth = 6.0 // Kalınlık artırıldı
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        final start = Offset(
          (line['start']['x'] as num).toDouble() * size.width,
          (line['start']['y'] as num).toDouble() * size.height,
        );
        final end = Offset(
          (line['end']['x'] as num).toDouble() * size.width,
          (line['end']['y'] as num).toDouble() * size.height,
        );

        canvas.drawLine(start, end, exercisePaint);
        print('✅ Exercise line: $start -> $end (${lineColor})');

      } catch (e) {
        print('❌ Exercise line error: $e');
      }
    }

    // 3. Önemli noktalar (dirsek, bilek vs.)
    for (var point in posePoints) {
      try {
        final center = Offset(
          (point['x'] as num).toDouble() * size.width,
          (point['y'] as num).toDouble() * size.height,
        );

        Color pointColor = Colors.white;
        double pointSize = 4;

        if (point['type'] == 'joint') {
          String colorName = point['color'] ?? 'white';
          switch (colorName.toLowerCase()) {
            case 'green':
              pointColor = Colors.green;
              break;
            case 'red':
              pointColor = Colors.red;
              break;
            case 'yellow':
              pointColor = Colors.yellow;
              break;
            default:
              pointColor = Colors.white;
          }
          pointSize = 10.0; // Büyük eklem noktaları
        }

        final pointPaint = Paint()
          ..color = pointColor
          ..style = PaintingStyle.fill;

        final borderPaint = Paint()
          ..color = Colors.black.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(center, pointSize + 2, borderPaint);
        canvas.drawCircle(center, pointSize, pointPaint);

        if (point['type'] == 'joint') {
          print('✅ Joint point: $center (${pointColor})');
        }

      } catch (e) {
        print('❌ Point error: $e');
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}