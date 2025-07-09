
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:fitness_tracking_app/BottomBar/analiz/DatePickerSelect.dart';
import 'package:fitness_tracking_app/BottomBar/analiz/analysis_timeline_tab.dart';
import 'package:fitness_tracking_app/BottomBar/analiz/analysis_statistics_tab.dart';
import 'package:flutter/material.dart';
import 'package:fitness_tracking_app/models/userModel.dart';

class AnalysisPage extends StatefulWidget {
  final UserModel currentUser;
  final NotchBottomBarController? bottomBarController;
  final PageController? pageController;

  const AnalysisPage({
    Key? key,
    required this.currentUser,
    this.bottomBarController,
    this.pageController
  }) : super(key: key);

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Son 7 Gün';
  DateTime? _startDate;
  DateTime? _endDate;
  late TabController _tabController;
  DateTimeRange? _customDateRange;

  // Renk paletleri
  final Color _primaryColor = Color(0xFF5046E5);
  final Color _backgroundColor = Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;
  final Color _greyTextColor = Color(0xFF9aa0a6);

  @override
  void initState() {
    super.initState();
    _setDateRangeFromFilter('Son 7 Gün');
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setDateRangeFromFilter(String filter) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (filter) {
      case 'Son 7 Gün':
        start = now.subtract(Duration(days: 7));
        break;
      case 'Son 30 Gün':
        start = now.subtract(Duration(days: 30));
        break;
      case 'Son 3 Ay':
        start = now.subtract(Duration(days: 90));
        break;
      case 'Özel Aralık':
        if (_customDateRange != null) {
          start = _customDateRange!.start;
          end = _customDateRange!.end;
        } else {
          start = now.subtract(Duration(days: 7));
        }
        break;
      default:
        start = now.subtract(Duration(days: 7));
    }

    setState(() {
      _selectedFilter = filter;
      _startDate = start;
      _endDate = end;
    });
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final defaultStart = _customDateRange?.start ?? now.subtract(Duration(days: 7));
    final defaultEnd = _customDateRange?.end ?? now;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ModernDateRangePicker(
          initialStartDate: defaultStart,
          initialEndDate: defaultEnd,
          onDateRangeSelected: (DateTimeRange selected) {
            setState(() {
              _customDateRange = selected;
              _startDate = selected.start;
              _endDate = selected.end;
              _selectedFilter = 'Özel Aralık';
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: _cardColor,
              elevation: 0,
              expandedHeight: 150,
              pinned: true,
              floating: true,
              snap: false,
              title: Text(
                'Analizlerim',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.calendar_today, color: _primaryColor),
                  onPressed: _showDateRangePicker,
                ),
                SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(97),
                child: Container(
                  color: _cardColor,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildFilterChips(),
                      TabBar(
                        controller: _tabController,
                        labelColor: _primaryColor,
                        unselectedLabelColor: _greyTextColor,
                        indicatorColor: _primaryColor,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: 'Zaman Çizelgesi'),
                          Tab(text: 'İstatistikler'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            AnalysisTimelineTab(
              currentUser: widget.currentUser,
              startDate: _startDate,
              endDate: _endDate,
              bottomBarController: widget.bottomBarController,
              pageController: widget.pageController,
            ),
            AnalysisStatisticsTab(
              currentUser: widget.currentUser,
              startDate: _startDate,
              endDate: _endDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Son 7 Gün'),
          SizedBox(width: 8),
          _buildFilterChip('Son 30 Gün'),
          SizedBox(width: 8),
          _buildFilterChip('Son 3 Ay'),
          SizedBox(width: 8),
          _buildCustomRangeChip(),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _setDateRangeFromFilter(label);
        }
      },
      backgroundColor: _cardColor,
      selectedColor: _primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? _primaryColor : _greyTextColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? _primaryColor : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildCustomRangeChip() {
    final isSelected = _selectedFilter == 'Özel Aralık';
    return FilterChip(
      label: Row(
        children: [
          Text('Özel Aralık'),
          if (isSelected && _customDateRange != null) ...[
            SizedBox(width: 4),
            Icon(Icons.check, size: 16, color: _primaryColor),
          ]
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _showDateRangePicker();
        }
      },
      backgroundColor: _cardColor,
      selectedColor: _primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? _primaryColor : _greyTextColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? _primaryColor : Colors.grey.shade300,
        ),
      ),
    );
  }
}

