import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';

class AnalysisStatisticsTab extends StatefulWidget {
  final UserModel currentUser;
  final DateTime? startDate;
  final DateTime? endDate;

  const AnalysisStatisticsTab({
    Key? key,
    required this.currentUser,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  State<AnalysisStatisticsTab> createState() => _AnalysisStatisticsTabState();
}

class _AnalysisStatisticsTabState extends State<AnalysisStatisticsTab> {
  String _selectedBodyRegion = 'Tüm Bölgeler';

  // Renk paletleri
  final Color _primaryColor = Color(0xFF5046E5);
  final Color _backgroundColor = Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;
  final Color _greyTextColor = Color(0xFF9aa0a6);
  final Color _accentColor = Color(0xFFFF7D33);

  final List<String> _bodyRegionOptions = [
    'Tüm Bölgeler',
    'Göğüs',
    'Sırt',
    'Omuzlar',
    'Kollar',
    'Bacaklar',
    'Karın'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBodyRegionFilter(),
          SizedBox(height: 8),
          _buildAnalysisSummary(),
          SizedBox(height: 16),
          _buildPerformanceByRegion(),
          SizedBox(height: 16),
          _buildMostPerformedExercises(),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBodyRegionFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _bodyRegionOptions.map((region) {
          final isSelected = _selectedBodyRegion == region;
          return ChoiceChip(
            label: Text(region),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedBodyRegion = selected ? region : 'Tüm Bölgeler';
              });
            },
            selectedColor: _primaryColor.withOpacity(0.1),
            labelStyle: TextStyle(
              color: isSelected ? _primaryColor : _greyTextColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            backgroundColor: _cardColor,
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected ? _primaryColor : Colors.grey.shade300,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnalysisSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.userId)
          .collection('analysisResults')
          .where('timestamp', isGreaterThanOrEqualTo: widget.startDate)
          .where('timestamp', isLessThanOrEqualTo: widget.endDate)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(220);
        }

        if (snapshot.hasError) {
          return Container(
            height: 220,
            child: Center(
              child: Text('Veri yüklenirken hata oluştu'),
            ),
          );
        }

        final analysisDocs = snapshot.data?.docs ?? [];

        if (analysisDocs.isEmpty) {
          return _buildEmptyStateCard(
            height: 220,
            icon: Icons.analytics_outlined,
            message: 'Bu tarih aralığında analiz bulunmamakta',
          );
        }

        // Seçilen bölgeye göre filtreleme
        final filteredDocs = _selectedBodyRegion == 'Tüm Bölgeler'
            ? analysisDocs
            : analysisDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['bodyRegion'] as String?) == _selectedBodyRegion;
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyStateCard(
            height: 220,
            icon: Icons.filter_alt_outlined,
            message: '$_selectedBodyRegion bölgesinde analiz bulunmamakta',
          );
        }

