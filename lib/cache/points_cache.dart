import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Class for caching and managing user point data locally
class PointsCache {
  // Singleton pattern
  static final PointsCache _instance = PointsCache._internal();
  factory PointsCache() => _instance;
  PointsCache._internal();
  
  // Keys for SharedPreferences
  static const String _pointsKey = 'user_points';
  static const String _distanceKey = 'user_distance';
  static const String _lastUpdateKey = 'points_last_update';
  static const String _pointsHistoryKey = 'points_history';
  
  // Cache max age (6 hours in milliseconds)
  static const int _cacheMaxAge = 6 * 60 * 60 * 1000;
  
  /// Get cached points
  Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }
  
  /// Get cached distance
  Future<double> getDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_distanceKey) ?? 0.0;
  }
  
  /// Update points in cache
  Future<void> updatePoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsKey, points);
    await _updateTimestamp();
  }
  
  /// Update distance in cache
  Future<void> updateDistance(double distance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_distanceKey, distance);
    await _updateTimestamp();
  }
  
  /// Add points and update cache
  Future<void> addPoints(int pointsToAdd) async {
    final prefs = await SharedPreferences.getInstance();
    final currentPoints = prefs.getInt(_pointsKey) ?? 0;
    await prefs.setInt(_pointsKey, currentPoints + pointsToAdd);
    await _updateTimestamp();
    
    // Record in history
    await _addToHistory(pointsToAdd, 0.0);
  }
  
  /// Add distance and update cache
  Future<void> addDistance(double distanceToAdd) async {
    final prefs = await SharedPreferences.getInstance();
    final currentDistance = prefs.getDouble(_distanceKey) ?? 0.0;
    await prefs.setDouble(_distanceKey, currentDistance + distanceToAdd);
    await _updateTimestamp();
  }
  
  /// Add both points and distance together
  Future<void> addPointsAndDistance(int pointsToAdd, double distanceToAdd) async {
    final prefs = await SharedPreferences.getInstance();
    
    final currentPoints = prefs.getInt(_pointsKey) ?? 0;
    final currentDistance = prefs.getDouble(_distanceKey) ?? 0.0;
    
    await prefs.setInt(_pointsKey, currentPoints + pointsToAdd);
    await prefs.setDouble(_distanceKey, currentDistance + distanceToAdd);
    await _updateTimestamp();
    
    // Record in history
    await _addToHistory(pointsToAdd, distanceToAdd);
  }
  
  /// Add points record to history
  Future<void> _addToHistory(int points, double distance) async {
    final prefs = await SharedPreferences.getInstance();
    
    List<Map<String, dynamic>> history = [];
    final historyString = prefs.getString(_pointsHistoryKey);
    
    if (historyString != null) {
      final List<dynamic> decoded = jsonDecode(historyString);
      history = decoded.cast<Map<String, dynamic>>();
    }
    
    // Add new entry
    history.add({
      'points': points,
      'distance': distance,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Keep only last 50 entries
    if (history.length > 50) {
      history = history.sublist(history.length - 50);
    }
    
    // Save history
    await prefs.setString(_pointsHistoryKey, jsonEncode(history));
  }
  
  /// Get points history
  Future<List<Map<String, dynamic>>> getPointsHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_pointsHistoryKey);
    
    if (historyString != null) {
      final List<dynamic> decoded = jsonDecode(historyString);
      return decoded.cast<Map<String, dynamic>>();
    }
    
    return [];
  }
  
  /// Check if cache is fresh (less than max age)
  Future<bool> isCacheFresh() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    
    if (lastUpdate == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastUpdate) < _cacheMaxAge;
  }
  
  /// Update timestamp in cache
  Future<void> _updateTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  /// Clear all cached data
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pointsKey);
    await prefs.remove(_distanceKey);
    await prefs.remove(_lastUpdateKey);
    await prefs.remove(_pointsHistoryKey);
  }
  
  /// Get combined user stats
  Future<Map<String, dynamic>> getUserStats() async {
    final points = await getPoints();
    final distance = await getDistance();
    final isFresh = await isCacheFresh();
    
    return {
      'points': points,
      'distance': distance,
      'isFresh': isFresh,
      'lastUpdate': await _getLastUpdateTime(),
    };
  }
  
  /// Get formatted last update time
  Future<String?> _getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    
    if (lastUpdate == null) return null;
    
    final datetime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    return '${datetime.hour}:${datetime.minute.toString().padLeft(2, '0')}';
  }
}
