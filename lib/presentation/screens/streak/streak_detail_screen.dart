import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakDetailScreen extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final Map<String, bool>? weeklyCompletion; // Map of date strings (YYYY-MM-DD) to completion status

  const StreakDetailScreen({
    super.key,
    this.currentStreak = 12,
    this.bestStreak = 20,
    this.weeklyCompletion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Chuỗi ngày luyện tập',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Fire Icon with Streak Number
            SizedBox(
              width: 250, // Fixed width - increased by ~30%
              height: 250, // Fixed height - increased by ~30%
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent, // Transparent background - no fill
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF9900), // Vibrant Orange
                    width: 2, // Thin, clean border
                  ),
                  boxShadow: [
                    // Very faint, subtle glow just outside the border
                    BoxShadow(
                      color: const Color(0xFFFF9900).withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Fire Icon with very subtle glow effect
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Very subtle, contained glow around the fire icon only
                          BoxShadow(
                            color: const Color(0xFFFF9900).withOpacity(0.25),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.local_fire_department,
                          color: const Color(0xFFFF9900), // Vibrant Orange
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Group: Number and Text together
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$currentStreak',
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White for strong contrast
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ngày liên tiếp',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white, // White for readability
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 56),
            // Motivational Message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade700.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.shade600.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Colors.orange.shade600,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tuyệt vời!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bạn đã duy trì chuỗi ngày luyện tập trong $currentStreak ngày. Hãy tiếp tục phát huy!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Progress Info Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade800.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.shade700.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin chuỗi ngày',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Bắt đầu',
                    value: 'Ngày ${DateTime.now().subtract(Duration(days: currentStreak - 1)).day}/${DateTime.now().subtract(Duration(days: currentStreak - 1)).month}',
                    boldValue: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.trending_up,
                    label: 'Mục tiêu',
                    value: '30 ngày',
                    boldValue: true,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.local_fire_department,
                    label: 'Tiến độ',
                    value: '${((currentStreak / 30) * 100).toStringAsFixed(0)}%',
                    boldValue: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Current and Best Streak Cards
            Row(
              children: [
                Expanded(
                  child: _buildStreakCard(
                    title: 'Chuỗi hiện tại',
                    value: currentStreak,
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStreakCard(
                    title: 'Chuỗi tốt nhất',
                    value: bestStreak,
                    icon: Icons.emoji_events,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Weekly Completion Status
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade800.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.shade700.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_view_week,
                        color: Colors.orange.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Trạng thái tuần này',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildWeeklyCompletionGrid(),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard({
    required String title,
    required int value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.shade700.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.shade600.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color.shade600,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$value',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color.shade400,
                  ),
                ),
                TextSpan(
                  text: ' ngày',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCompletionGrid() {
    final completionData = weeklyCompletion ?? _generateDefaultWeeklyData();
    final weekDays = _getCurrentWeekDays();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.asMap().entries.map((entry) {
        final index = entry.key;
        final date = entry.value;
        final dateKey = date.toIso8601String().split('T')[0];
        final isCompleted = completionData[dateKey] ?? false;
        final isToday = date.day == DateTime.now().day &&
                       date.month == DateTime.now().month &&
                       date.year == DateTime.now().year;
        
        return Expanded(
          child: Column(
            children: [
              // Day label
              Text(
                _getDayAbbreviation(index),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 8),
              // Status icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.orange.shade700.withOpacity(0.2)
                      : Colors.grey.shade700.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isToday
                        ? Colors.orange.shade600
                        : (isCompleted
                            ? Colors.orange.shade600.withOpacity(0.5)
                            : Colors.grey.shade600.withOpacity(0.3)),
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Icon(
                  isCompleted ? Icons.local_fire_department : Icons.remove,
                  color: isCompleted
                      ? Colors.orange.shade600
                      : Colors.grey.shade500,
                  size: isCompleted ? 24 : 20,
                ),
              ),
              const SizedBox(height: 6),
              // Date number
              Text(
                '${date.day}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday
                      ? Colors.orange.shade400
                      : (isCompleted ? Colors.white70 : Colors.white54),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<DateTime> _getCurrentWeekDays() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  String _getDayAbbreviation(int weekdayIndex) {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days[weekdayIndex];
  }

  Map<String, bool> _generateDefaultWeeklyData() {
    // Generate default data based on current streak
    final weekDays = _getCurrentWeekDays();
    final today = DateTime.now();
    final data = <String, bool>{};
    
    // Mark days as completed if they're within the current streak
    for (var i = 0; i < weekDays.length; i++) {
      final date = weekDays[i];
      final dateKey = date.toIso8601String().split('T')[0];
      
      // If date is today or in the past and within streak range, mark as completed
      if (date.isBefore(today) || date.day == today.day) {
        // Simple logic: mark recent days as completed (can be enhanced with real data)
        final daysAgo = today.difference(date).inDays;
        data[dateKey] = daysAgo < currentStreak && daysAgo >= 0;
      } else {
        data[dateKey] = false;
      }
    }
    
    return data;
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool boldValue = false,
  }) {
    // Extract numeric/key data parts to bold
    String? boldPart;
    String? regularPart;
    
    if (boldValue) {
      // For "Ngày 13/11" - bold the date part
      if (value.startsWith('Ngày ')) {
        boldPart = value.substring(5); // "13/11"
        regularPart = 'Ngày ';
      }
      // For "30 ngày" - bold the number
      else if (value.contains(' ngày')) {
        final parts = value.split(' ngày');
        boldPart = parts[0]; // "30"
        regularPart = ' ngày';
      }
      // For "40%" - bold the percentage
      else if (value.endsWith('%')) {
        boldPart = value; // "40%"
        regularPart = null;
      }
    }
    
    return Row(
      children: [
        Icon(icon, color: Colors.orange.shade600, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white70,
            ),
          ),
        ),
        if (boldValue && boldPart != null)
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white,
              ),
              children: [
                if (regularPart != null)
                  TextSpan(
                    text: regularPart,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                TextSpan(
                  text: boldPart,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade400,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: boldValue ? FontWeight.bold : FontWeight.w600,
              color: boldValue ? Colors.orange.shade400 : Colors.white,
            ),
          ),
      ],
    );
  }
}

