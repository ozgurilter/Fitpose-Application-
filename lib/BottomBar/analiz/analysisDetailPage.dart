import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

class AnalysisDetailPage extends StatefulWidget {
  final String analysisId;
  final String userId;
  final Map<String, dynamic> initialData;

  const AnalysisDetailPage({
    Key? key,
    required this.analysisId,
    required this.userId,
    required this.initialData,
  }) : super(key: key);

  @override
  _AnalysisDetailPageState createState() => _AnalysisDetailPageState();
}

class _AnalysisDetailPageState extends State<AnalysisDetailPage> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoLoading = false;
  bool _showControls = true;
  TabController? _tabController;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeVideo();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _videoController?.dispose();
    _controlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.initialData['videoUrl'] as String?;

    if (videoUrl == null || videoUrl.isEmpty) {
      return;
    }

    setState(() {
      _isVideoLoading = true;
    });

    try {
      _videoController = VideoPlayerController.network(videoUrl);
      await _videoController!.initialize();

      setState(() {
        _isVideoLoading = false;
      });

      // Video state değişikliklerini dinle
      _videoController!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      print('Error initializing video controller: $e');
      setState(() {
        _isVideoLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video yüklenirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
        _startControlsTimer();
      }
    });
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

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls && _videoController != null && _videoController!.value.isPlaying) {
      _startControlsTimer();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy < 60) return Color(0xFFE74C3C);
    else if (accuracy < 75) return Color(0xFFFF7D33);
    else if (accuracy < 90) return Color(0xFFF39C12);
    else return Color(0xFF00B894);
  }

  String _getPerformanceTitle(double accuracy) {
    if (accuracy < 60) {
      return "Geliştirilmesi Gereken Form";
    } else if (accuracy < 75) {
      return "Ortalama Performans";
    } else if (accuracy < 90) {
      return "İyi Performans";
    } else {
      return "Mükemmel Form";
    }
  }

  String _getPerformanceFeedback(double accuracy, String exerciseName) {
    if (accuracy < 60) {
      return "Temel form düzeltmeleri gerekiyor. Hareketi doğru şekilde yapmak için teknik detaylara odaklanmalısınız.";
    } else if (accuracy < 75) {
      return "Teknik olarak doğru gidiyorsunuz ancak formu geliştirmek için bazı düzeltmeler yapabilirsiniz.";
    } else if (accuracy < 90) {
      return "Form oldukça iyi. Küçük ince ayarlar ile mükemmel forma ulaşabilirsiniz.";
    } else {
      return "Hareketi teknik olarak mükemmel yapıyorsunuz. Bu formu koruyarak ağırlık veya tekrar sayısını artırabilirsiniz.";
    }
  }

  Widget _buildImprovementTips(double accuracy, String exerciseName) {
    final tips = <String>[];
    final lowerExerciseName = exerciseName.toLowerCase();

    if (accuracy < 75) {
      // Düşük veya orta doğruluk için genel öneriler
      if (lowerExerciseName.contains('squat')) {
        tips.add("Dizlerinizin ayak parmaklarınızı geçmemesine dikkat edin.");
        tips.add("Sırtınızı dik tutun ve göğsünüzü öne çıkarın.");
        tips.add("Ağırlık dağılımının topukta olmasına özen gösterin.");
      } else if (lowerExerciseName.contains('push') || lowerExerciseName.contains('bench')) {
        tips.add("Dirseklerinizi vücudunuza doğru sıkın.");
        tips.add("Omuzlarınızı geriye ve aşağıya doğru çekin.");
        tips.add("Başınızı nötr pozisyonda tutun, boyun gerilmesini önleyin.");
      } else if (lowerExerciseName.contains('curl')) {
        tips.add("Hareket sırasında dirseklerinizi sabit tutun.");
        tips.add("Omuzlarınızı geriye ve aşağıya doğru çekin.");
        tips.add("Kontrolü kaybetmeden ağırlığı indirin, sarkıtmayın.");
      } else if (lowerExerciseName.contains('shoulder') || lowerExerciseName.contains('press') || lowerExerciseName.contains('raise')) {
        tips.add("Bel çukurunu arttırmamaya dikkat edin.");
        tips.add("Omuzları geriye ve aşağıya doğru çekin.");
        tips.add("Hareketi kontrollü ve yavaş yapın.");
      } else if (lowerExerciseName.contains('deadlift')) {
        tips.add("Sırtınızı düz tutun, bel çukurunu koruyun.");
        tips.add("Hareketi kalçalardan başlatın, dizlerinizle değil.");
        tips.add("Ağırlığı vücudunuza yakın tutun.");
      } else if (lowerExerciseName.contains('lunge')) {
        tips.add("Öndeki dizinizin ayak parmaklarınızı geçmemesine dikkat edin.");
        tips.add("Gövdenizi dik tutun, öne eğilmeyin.");
        tips.add("Adım boyunuzu uygun mesafede tutun, çok uzun veya çok kısa olmamalı.");
      } else if (lowerExerciseName.contains('sit') || lowerExerciseName.contains('crunch')) {
        tips.add("Boyun gerginliğini önlemek için çenenizi göğsünüze yakın tutun.");
        tips.add("Karın kaslarınızı sıkın ve her tekrarda nefes verin.");
        tips.add("Kaliteli tekrarlar için hızlı değil, kontrollü hareket edin.");
      }
    } else {
      // Yüksek doğruluk için ileri seviye öneriler
      if (lowerExerciseName.contains('squat')) {
        tips.add("Daha derin squat'lar için mobilite çalışmaları yapın.");
        tips.add("Tek bacak varyasyonlarını deneyerek dengeyi geliştirin.");
        tips.add("Patlamalı squat hareketleri ile güç geliştirebilirsiniz.");
      } else if (lowerExerciseName.contains('push') || lowerExerciseName.contains('bench')) {
        tips.add("Dar veya geniş tutuş varyasyonlarını deneyerek farklı kas gruplarını hedefleyin.");
        tips.add("Düşüş hızını yavaşlatarak kas aktivasyonunu artırın.");
        tips.add("Pliyometrik şınav varyasyonları ile patlayıcı gücü geliştirebilirsiniz.");
      } else if (lowerExerciseName.contains('curl')) {
        tips.add("Süper setler ekleyerek antrenmanı yoğunlaştırın.");
        tips.add("Negatif tekrarlar ekleyerek kas gelişimini hızlandırın.");
        tips.add("İzometrik duraksamalar ile kas dayanıklılığını artırın.");
      } else if (lowerExerciseName.contains('shoulder') || lowerExerciseName.contains('press') || lowerExerciseName.contains('raise')) {
        tips.add("Farklı açılardan omuz egzersizleri yaparak tam gelişim sağlayın.");
        tips.add("Drop set tekniği ile kas dayanıklılığını geliştirin.");
        tips.add("Tek kol varyasyonları ile dengesizlikleri düzeltin.");
      } else if (lowerExerciseName.contains('deadlift')) {
        tips.add("Sumo duruşu, konvansiyonel duruş gibi farklı varyasyonlar deneyin.");
        tips.add("Tek bacak deadlift ile dengeyi ve çekirdek gücünü geliştirin.");
        tips.add("Patlamalı (hızlı) deadlift ile güç üretimini artırın.");
      } else if (lowerExerciseName.contains('lunge')) {
        tips.add("Yürüyüş lunges, pliometrik lunges gibi varyasyonlar deneyin.");
        tips.add("Ağırlık ekleyerek zorluğu artırın.");
        tips.add("Çok yönlü lunges yaparak kalça mobilitesini geliştirin.");
      } else if (lowerExerciseName.contains('sit') || lowerExerciseName.contains('crunch')) {
        tips.add("Bacak kaldırma ve bisiklet crunch gibi zorlu varyasyonlar ekleyin.");
        tips.add("Plank çeşitlerini ekleyerek core stabilizasyonunu geliştirin.");
        tips.add("Rotasyonel hareketler ekleyerek oblik kasları da çalıştırın.");
      }
    }

    // Genel gelişim önerileri ekle
    if (tips.isEmpty) {
      tips.add("Düzenli antrenman programı ile devamlılık sağlayın.");
      tips.add("Doğru beslenme ile performansınızı destekleyin.");
      tips.add("Yeterli dinlenme ve toparlanma süresi bırakın.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips.map((tip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline,
                  color: Color(0xFF5046E5), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  tip,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = (widget.initialData['timestamp'] as Timestamp).toDate();
    final dateStr = DateFormat('d MMMM, yyyy - HH:mm').format(timestamp);
    final exerciseName = widget.initialData['exerciseName'] as String? ?? 'Bilinmeyen Egzersiz';
    final repCount = widget.initialData['repCount'] as int? ?? 0;
    final durationSeconds = widget.initialData['durationSeconds'] as double? ?? 0.0;
    final accuracy = widget.initialData['accuracyPercent'] as double? ?? 0.0;
    final bodyRegion = widget.initialData['bodyRegion'] as String? ?? 'Diğer';

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF5046E5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF5046E5),
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(
          'Egzersiz Analizi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: Color(0xFF5046E5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF5046E5),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Genel Bilgiler'),
              Tab(text: 'Form Analizi'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(exerciseName, repCount, durationSeconds, accuracy, dateStr, bodyRegion),
          _buildFormAnalysisTab(accuracy, exerciseName),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
      String exerciseName,
      int repCount,
      double duration,
      double accuracy,
      String dateStr,
      String bodyRegion) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and time banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Color(0xFFEBEEFF),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  size: 18,
                  color: Color(0xFF5046E5),
                ),
                SizedBox(width: 8),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5046E5),
                  ),
                ),
              ],
            ),
          ),

          // Video player
          _buildVideoPlayer(),

          // Exercise overview card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFF5046E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getExerciseIcon(exerciseName),
                        color: Color(0xFF5046E5),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exerciseName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getBodyRegionColor(bodyRegion).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              bodyRegion,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getBodyRegionColor(bodyRegion),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Exercise stats cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      title: "Tekrar Sayısı",
                      value: "$repCount",
                      icon: Icons.repeat,
                      color: Color(0xFF5046E5),
                    ),
                    _buildStatCard(
                      title: "Süre",
                      value: "${duration.toStringAsFixed(1)} sn",
                      icon: Icons.timer,
                      color: Color(0xFF3CCFCF),
                    ),
                    _buildStatCard(
                      title: "Doğruluk",
                      value: "${accuracy.toStringAsFixed(1)}%",
                      icon: Icons.analytics,
                      color: _getAccuracyColor(accuracy),
                    ),
                    _buildStatCard(
                      title: "Tempo",
                      value: "${(repCount / (duration / 60)).toStringAsFixed(1)}/dk",
                      icon: Icons.speed,
                      color: Color(0xFFFF7D33),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Performance feedback
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getAccuracyColor(accuracy).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getAccuracyColor(accuracy).withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        accuracy < 60 ? Icons.sentiment_dissatisfied :
                        accuracy < 75 ? Icons.sentiment_neutral :
                        accuracy < 90 ? Icons.sentiment_satisfied :
                        Icons.sentiment_very_satisfied,
                        color: _getAccuracyColor(accuracy),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPerformanceTitle(accuracy),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _getAccuracyColor(accuracy),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _getPerformanceFeedback(accuracy, exerciseName),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormAnalysisTab(double accuracy, String exerciseName) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Accuracy visualization
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Form Doğruluğu",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24),

                // Circular accuracy indicator
                Center(
                  child: Container(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: accuracy / 100,
                            strokeWidth: 15,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(_getAccuracyColor(accuracy)),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${accuracy.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: _getAccuracyColor(accuracy),
                              ),
                            ),
                            Text(
                              "Doğruluk",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Performance level
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      accuracy < 60 ? Icons.sentiment_dissatisfied :
                      accuracy < 75 ? Icons.sentiment_neutral :
                      accuracy < 90 ? Icons.sentiment_satisfied :
                      Icons.sentiment_very_satisfied,
                      color: _getAccuracyColor(accuracy),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _getPerformanceTitle(accuracy),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getAccuracyColor(accuracy),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Improvement tips
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Color(0xFFFF7D33)),
                    SizedBox(width: 8),
                    Text(
                      'Geliştirme Önerileri',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildImprovementTips(accuracy, exerciseName),
              ],
            ),
          ),

          // Common mistakes
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFE74C3C)),
                    SizedBox(width: 8),
                    Text(
                      'Dikkat Edilmesi Gerekenler',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildCommonMistakes(exerciseName),
              ],
            ),
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCommonMistakes(String exerciseName) {
    final mistakes = <String>[];
    final lowerExerciseName = exerciseName.toLowerCase();

    if (lowerExerciseName.contains('squat')) {
      mistakes.add("Dizlerin içe doğru kapanması (valgus)");
      mistakes.add("Topukların yerden kalkması");
      mistakes.add("Belin yuvarlaklaşması");
    } else if (lowerExerciseName.contains('push') || lowerExerciseName.contains('bench')) {
      mistakes.add("Dirseklerin aşırı açılması");
      mistakes.add("Omuzların öne doğru yuvarlanması");
      mistakes.add("Belin çok fazla kavisli olması");
    } else if (lowerExerciseName.contains('curl')) {
      mistakes.add("Dirseği hareket ettirerek momentum kullanmak");
      mistakes.add("Ağırlığı tam indirmemek");
      mistakes.add("Bileği bükmek");
    } else if (lowerExerciseName.contains('shoulder') || lowerExerciseName.contains('press') || lowerExerciseName.contains('raise')) {
      mistakes.add("Omurgayı aşırı kavislendirmek");
      mistakes.add("Boynu öne uzatmak");
      mistakes.add("Omuzları yukarı kaldırmak (trapezius kullanımı)");
    } else if (lowerExerciseName.contains('deadlift')) {
      mistakes.add("Sırtın yuvarlaklaşması");
      mistakes.add("Dizlerden önce kalçayı hareket ettirmek");
      mistakes.add("Ağırlığı vücuttan uzakta tutmak");
    } else if (lowerExerciseName.contains('lunge')) {
      mistakes.add("Öne eğilmek");
      mistakes.add("Arka dizi yere çarpmak");
      mistakes.add("Ön dizin ayak hizasını geçmesi");
    } else if (lowerExerciseName.contains('sit') || lowerExerciseName.contains('crunch')) {
      mistakes.add("Boynu zorlayarak başı öne çekmek");
      mistakes.add("Çok hızlı ve kontrolsüz hareket etmek");
      mistakes.add("Nefesi tutmak");
    } else {
      mistakes.add("Hareketin hızlı ve kontrolsüz yapılması");
      mistakes.add("Nefes alıp vermenin düzensiz olması");
      mistakes.add("Eklemlerin kilitlenmesi veya aşırı zorlanması");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mistakes.map((mistake) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline,
                  color: Color(0xFFE74C3C), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  mistake,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        height: 250,
        color: Colors.black,
        child: Center(
          child: _isVideoLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, color: Colors.white54, size: 48),
              SizedBox(height: 12),
              Text(
                'Video yüklenemedi',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        height: 250,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
            // Video controls
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top bar - Title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF5046E5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Analiz Videosu',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom bar - Controls
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Progress bar
                          Row(
                            children: [
                              Text(
                                _formatDuration(_videoController!.value.position),
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              SizedBox(width: 12),
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
                                    value: _videoController!.value.position.inMilliseconds.toDouble(),
                                    max: _videoController!.value.duration.inMilliseconds.toDouble(),
                                    onChanged: (value) {
                                      _videoController!.seekTo(Duration(milliseconds: value.toInt()));
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                _formatDuration(_videoController!.value.duration),
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // Playback controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Geri 10 saniye
                              IconButton(
                                onPressed: () {
                                  final position = _videoController!.value.position;
                                  final newPosition = position - Duration(seconds: 10);
                                  _videoController!.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
                                },
                                icon: Icon(Icons.replay_10, color: Colors.white, size: 28),
                              ),
                              SizedBox(width: 16),

                              // Play/Pause
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF5046E5),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF5046E5).withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: _toggleVideoPlayback,
                                  icon: Icon(
                                    _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),

                              // İleri 10 saniye
                              IconButton(
                                onPressed: () {
                                  final position = _videoController!.value.position;
                                  final newPosition = position + Duration(seconds: 10);
                                  final duration = _videoController!.value.duration;
                                  _videoController!.seekTo(newPosition > duration ? duration : newPosition);
                                },
                                icon: Icon(Icons.forward_10, color: Colors.white, size: 28),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Play indicator when controls are hidden
            if (!_showControls && !_videoController!.value.isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _toggleVideoPlayback,
                  icon: Icon(Icons.play_arrow, color: Colors.white, size: 50),
                  iconSize: 50,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getExerciseIcon(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();

    if (lowerName.contains('squat')) {
      return Icons.accessibility_new;
    } else if (lowerName.contains('push') || lowerName.contains('bench')) {
      return Icons.fitness_center;
    } else if (lowerName.contains('curl')) {
      return Icons.sports_gymnastics;
    } else if (lowerName.contains('shoulder') || lowerName.contains('press') || lowerName.contains('raise')) {
      return Icons.accessibility_new;
    } else if (lowerName.contains('deadlift')) {
      return Icons.accessibility_new;
    } else if (lowerName.contains('lunge')) {
      return Icons.directions_walk;
    } else if (lowerName.contains('wall sit')) {
      return Icons.airline_seat_recline_normal;
    } else if (lowerName.contains('sit') || lowerName.contains('crunch')) {
      return Icons.airline_seat_flat;
    } else {
      return Icons.fitness_center;
    }
  }

  Color _getBodyRegionColor(String region) {
    switch (region) {
      case 'Göğüs':
        return Color(0xFFE63946);
      case 'Sırt':
        return Color(0xFF457B9D);
      case 'Omuzlar':
        return Color(0xFFF4A261);
      case 'Kollar':
        return Color(0xFF2A9D8F);
      case 'Bacaklar':
        return Color(0xFF6A0DAD);
      case 'Karın':
        return Color(0xFFE76F51);
      default:
        return Color(0xFF5046E5);
    }
  }
}