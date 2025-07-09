

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fitness_tracking_app/BottomBar/analiz/analysisDetailPage.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';

class AnalysisTimelineTab extends StatelessWidget {
  final UserModel currentUser;
  final DateTime? startDate;
  final DateTime? endDate;
  final NotchBottomBarController? bottomBarController;
  final PageController? pageController;

  // Renk paletleri
  final Color _primaryColor = Color(0xFF5046E5);
  final Color _greyTextColor = Color(0xFF9aa0a6);
  final Color _accentColor = Color(0xFFFF7D33);
  final Color _backgroundColor = Color(0xFFF8F9FA);

  // Egzersiz verileri
  final List<Map<String, dynamic>> availableExercises = [
    {
      'name': 'squat',
      'displayName': 'Squat',
      'icon': Icons.accessibility_new,
      'gradient': [Color(0xFF5046E5), Color(0xFF7B68FF)],
      'description': 'Alt vücut kuvvet antrenmanı'
    },
    {
      'name': 'pushup',
      'displayName': 'Push Up',
      'icon': Icons.fitness_center,
      'gradient': [Color(0xFFFF7D33), Color(0xFFFFB366)],
      'description': 'Göğüs ve kol geliştirme'
    },
    {
      'name': 'barbell_curl',
      'displayName': 'Barbell Curl',
      'icon': Icons.sports_gymnastics,
      'gradient': [Color(0xFF3CCFCF), Color(0xFF66E0E0)],
      'description': 'Biceps kuvvet antrenmanı'
    },
    {
      'name': 'hammer_curl',
      'displayName': 'Hammer Curl',
      'icon': Icons.sports_gymnastics,
      'gradient': [Color(0xFFE84393), Color(0xFFFF6FB5)],
      'description': 'Kol kas geliştirme'
    },
    {
      'name': 'shoulder_press',
      'displayName': 'Shoulder Press',
      'icon': Icons.accessibility_new,
      'gradient': [Color(0xFF00B894), Color(0xFF00E6B8)],
      'description': 'Omuz kuvvet antrenmanı'
    },
    {
      'name': 'lateral_raise',
      'displayName': 'Lateral Raise',
      'icon': Icons.accessibility_new,
      'gradient': [Color(0xFFFFD93D), Color(0xFFFFE66D)],
      'description': 'Omuz yan kas geliştirme'
    },
    {
      'name': 'romanian_deadlift',
      'displayName': 'Romanian Deadlift',
      'icon': Icons.accessibility_new,
      'gradient': [Color(0xFF6C5CE7), Color(0xFF8B7EFF)],
      'description': 'Sırt ve bacak kuvvet'
    },
    {
      'name': 'lunge',
      'displayName': 'Lunge',
      'icon': Icons.directions_walk,
      'gradient': [Color(0xFFFD79A8), Color(0xFFFF9FBB)],
      'description': 'Dinamik bacak antrenmanı'
    },
    {
      'name': 'wall_sit',
      'displayName': 'Wall Sit',
      'icon': Icons.airline_seat_recline_normal,
      'gradient': [Color(0xFF74B9FF), Color(0xFF94C7FF)],
      'description': 'Statik dayanıklılık'
    },
    {
      'name': 'situp',
      'displayName': 'Sit Up',
      'icon': Icons.airline_seat_flat,
      'gradient': [Color(0xFFA29BFE), Color(0xFFB8B1FF)],
      'description': 'Karın kas geliştirme'
    },
  ];