        final accuracyData = <DateTime, double>{};
        for (var doc in filteredDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final accuracy = data['accuracyPercent'] as double? ?? 0.0;
          accuracyData[timestamp] = accuracy;
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: _primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Performans Grafiği',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Spacer(),
                    _buildAverageAccuracy(accuracyData),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  height: 160,
                  child: _buildPerformanceChart(accuracyData),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceByRegion() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.userId)
          .collection('analysisResults')
          .where('timestamp', isGreaterThanOrEqualTo: widget.startDate)
          .where('timestamp', isLessThanOrEqualTo: widget.endDate)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(300);
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Veri yüklenirken hata oluştu'),
          );
        }

        final analysisDocs = snapshot.data?.docs ?? [];

        if (analysisDocs.isEmpty) {
          return _buildEmptyStateCard(
            icon: Icons.fitness_center_outlined,
            message: 'Bu tarih aralığında analiz bulunmamakta',
          );
        }

        // Bölgelere göre performans verileri
        Map<String, List<double>> regionAccuracies = {};
        Map<String, int> regionCounts = {};

        for (var doc in analysisDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final bodyRegion = data['bodyRegion'] as String? ?? 'Diğer';
          final accuracy = data['accuracyPercent'] as double? ?? 0.0;

          if (!regionAccuracies.containsKey(bodyRegion)) {
            regionAccuracies[bodyRegion] = [];
            regionCounts[bodyRegion] = 0;
          }

          regionAccuracies[bodyRegion]!.add(accuracy);
          regionCounts[bodyRegion] = (regionCounts[bodyRegion] ?? 0) + 1;
        }

        // Seçilen bölgeye göre filtreleme
        if (_selectedBodyRegion != 'Tüm Bölgeler') {
          regionAccuracies = {
            _selectedBodyRegion: regionAccuracies[_selectedBodyRegion] ?? []
          };
          regionCounts = {
            _selectedBodyRegion: regionCounts[_selectedBodyRegion] ?? 0
          };
        }

        if (regionAccuracies.isEmpty) {
          return _buildEmptyStateCard(
            icon: Icons.filter_alt_outlined,
            message: 'Seçilen bölgede analiz bulunmamakta',
          );
        }

        // Bölge performans kartları
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0, left: 4),
                child: Text(
                  'Bölgelere Göre Performans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...regionAccuracies.entries.map((entry) {
                final region = entry.key;
                final accuracies = entry.value;

                // Ortalama doğruluk hesapla
                double avgAccuracy = 0;
                if (accuracies.isNotEmpty) {
                  accuracies.forEach((acc) => avgAccuracy += acc);
                  avgAccuracy /= accuracies.length;
                }

                final exerciseCount = regionCounts[region] ?? 0;

                return _buildRegionPerformanceCard(
                  region: region,
                  accuracy: avgAccuracy,
                  exerciseCount: exerciseCount,
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMostPerformedExercises() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.userId)
          .collection('analysisResults')
          .where('timestamp', isGreaterThanOrEqualTo: widget.startDate)
          .where('timestamp', isLessThanOrEqualTo: widget.endDate)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(300);
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Veri yüklenirken hata oluştu'),
          );
        }

        final analysisDocs = snapshot.data?.docs ?? [];

        if (analysisDocs.isEmpty) {
          return _buildEmptyStateCard(
            icon: Icons.fitness_center_outlined,
            message: 'Bu tarih aralığında analiz bulunmamakta',
          );
        }

        // Egzersiz sayımlarını topla
        Map<String, int> exerciseCounts = {};
        Map<String, List<double>> exerciseAccuracies = {};

        for (var doc in analysisDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final exerciseName = data['exerciseName'] as String? ?? 'Bilinmeyen';
          final bodyRegion = data['bodyRegion'] as String? ?? 'Diğer';
          final accuracy = data['accuracyPercent'] as double? ?? 0.0;

          // Bölgeye göre filtreleme
          if (_selectedBodyRegion != 'Tüm Bölgeler' &&
              bodyRegion != _selectedBodyRegion) {
            continue;
          }

          exerciseCounts[exerciseName] =
              (exerciseCounts[exerciseName] ?? 0) + 1;

          if (!exerciseAccuracies.containsKey(exerciseName)) {
            exerciseAccuracies[exerciseName] = [];
          }
          exerciseAccuracies[exerciseName]!.add(accuracy);
        }

        // Eğer hiç egzersiz yoksa
        if (exerciseCounts.isEmpty) {
          return _buildEmptyStateCard(
            icon: Icons.filter_list,
            message: 'Seçilen kriterlere göre egzersiz bulunmamakta',
          );
        }

        // En çok yapılan egzersizleri sıralama
        final sortedExercises = exerciseCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // İlk 5 egzersizi göster (veya daha az varsa tümünü)
        final topExercises = sortedExercises.take(5).toList();

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fitness_center, color: _primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'En Çok Yapılan Egzersizler',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ...topExercises.map((entry) {
                  final exerciseName = entry.key;
                  final count = entry.value;
                  final accuracies = exerciseAccuracies[exerciseName] ?? [];

                  // Ortalama doğruluk hesapla
                  double avgAccuracy = 0;
                  if (accuracies.isNotEmpty) {
                    accuracies.forEach((acc) => avgAccuracy += acc);
                    avgAccuracy /= accuracies.length;
                  }

                  return _buildExerciseListItem(
                    exerciseName: exerciseName,
                    count: count,
                    accuracy: avgAccuracy,
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegionPerformanceCard({
    required String region,
    required double accuracy,
    required int exerciseCount,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getBodyRegionColor(region).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getBodyRegionIcon(region),
                color: _getBodyRegionColor(region),
                size: 22,
              ),
            ),
            title: Text(
              region,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              '$exerciseCount egzersiz',
              style: TextStyle(
                color: _greyTextColor,
                fontSize: 13,
              ),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getAccuracyColor(accuracy).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${accuracy.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _getAccuracyColor(accuracy),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPerformanceProgressBar(accuracy),
                SizedBox(height: 16),
                _buildImprovementTip(region, accuracy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseListItem({
    required String exerciseName,
    required int count,
    required double accuracy,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getExerciseIcon(exerciseName),
              color: _primaryColor,
              size: 20,
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
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$count kez yapıldı',
                  style: TextStyle(
                    color: _greyTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getAccuracyColor(accuracy).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${accuracy.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getAccuracyColor(accuracy),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceProgressBar(double accuracy) {
    final percentage = (accuracy).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Form Kalitesi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getAccuracyColor(accuracy),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                color: Colors.grey.shade200,
              ),
              FractionallySizedBox(
                widthFactor: accuracy / 100,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getAccuracyColor(accuracy),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _getAccuracyColor(accuracy).withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceChart(Map<DateTime, double> accuracyData) {
    if (accuracyData.isEmpty) {
      return Center(
        child: Text(
          'Veri bulunmamakta',
          style: TextStyle(
            color: _greyTextColor,
            fontSize: 16,
          ),
        ),
      );
    }

    final sortedEntries = accuracyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = <FlSpot>[];
    for (var i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].value / 100));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 0.2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < sortedEntries.length &&
                    (sortedEntries.length <= 7 ||
                        value.toInt() % (sortedEntries.length ~/ 5) == 0)) {
                  final date = sortedEntries[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('d MMM').format(date),
                      style: TextStyle(
                        color: _greyTextColor,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return SizedBox();
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    color: _greyTextColor,
                    fontSize: 12,
                  ),
                );
              },
              interval: 0.2,
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (sortedEntries.length - 1).toDouble(),
        minY: 0,
        maxY: 1.0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.amber,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length < 10,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 6,
                    color: _primaryColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _primaryColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementTip(String region, double accuracy) {
    String tipText = '';

    if (accuracy < 70) {
      switch (region) {
        case 'Göğüs':
          tipText =
          "Form geliştirmek için ağırlıkları azaltıp tekniğe odaklanın. Göğüs kaslarınızı hissetmeye çalışın.";
          break;
        case 'Sırt':
          tipText =
          "Sırt kaslarınızı hissetmeye odaklanın. Çekişlerde omuzlarınızı geri çekin ve sıkın.";
          break;
        case 'Omuzlar':
          tipText =
          "Hafif ağırlıklar ile teknik geliştirin. Omuz kaslarını izole etmeye çalışın.";
          break;
        case 'Kollar':
          tipText =
          "Formunuzu geliştirin ve eklemlerin aşırı zorlanmasından kaçının. Kontrollü hareket edin.";
          break;
        case 'Bacaklar':
          tipText =
          "Doğru hareket aralığına odaklanın. Sırtınızı düz tutun ve dizlerinizi kontrol edin.";
          break;
        case 'Karın':
          tipText =
          "Her hareketi kontrollü yapın. Boyun zorlanmasından kaçının, karın kaslarınızı sıkın.";
          break;
        default:
          tipText =
          "Temel tekniklere odaklanın ve formunuzu geliştirin. Aynada kontrol edin.";
      }
    } else if (accuracy < 85) {
      switch (region) {
        case 'Göğüs':
          tipText =
          "Temponuzu yavaşlatın ve kasın tam kasılmasına odaklanın. Daha kontrollü çalışın.";
          break;
        case 'Sırt':
          tipText =
          "Her tekrarda tam açıda çalışmaya odaklanın. Sırt kaslarınızı sıkarak hareket edin.";
          break;
        case 'Omuzlar':
          tipText =
          "Farklı açılardan çalışarak omuz gelişimini dengelemek faydalı olabilir.";
          break;
        case 'Kollar':
          tipText =
          "Hareketi izole etmeye çalışın. Momentum kullanmaktan kaçının, yavaş ve kontrollü olun.";
          break;
        case 'Bacaklar':
          tipText =
          "Stabilite ve denge çalışmalarını programınıza ekleyin. Tek bacak varyasyonları deneyin.";
          break;
        case 'Karın':
          tipText =
          "Nefes kontrolüne odaklanın ve karın bölgesini tam olarak sıkın. Kaliteli tekrar yapın.";
          break;
        default:
          tipText =
          "İyi gidiyorsunuz! Hafif teknik iyileştirmeler ile formunuzu daha da geliştirebilirsiniz.";
      }
    } else {
      switch (region) {
        case 'Göğüs':
          tipText =
          "Mükemmel form! Zorluğu artırabilir veya süper setler ekleyerek antrenmanınızı yoğunlaştırabilirsiniz.";
          break;
        case 'Sırt':
          tipText =
          "Çok iyi! Farklı çekiş varyasyonları ekleyerek gelişimi sürdürün ve ağırlıkları artırabilirsiniz.";
          break;
        case 'Omuzlar':
          tipText =
          "Harika gidiyorsunuz! İleri seviye hareketlere geçebilir veya piramit setler ekleyebilirsiniz.";
          break;
        case 'Kollar':
          tipText =
          "Mükemmel! Süper setler ekleyerek antrenmanı yoğunlaştırabilir veya daha ileri teknikler deneyebilirsiniz.";
          break;
        case 'Bacaklar':
          tipText =
          "Harika form! Tek bacak egzersizleri ile dengeyi geliştirin veya ağırlıkları artırın.";
          break;
        case 'Karın':
          tipText =
          "Formunuz çok iyi! Daha zorlu hareketleri deneyebilir veya direnç ekleyebilirsiniz.";
          break;
        default:
          tipText =
          "Mükemmel performans! Bu şekilde devam edin ve antrenman yoğunluğunu artırabilirsiniz.";
      }
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            accuracy < 70
                ? Icons.lightbulb_outline
                : accuracy < 85
                ? Icons.tips_and_updates_outlined
                : Icons.star_outline,
            color: _getAccuracyColor(accuracy),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              tipText,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String message,
    double height = 200,
  }) {
    return Container(
      height: height,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.grey.shade300,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: _greyTextColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(double height) {
    return Container(
      height: height,
      padding: EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageAccuracy(Map<DateTime, double> accuracyData) {
    if (accuracyData.isEmpty) return SizedBox();

    double totalAccuracy = 0;
    for (var accuracy in accuracyData.values) {
      totalAccuracy += accuracy;
    }

    final avgAccuracy = totalAccuracy / accuracyData.length;
    final avgPercentage = avgAccuracy.toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getAccuracyColor(avgAccuracy).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Ort. $avgPercentage%',
        style: TextStyle(
          color: _getAccuracyColor(avgAccuracy),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
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
        return _primaryColor;
    }
  }

  IconData _getBodyRegionIcon(String region) {
    switch (region) {
      case 'Göğüs':
        return Icons.fitness_center;
      case 'Sırt':
        return Icons.accessibility_new;
      case 'Omuzlar':
        return Icons.architecture;
      case 'Kollar':
        return Icons.sports_gymnastics;
      case 'Bacaklar':
        return Icons.directions_walk;
      case 'Karın':
        return Icons.circle;
      default:
        return Icons.fitness_center;
    }
  }

  IconData _getExerciseIcon(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();

    if (lowerName.contains('squat')) {
      return Icons.accessibility_new;
    } else if (lowerName.contains('push') || lowerName.contains('bench')) {
      return Icons.fitness_center;
    } else if (lowerName.contains('curl')) {
      return Icons.sports_gymnastics;
    } else if (lowerName.contains('shoulder') || lowerName.contains('press') ||
        lowerName.contains('raise')) {
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
}