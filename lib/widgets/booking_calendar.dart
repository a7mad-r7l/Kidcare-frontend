import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF3B82F6);
const _kUnavailable = Color(0xFFEF4444);
const _kTextPrimary = Color(0xFF1F2937);
const _kTextSecondary = Color(0xFF6B7280);
const _kTextDisabled = Color(0xFFD1D5DB);
const _kNavButtonBg = Color(0xFFF3F4F6);

/// Inline month-view calendar used in the booking flow.
///
/// Past dates (before [minDate]) are non-tappable. Selected date is a filled
/// blue circle with a soft glow; today shows a subtle dot under the number
/// when not selected. Switching months animates with a small slide+fade.
class BookingCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime minDate;
  final DateTime? maxDate;
  final ValueChanged<DateTime> onDateSelected;

  /// Dart weekdays (Mon=1..Sun=7) the doctor works on.
  /// Empty = unknown / not loaded — calendar shows no red marks.
  /// Any weekday NOT in this set is rendered as unavailable (red line, untappable).
  final Set<int> workingWeekdays;

  const BookingCalendar({
    super.key,
    required this.selectedDate,
    required this.minDate,
    this.maxDate,
    required this.onDateSelected,
    this.workingWeekdays = const <int>{},
  });

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  late DateTime _currentMonth;
  bool _slideForward = true;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    final initial = widget.selectedDate ?? widget.minDate;
    _currentMonth = DateTime(initial.year, initial.month);
  }

  @override
  void didUpdateWidget(BookingCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newSelected = widget.selectedDate;
    if (newSelected != null &&
        (newSelected.year != _currentMonth.year ||
            newSelected.month != _currentMonth.month)) {
      _slideForward = !newSelected.isBefore(
        DateTime(_currentMonth.year, _currentMonth.month),
      );
      _currentMonth = DateTime(newSelected.year, newSelected.month);
    }
  }

  void _prev() {
    setState(() {
      _slideForward = false;
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _next() {
    setState(() {
      _slideForward = true;
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month);
    if (target.year == _currentMonth.year &&
        target.month == _currentMonth.month) {
      return;
    }
    setState(() {
      _slideForward = target.isAfter(_currentMonth);
      _currentMonth = target;
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildWeekdayLabels(),
          const SizedBox(height: 8),
          ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: Offset(_slideForward ? 0.12 : -0.12, 0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: slide,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(
                  '${_currentMonth.year}-${_currentMonth.month}',
                ),
                child: _buildGrid(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final onCurrentMonth = _currentMonth.year == now.year &&
        _currentMonth.month == now.month;

    return Row(
      children: [
        _NavButton(icon: Icons.chevron_left_rounded, onTap: _prev),
        Expanded(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      axis: Axis.horizontal,
                      sizeFactor: animation,
                      child: child,
                    ),
                  ),
                  child: onCurrentMonth
                      ? const SizedBox.shrink(key: ValueKey('no-pill'))
                      : Padding(
                          key: const ValueKey('today-pill'),
                          padding: const EdgeInsets.only(left: 8),
                          child: _TodayPill(onTap: _jumpToToday),
                        ),
                ),
              ],
            ),
          ),
        ),
        _NavButton(icon: Icons.chevron_right_rounded, onTap: _next),
      ],
    );
  }


  Widget _buildWeekdayLabels() {
    return Row(
      children: _weekdayLabels
          .map(
            (l) => Expanded(
              child: Center(
                child: Text(
                  l,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _kTextSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGrid() {
    final firstOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final today = DateTime.now();
    final minNormalized = DateTime(
      widget.minDate.year,
      widget.minDate.month,
      widget.minDate.day,
    );

    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              if (cellIndex < firstWeekday || cellIndex >= totalCells) {
                return const Expanded(child: SizedBox(height: 44));
              }
              final day = cellIndex - firstWeekday + 1;
              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                day,
              );
              final isSelected = widget.selectedDate != null &&
                  _sameDay(date, widget.selectedDate!);
              final isToday = _sameDay(date, today);
              final isPast = date.isBefore(minNormalized);
              final isUnavailable = !isPast &&
                  widget.workingWeekdays.isNotEmpty &&
                  !widget.workingWeekdays.contains(date.weekday);

              return Expanded(
                child: _DayCell(
                  day: day,
                  isSelected: isSelected,
                  isToday: isToday,
                  isPast: isPast,
                  isUnavailable: isUnavailable,
                  onTap: (isPast || isUnavailable)
                      ? null
                      : () => widget.onDateSelected(date),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isPast;
  final bool isUnavailable;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isPast,
    required this.isUnavailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isSelected
        ? Colors.white
        : isPast
            ? _kTextDisabled
            : isUnavailable
                ? _kTextDisabled
                : isToday
                    ? _kPrimary
                    : _kTextPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 44,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
            if (isUnavailable && !isSelected)
              Positioned(
                bottom: 7,
                child: Container(
                  width: 14,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: _kUnavailable,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )
            else if (isToday && !isSelected)
              Positioned(
                bottom: 7,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kNavButtonBg,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: _kTextPrimary, size: 22),
        ),
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Today',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