  AnalysisTimelineTab({
    Key? key,
    required this.currentUser,
    required this.startDate,
    required this.endDate,
    this.bottomBarController,
    this.pageController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColor,
      child: Column(
        children: [
          SizedBox(height: 8),
          Expanded(
            child: _buildAnalysisList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.userId)
          .collection('analysisResults')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Veriler yüklenirken hata oluştu'),
          );
        }

        final analysisDocs = snapshot.data?.docs ?? [];

        if (analysisDocs.isEmpty) {
          return _buildEmptyState(context);
        }

        final Map<String, List<DocumentSnapshot>> analysesByDate = {};
        for (var doc in analysisDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final dateKey = DateFormat('yyyy-MM-dd').format(timestamp);

          if (!analysesByDate.containsKey(dateKey)) {
            analysesByDate[dateKey] = [];
          }
          analysesByDate[dateKey]!.add(doc);
        }

        final sortedDates = analysesByDate.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 16),
          itemCount: sortedDates.length,
          itemBuilder: (context, dateIndex) {
            final dateKey = sortedDates[dateIndex];
            final date = DateFormat('yyyy-MM-dd').parse(dateKey);
            final dateStr = DateFormat('d MMM, yyyy').format(date);
            final analyses = analysesByDate[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarih başlığı - tam genişlik
                Container(
                  margin: EdgeInsets.fromLTRB(16, 16, 16, 12),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD93D), Color(0xFFFFE66D)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFFD93D).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${analyses.length} antrenman',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Egzersiz listesi
                ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: analyses.length,
                  itemBuilder: (context, index) {
                    final doc = analyses[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = (data['timestamp'] as Timestamp).toDate();
                    final time = DateFormat('HH:mm').format(timestamp);
                    final exerciseName = data['exerciseName'] as String? ?? 'Bilinmeyen Egzersiz';
                    final repCount = data['repCount'] as int? ?? 0;
                    final durationSeconds = data['durationSeconds'] as double? ?? 0.0;
                    final accuracy = data['accuracyPercent'] as double? ?? 0.0;

                    return _buildAnalysisCard(
                      context: context,
                      time: time,
                      exerciseName: exerciseName,
                      repCount: repCount,
                      durationSeconds: durationSeconds,
                      accuracy: accuracy,
                      analysisId: doc.id,
                      data: data,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAnalysisCard({
    required BuildContext context,
    required String time,
    required String exerciseName,
    required int repCount,
    required double durationSeconds,
    required double accuracy,
    required String analysisId,
    required Map<String, dynamic> data,
  }) {
    final exerciseData = _getExerciseData(exerciseName);
    final gradient = exerciseData['gradient'] as List<Color>;
    final icon = exerciseData['icon'] as IconData;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: _AnimatedAnalysisCard(
        gradient: gradient,
        icon: icon,
        time: time,
        exerciseName: exerciseName,
        repCount: repCount,
        durationSeconds: durationSeconds,
        accuracy: accuracy,
        greyTextColor: _greyTextColor,
        primaryColor: _primaryColor,
        onTap: () => _navigateToAnalysisDetail(context, analysisId, data),
        getAccuracyColor: _getAccuracyColor,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            'Bu aralıkta egzersiz analizi bulunmuyor',
            style: TextStyle(
              color: _greyTextColor,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Egzersiz yapmak için Fitness bölümüne göz at',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (bottomBarController != null) {
                bottomBarController!.jumpTo(2);
              }
              if (pageController != null) {
                pageController!.jumpToPage(2);
              }
            },
            icon: Icon(Icons.fitness_center),
            label: Text('Fitness Sayfasına Git'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  void _navigateToAnalysisDetail(BuildContext context, String analysisId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisDetailPage(
          analysisId: analysisId,
          userId: currentUser.userId,
          initialData: data,
        ),
      ),
    );
  }

  Map<String, dynamic> _getExerciseData(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();

    for (var exercise in availableExercises) {
      if (lowerName.contains(exercise['name'].toLowerCase()) ||
          lowerName.contains(exercise['displayName'].toLowerCase())) {
        return exercise;
      }
    }

    // Varsayılan egzersiz verisi
    return {
      'name': 'default',
      'displayName': exerciseName,
      'icon': Icons.fitness_center,
      'gradient': [_primaryColor, _primaryColor.withOpacity(0.7)],
      'description': 'Genel egzersiz'
    };
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy < 60) {
      return Colors.red.shade500;
    } else if (accuracy < 75) {
      return _accentColor;
    } else if (accuracy < 90) {
      return Colors.green.shade500;
    } else {
      return Color(0xFF3CCFCF);
    }
  }
}

// Animasyonlu kart widget'ı
class _AnimatedAnalysisCard extends StatefulWidget {
  final List<Color> gradient;
  final IconData icon;
  final String time;
  final String exerciseName;
  final int repCount;
  final double durationSeconds;
  final double accuracy;
  final Color greyTextColor;
  final Color primaryColor;
  final VoidCallback onTap;
  final Color Function(double) getAccuracyColor;

  const _AnimatedAnalysisCard({
    Key? key,
    required this.gradient,
    required this.icon,
    required this.time,
    required this.exerciseName,
    required this.repCount,
    required this.durationSeconds,
    required this.accuracy,
    required this.greyTextColor,
    required this.primaryColor,
    required this.onTap,
    required this.getAccuracyColor,
  }) : super(key: key);

  @override
  _AnimatedAnalysisCardState createState() => _AnimatedAnalysisCardState();
}

class _AnimatedAnalysisCardState extends State<_AnimatedAnalysisCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0,
      end: 8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    setState(() {
      _isHovered = true;
    });
    _animationController.forward();
  }

  void _onHoverExit() {
    setState(() {
      _isHovered = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      child: GestureDetector(
        onTapDown: (_) => _onHoverEnter(),
        onTapUp: (_) => _onHoverExit(),
        onTapCancel: () => _onHoverExit(),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Card(
                elevation: _elevationAnimation.value,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isHovered
                            ? widget.gradient.first.withOpacity(0.3)
                            : Colors.grey.shade200,
                        width: _isHovered ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Sol taraf - renk çubuğu
                        Container(
                          width: 4,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.gradient,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // İkon
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isHovered ? [
                              BoxShadow(
                                color: widget.gradient.first.withOpacity(0.4),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ] : [],
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        // Orta kısım - egzersiz bilgileri
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.exerciseName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${widget.repCount} tekrar • ${widget.durationSeconds.toStringAsFixed(1)} sn',
                                style: TextStyle(
                                  color: widget.greyTextColor,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: widget.greyTextColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    widget.time,
                                    style: TextStyle(
                                      color: widget.greyTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Sağ taraf - doğruluk oranı ve buton
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.getAccuracyColor(widget.accuracy),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.accuracy < 60
                                        ? Icons.close
                                        : widget.accuracy < 75
                                        ? Icons.remove
                                        : Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${widget.accuracy.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: widget.primaryColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: _isHovered ? [
                                  BoxShadow(
                                    color: widget.primaryColor.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ] : [],
                              ),
                              child: Text(
                                'Detayları Gör',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }}