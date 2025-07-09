
import 'package:flutter/material.dart';
import 'package:fitness_tracking_app/models/userModel.dart';


class ExerciseSelectionPage extends StatefulWidget {
  final UserModel currentUser;
  final Function(String, String)? onExerciseSelected; // Callback for exercise selection

  const ExerciseSelectionPage({
    Key? key,
    required this.currentUser,
    this.onExerciseSelected,
  }) : super(key: key);

  @override
  State<ExerciseSelectionPage> createState() => _ExerciseSelectionPageState();
}

class _ExerciseSelectionPageState extends State<ExerciseSelectionPage>
    with TickerProviderStateMixin {

  String? _selectedExercise;

  // Animation controllers
  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;

  // Available exercises
  final List<Map<String, dynamic>> _availableExercises = [
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

  @override
  void initState() {
    super.initState();

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _cardAnimationController, curve: Curves.elasticOut)
    );

    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _selectExercise(String exerciseName) {
    setState(() {
      if (_selectedExercise == exerciseName) {
        _selectedExercise = null;
      } else {
        _selectedExercise = exerciseName;
      }
    });
  }

  void _continueToVideoAnalysis() {
    if (_selectedExercise == null) return;

    final exerciseDisplayName = _availableExercises
        .firstWhere((e) => e['name'] == _selectedExercise)['displayName'];

    // Callback aracılığıyla seçilen egzersizi bildir
    if (widget.onExerciseSelected != null) {
      widget.onExerciseSelected!(_selectedExercise!, exerciseDisplayName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFF5046E5).withOpacity(0.02),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5046E5).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5046E5), Color(0xFF7B68FF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF5046E5).withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Egzersiz Seçimi",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Analiz etmek istediğiniz hareketi seçin",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9aa0a6),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Exercise Grid - 3 columns
            Expanded(
              child: AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (_cardAnimation.value * 0.2).clamp(0.0, 0.2),
                    child: Opacity(
                      opacity: _cardAnimation.value.clamp(0.0, 1.0), // Clamp opacity between 0 and 1
                      child: GridView.builder(
                        padding: EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _availableExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _availableExercises[index];
                          final bool isSelected = _selectedExercise == exercise['name'];

                          // Staggered animation delay with proper clamping
                          final delay = index * 0.05; // Reduced delay for smoother animation
                          final adjustedValue = (_cardAnimation.value - delay).clamp(0.0, 1.0);

                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - adjustedValue)), // Reduced movement
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.fastOutSlowIn,
                              transform: isSelected
                                  ? (Matrix4.identity()..scale(1.02)..translate(0.0, -2.0))
                                  : Matrix4.identity(),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _selectExercise(exercise['name']),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: exercise['gradient'],
                                      )
                                          : LinearGradient(
                                        colors: [Colors.white, Colors.white],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : Color(0xFF9aa0a6).withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? (exercise['gradient'] as List<Color>)[0].withOpacity(0.3)
                                              : Colors.black.withOpacity(0.05),
                                          blurRadius: isSelected ? 16 : 6,
                                          offset: Offset(0, isSelected ? 4 : 2),
                                          spreadRadius: isSelected ? 1 : 0,
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Icon
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white.withOpacity(0.2)
                                                  : (exercise['gradient'] as List<Color>)[0].withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              exercise['icon'],
                                              size: 24,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (exercise['gradient'] as List<Color>)[0],
                                            ),
                                          ),

                                          SizedBox(height: 8),

                                          // Exercise name
                                          Text(
                                            exercise['displayName'],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          SizedBox(height: 4),

                                          // Description
                                          Text(
                                            exercise['description'],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isSelected
                                                  ? Colors.white.withOpacity(0.8)
                                                  : Color(0xFF9aa0a6),
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          // Selection indicator
                                          if (isSelected) ...[
                                            SizedBox(height: 6),
                                            Container(
                                              padding: EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Continue Button
            Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.9),
                    Colors.white,
                  ],
                ),
              ),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: _selectedExercise != null
                      ? LinearGradient(
                    colors: [Color(0xFF5046E5), Color(0xFF7B68FF)],
                  )
                      : null,
                  color: _selectedExercise == null ? Color(0xFF9aa0a6).withOpacity(0.3) : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _selectedExercise != null ? [
                    BoxShadow(
                      color: Color(0xFF5046E5).withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ] : [],
                ),
                child: ElevatedButton(
                  onPressed: _selectedExercise != null ? _continueToVideoAnalysis : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Devam Et",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

