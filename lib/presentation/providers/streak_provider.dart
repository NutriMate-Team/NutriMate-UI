import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakProvider extends ChangeNotifier {
  int _currentStreak = 12; // Default value
  static const String _streakKey = 'current_streak';
  static const String _lastActivityDateKey = 'last_activity_date';

  int get currentStreak => _currentStreak;

  StreakProvider() {
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStreak = prefs.getInt(_streakKey) ?? 12;
    
    // Check if streak should be reset (if last activity was not yesterday or today)
    final String? lastActivityDate = prefs.getString(_lastActivityDateKey);
    final String today = DateTime.now().toIso8601String().split('T')[0];
    
    if (lastActivityDate != null && lastActivityDate != today) {
      final lastDate = DateTime.parse(lastActivityDate);
      final todayDate = DateTime.parse(today);
      final daysDifference = todayDate.difference(lastDate).inDays;
      
      // If more than 1 day has passed, reset streak
      if (daysDifference > 1) {
        _currentStreak = 0;
        await prefs.setInt(_streakKey, 0);
      }
    }
    
    notifyListeners();
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final String? lastActivityDate = prefs.getString(_lastActivityDateKey);
    
    if (lastActivityDate == today) {
      // Already updated today, don't increment
      return;
    }
    
    if (lastActivityDate != null) {
      final lastDate = DateTime.parse(lastActivityDate);
      final todayDate = DateTime.parse(today);
      final daysDifference = todayDate.difference(lastDate).inDays;
      
      if (daysDifference == 1) {
        // Consecutive day - increment streak
        _currentStreak++;
      } else if (daysDifference > 1) {
        // Streak broken - reset to 1
        _currentStreak = 1;
      }
      // If daysDifference == 0, it's the same day, do nothing
    } else {
      // First time - start streak at 1
      _currentStreak = 1;
    }
    
    await prefs.setInt(_streakKey, _currentStreak);
    await prefs.setString(_lastActivityDateKey, today);
    notifyListeners();
  }

  Future<void> setStreak(int streak) async {
    _currentStreak = streak;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakKey, streak);
    final String today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString(_lastActivityDateKey, today);
    notifyListeners();
  }
}

