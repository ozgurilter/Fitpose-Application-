import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';

class ModernDateRangePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTimeRange) onDateRangeSelected;

  const ModernDateRangePicker({
    Key? key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  _ModernDateRangePickerState createState() => _ModernDateRangePickerState();
}

class _ModernDateRangePickerState extends State<ModernDateRangePicker> {
  late DateTime _startDate;
  late DateTime _endDate;
  final DateRangePickerController _controller = DateRangePickerController();

  // Uygulama renkleri
  final Color primaryColor = const Color(0xFF5046E5); // mavimsi mor
  final Color grayColor = const Color(0xFF9aa0a6); // gri
  final Color accentColor = const Color(0xFFFF7D33); // turuncu

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate ?? DateTime.now().subtract(const Duration(days: 7));
    _endDate = widget.initialEndDate ?? DateTime.now();

    _controller.selectedRange = PickerDateRange(_startDate, _endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tarih Aralığı Seçin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: grayColor),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            const SizedBox(height: 12),

            // Seçilen tarih aralığı bilgisi
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(_startDate),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 18, color: grayColor),
                  Text(
                    DateFormat('dd MMM yyyy').format(_endDate),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Takvim widget'ı
            SizedBox(
              height: 300,
              child: SfDateRangePicker(
                controller: _controller,
                view: DateRangePickerView.month,
                selectionMode: DateRangePickerSelectionMode.range,
                monthViewSettings: DateRangePickerMonthViewSettings(
                  viewHeaderStyle: DateRangePickerViewHeaderStyle(
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: grayColor,
                    ),
                  ),
                  firstDayOfWeek: 1, // Pazartesi
                ),
                headerStyle: DateRangePickerHeaderStyle(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                yearCellStyle: DateRangePickerYearCellStyle(
                  textStyle: const TextStyle(fontSize: 14),
                  todayTextStyle: const TextStyle(fontSize: 14),
                ),
                monthCellStyle: DateRangePickerMonthCellStyle(
                  textStyle: TextStyle(fontSize: 14, color: Colors.black87),
                  todayTextStyle: TextStyle(fontSize: 14, color: primaryColor, fontWeight: FontWeight.bold),
                ),
                selectionTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
                rangeTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
                startRangeSelectionColor: accentColor,
                endRangeSelectionColor: accentColor,
                rangeSelectionColor: accentColor.withOpacity(0.2),
                todayHighlightColor: primaryColor,
                selectionColor: primaryColor,
                onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                  if (args.value is PickerDateRange) {
                    final PickerDateRange range = args.value;
                    setState(() {
                      _startDate = range.startDate ?? _startDate;
                      _endDate = range.endDate ?? _startDate;
                    });
                  }
                },
                showNavigationArrow: true,
              ),
            ),
            const SizedBox(height: 20),

            // Hızlı seçim butonları
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickSelectButton('Bugün', () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = now;
                    _endDate = now;
                    _controller.selectedRange = PickerDateRange(_startDate, _endDate);
                  });
                }),
                _buildQuickSelectButton('Son 7 Gün', () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = now.subtract(const Duration(days: 6));
                    _endDate = now;
                    _controller.selectedRange = PickerDateRange(_startDate, _endDate);
                  });
                }),
                _buildQuickSelectButton('Son 30 Gün', () {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = now.subtract(const Duration(days: 29));
                    _endDate = now;
                    _controller.selectedRange = PickerDateRange(_startDate, _endDate);
                  });
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'İptal',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onDateRangeSelected(DateTimeRange(start: _startDate, end: _endDate));
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Uygula'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: grayColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: accentColor,
          ),
        ),
      ),
    );
  }
}
