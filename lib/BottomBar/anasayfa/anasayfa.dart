
import 'package:flutter/material.dart';
import 'package:fitness_tracking_app/models/userModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  final UserModel currentUser;

  const HomePage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _workoutEvents = {};
  late String _dailyTip;
  bool _isChatOpen = false;
  TextEditingController _chatController = TextEditingController();
  List<ChatMessage> _chatMessages = [];
  bool _isLoading = false;
  final String _geminiApiKey = "Your APİ key";

  final List<String> _workoutTips = [
    'Egzersiz öncesi ve sonrası mutlaka su içmeyi unutma! 💧',
    'Kardiyo, hem kilo vermene hem de kalp sağlığına yardımcı olur. 🏃‍♂️',
    'Kaliteli uyku, kas gelişimi için en önemli faktörlerden biri. 😴',
    'Protein alımını artırarak kas kazanımını destekleyebilirsin. 🥩',
    'Haftada en az 2 gün direnç antrenmanı yapmayı hedefle. 💪',
    'Esneme hareketleri sakatlanma riskini azaltır. 🧘‍♀️',
    'Günde en az 8.000 adım atmayı hedefle. 👟',
    'Antrenman sonrası soğuma hareketleri kas ağrılarını azaltır. ❄️',
    'Antrenman günlüğü tutmak ilerlemeni görmeni sağlar. 📝',
    'Vücut ağırlığınla yapılan egzersizler bile oldukça etkilidir. 🙌',
    'Haftada 150 dakika orta şiddetli aktivite önerilir. ⏱️',
    'Antrenman çeşitliliği motivasyonunu yüksek tutar. 🔄',
    'Renkli sebzeler antioksidan alımını artırır. 🥗',
    'Yeterli su içmek performansını artırır. 🚰',
    'Doğru ayakkabı seçimi sakatlanmaları önler. 👟',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadWorkoutDays();
    _setDailyTip();
  }

  void _setDailyTip() {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final tipIndex = dayOfYear % _workoutTips.length;
    _dailyTip = _workoutTips[tipIndex];
  }

  // Gemini API ile mesaj gönderme
  // Gemini API ile mesaj gönderme - Düzeltilmiş versiyon
  Future<void> _sendMessageToGemini(String message) async {
    setState(() {
      _isLoading = true;
      _chatMessages.add(ChatMessage(text: message, isUserMessage: true));
    });

    try {
      // Güncel Gemini API endpoint'i
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
      );

      // Gemini API isteği için gerekli body
      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": "Sen bir fitness ve sağlıklı yaşam konusunda uzman asistansın. " +
                    "Kullanıcının adı: ${widget.currentUser.nameSurname}. " +
                    "Şimdi kullanıcının sorusunu yanıtla: $message",
              },
            ],
          },
        ],
        "generationConfig": {
          "temperature": 0.7,
          "topK": 40,
          "topP": 0.95,
          "maxOutputTokens": 800,
        },
      };

      // API isteği gönderme
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('HTTP Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Gemini API yanıtını işleme
        String botResponse = '';
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          botResponse = responseData['candidates'][0]['content']['parts'][0]['text'];
        } else {
          botResponse = 'Yanıt alınamadı. Lütfen tekrar deneyin.';
        }

        setState(() {
          _chatMessages.add(
            ChatMessage(text: botResponse, isUserMessage: false),
          );
          _isLoading = false;
        });
      } else {
        // Hata detaylarını göster
        print('API Hatası: ${response.statusCode}');
        print('Hata Mesajı: ${response.body}');

        setState(() {
          _chatMessages.add(
            ChatMessage(
              text: 'Bir hata oluştu. Hata kodu: ${response.statusCode}\n'
                  'Detay: ${response.body}',
              isUserMessage: false,
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception: $e');
      setState(() {
        _chatMessages.add(
          ChatMessage(
            text: 'Bağlantı hatası oluştu: $e',
            isUserMessage: false,
          ),
        );
        _isLoading = false;
      });
    }

    _chatController.clear();
  }

  // Firestore'dan antrenman günlerini yükle
  Future<void> _loadWorkoutDays() async {
    DateTime _startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
    DateTime _endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.currentUser.userId)
              .collection('analysisResults')
              .where('timestamp', isGreaterThanOrEqualTo: _startDate)
              .where('timestamp', isLessThanOrEqualTo: _endDate)
              .orderBy('timestamp', descending: true)
              .get();

      Map<DateTime, List<dynamic>> events = {};

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = Map<String, dynamic>.from(
          doc.data() as Map<String, dynamic>,
        );
        data['id'] = doc.id;

        DateTime date = (data['timestamp'] as Timestamp).toDate();
        DateTime normalizedDate = DateTime(date.year, date.month, date.day);

        if (events[normalizedDate] != null) {
          events[normalizedDate]!.add(data);
        } else {
          events[normalizedDate] = [data];
        }
      }

      setState(() {
        _workoutEvents = events;
      });
    } catch (e) {
      print('Antrenman günlerini yükleme hatası: $e');
    }
  }

  // Ay değiştirme fonksiyonu
  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });

    // Yeni ay için antrenman günlerini yeniden yükle
    _loadWorkoutDays();
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    // Zaman kısmını kaldırmak için tarihi normalleştir
    DateTime normalizedDate = DateTime(day.year, day.month, day.day);
    return _workoutEvents[normalizedDate] ?? [];
  }

  // Chat penceresini aç/kapat
  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.03),

                    // Modern minimal üst başlık
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getTodayDateInTurkish(),
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Row(
                          children: [
                            // Chat butonu - yeni eklenen kısım
                            GestureDetector(
                              onTap: _toggleChat,
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                margin: EdgeInsets.only(
                                  right: screenWidth * 0.03,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF7D30).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline,
                                  size: screenWidth * 0.06,
                                  color: Color(0xFFFF7D30),
                                ),
                              ),
                            ),
                            // Kullanıcı avatarı
                            CircleAvatar(
                              radius: screenWidth * 0.06,
                              backgroundColor: Color(0xFF5046E5),
                              child: Text(
                                _getInitials(widget.currentUser.nameSurname),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.05,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Modern Antrenman Takvimi
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Antrenman Takviminiz',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF5046E5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      size: 16,
                                      color: Color(0xFF5046E5),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _getTotalWorkoutsForMonth().toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5046E5),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            availableCalendarFormats: const {
                              CalendarFormat.month: 'Ay',
                              CalendarFormat.week: 'Hafta',
                            },
                            eventLoader: _getEventsForDay,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDay, day);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            onPageChanged: _onPageChanged,
                            calendarStyle: CalendarStyle(
                              markersMaxCount: 3,
                              markerDecoration: BoxDecoration(
                                color: Color(0xFF5046E5),
                                shape: BoxShape.circle,
                              ),
                              markerSize: 8,
                              todayDecoration: BoxDecoration(
                                border: Border.all(
                                  color: Color(0xFF5046E5),
                                  width: 1.5,
                                ),
                                shape: BoxShape.circle,
                              ),
                              todayTextStyle: TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.bold,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Color(0xFF5046E5),
                                shape: BoxShape.circle,
                              ),
                              selectedTextStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              weekendTextStyle: TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                              outsideDaysVisible: false,
                              defaultTextStyle: TextStyle(
                                fontFamily: 'Poppins',
                              ),
                            ),
                            headerStyle: HeaderStyle(
                              formatButtonVisible: true,
                              formatButtonTextStyle: TextStyle(
                                fontSize: 14.0,
                                color: Color(0xFF5046E5),
                                fontFamily: 'Poppins',
                              ),
                              formatButtonDecoration: BoxDecoration(
                                color: Color(0xFF5046E5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              titleTextStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                                fontFamily: 'Poppins',
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                color: Color(0xFF5046E5),
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                color: Color(0xFF5046E5),
                              ),
                              headerPadding: EdgeInsets.symmetric(vertical: 10),
                              titleCentered: true,
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: TextStyle(
                                color: Color(0xFF6B7280),
                                fontFamily: 'Poppins',
                              ),
                              weekendStyle: TextStyle(
                                color: Color(0xFF6B7280),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),

                          // Seçili gün için antrenman detayları
                          if (_selectedDay != null &&
                              _getEventsForDay(_selectedDay!).isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 16),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFF5046E5).withOpacity(0.07),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(0xFF5046E5).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: Color(0xFF5046E5),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _formatDateInTurkish(_selectedDay!),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF5046E5),
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      Spacer(),
                                      // Antrenman sayısını göster
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(
                                            0xFF5046E5,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${_getEventsForDay(_selectedDay!).length} antrenman',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF5046E5),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),

                                  // Scrollable antrenman listesi - maksimum 3 antrenman göster
                                  Container(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          _getEventsForDay(
                                                    _selectedDay!,
                                                  ).length >
                                                  3
                                              ? 240.0 // 3 antrenman için yaklaşık yükseklik
                                              : double.infinity,
                                    ),
                                    child: SingleChildScrollView(
                                      physics: BouncingScrollPhysics(),
                                      child: Column(
                                        children:
                                            _getEventsForDay(
                                              _selectedDay!,
                                            ).map((event) {
                                              return Container(
                                                margin: EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Color(
                                                      0xFF5046E5,
                                                    ).withOpacity(0.1),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: Color(
                                                              0xFFFF7D30,
                                                            ).withOpacity(
                                                              0.1,
                                                            ), // Turuncu renk eklendi
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: Icon(
                                                            Icons
                                                                .fitness_center,
                                                            size: 16,
                                                            color: Color(
                                                              0xFFFF7D30,
                                                            ), // Turuncu renk eklendi
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            event['exerciseName'] ??
                                                                'Bilinmeyen Egzersiz',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Color(
                                                                0xFF1F2937,
                                                              ),
                                                              fontFamily:
                                                                  'Poppins',
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          _formatDuration(
                                                            event['durationSeconds'],
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Color(
                                                              0xFFFF7D30,
                                                            ), // Turuncu renk eklendi
                                                            fontFamily:
                                                                'Poppins',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 8),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 44,
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                'Vücut Bölgesi: ',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                    0xFF9AA0A6,
                                                                  ), // Gri renk eklendi
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                              Text(
                                                                event['bodyRegion'] ??
                                                                    'Bilinmiyor',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Color(
                                                                    0xFF1F2937,
                                                                  ),
                                                                  fontFamily:
                                                                      'Poppins',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 4),
                                                          Row(
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    'Tekrar: ',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Color(
                                                                        0xFF9AA0A6,
                                                                      ), // Gri renk eklendi
                                                                      fontFamily:
                                                                          'Poppins',
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    '${event['repCount'] ?? 0}',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: Color(
                                                                        0xFF1F2937,
                                                                      ),
                                                                      fontFamily:
                                                                          'Poppins',
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                width: 16,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    'Doğruluk: ',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Color(
                                                                        0xFF9AA0A6,
                                                                      ), // Gri renk eklendi
                                                                      fontFamily:
                                                                          'Poppins',
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    '%${(event['accuracyPercent'] ?? 0.0).toStringAsFixed(1)}',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: _getAccuracyColor(
                                                                        event['accuracyPercent'] ??
                                                                            0.0,
                                                                      ),
                                                                      fontFamily:
                                                                          'Poppins',
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),

                                  // Eğer 3'ten fazla antrenman varsa scroll indicator göster
                                  if (_getEventsForDay(_selectedDay!).length >
                                      3)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            size: 16,
                                            color: Color(0xFF6B7280),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Daha fazla görmek için kaydırın',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF6B7280),
                                              fontFamily: 'Poppins',
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

                    SizedBox(height: screenHeight * 0.025),

                    // Günün İpucu - Modern tasarım (Renk güncellendi)
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.045),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFF7D30),
                            Color(0xFFFF9A60),
                          ], // Turuncu gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF7D30).withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.025),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: Colors.white,
                              size: screenWidth * 0.06,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Günün İpucu',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _dailyTip,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    color: Colors.white.withOpacity(0.9),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.025),
                  ],
                ),
              ),
            ),
            if (_isChatOpen)
              Positioned(
                right: screenWidth * 0.05,
                top: screenHeight * 0.1,
                child: Container(
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Chat header
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF7D30),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fitness Asistanı',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            GestureDetector(
                              onTap: _toggleChat,
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Chat messages
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child:
                              _chatMessages.isEmpty
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          color: Color(
                                            0xFF9AA0A6,
                                          ).withOpacity(0.6),
                                          size: 40,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Fitness asistanına hoş geldiniz!',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF9AA0A6),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Egzersiz tavsiyeleri, beslenme önerileri veya motivasyon için sorularınızı sorabilirsiniz.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(
                                              0xFF9AA0A6,
                                            ).withOpacity(0.8),
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : ListView.builder(
                                    padding: EdgeInsets.only(bottom: 10),
                                    itemCount: _chatMessages.length,
                                    reverse: false,
                                    physics: BouncingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final message = _chatMessages[index];
                                      return Container(
                                        margin: EdgeInsets.only(
                                          bottom: 12,
                                          left: message.isUserMessage ? 40 : 0,
                                          right: message.isUserMessage ? 0 : 40,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              message.isUserMessage
                                                  ? Color(
                                                    0xFF5046E5,
                                                  ).withOpacity(0.1)
                                                  : Color(
                                                    0xFFFF7D30,
                                                  ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color:
                                                message.isUserMessage
                                                    ? Color(
                                                      0xFF5046E5,
                                                    ).withOpacity(0.2)
                                                    : Color(
                                                      0xFFFF7D30,
                                                    ).withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          message.text,
                                          style: TextStyle(
                                            color: Color(0xFF1F2937),
                                            fontSize: 13,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ),
                      // Chat input field
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                decoration: InputDecoration(
                                  hintText: 'Mesajınızı yazın...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9AA0A6),
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Color(0xFF9AA0A6).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Color(0xFF9AA0A6).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF7D30),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                onSubmitted: (text) {
                                  if (text.trim().isNotEmpty) {
                                    _sendMessageToGemini(text.trim());
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                if (_chatController.text.trim().isNotEmpty) {
                                  _sendMessageToGemini(
                                    _chatController.text.trim(),
                                  );
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF7D30),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child:
                                    _isLoading
                                        ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Bugünün tarihini Türkçe olarak formatla
  String _getTodayDateInTurkish() {
    final now = DateTime.now();
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    final dayName = days[now.weekday - 1];
    return '$dayName, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // Herhangi bir tarihi Türkçe olarak formatla
  String _formatDateInTurkish(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '';

    List<String> names = fullName.split(' ');
    String initials = '';

    for (var name in names) {
      if (name.isNotEmpty) {
        initials += name[0];
      }
      if (initials.length >= 2) break;
    }

    return initials.toUpperCase();
  }

  int _getTotalWorkoutsForMonth() {
    int total = 0;
    _workoutEvents.forEach((date, events) {
      if (date.month == _focusedDay.month && date.year == _focusedDay.year) {
        total += events.length;
      }
    });
    return total;
  }

  String _formatDuration(dynamic durationInSeconds) {
    // Null kontrolü ve varsayılan değer
    int seconds = 0;
    if (durationInSeconds != null) {
      // Double veya int olabilir, kontrol ediyoruz
      if (durationInSeconds is double) {
        seconds = durationInSeconds.round();
      } else if (durationInSeconds is int) {
        seconds = durationInSeconds;
      }
    }

    // Saniyeyi dakika ve saniyeye çevir
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;

    // Eğer 1 dakikadan az ise sadece saniye göster
    if (minutes == 0) {
      return '$seconds sn';
    }
    // Eğer tam dakika ise sadece dakikayı göster
    else if (remainingSeconds == 0) {
      return '$minutes dk';
    }
    // Hem dakika hem saniye varsa ikisini de göster
    else {
      return '$minutes dk $remainingSeconds sn';
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) {
      return Color(0xFF10B981); // Yeşil
    } else if (accuracy >= 60) {
      return Color(0xFFF59E0B); // Sarı/Turuncu
    } else {
      return Color(0xFFEF4444); // Kırmızı
    }
  }
}

// Chat mesajı sınıfı
class ChatMessage {
  final String text;
  final bool isUserMessage;

  ChatMessage({required this.text, required this.isUserMessage});
}
