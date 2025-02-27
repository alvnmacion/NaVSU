import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<UserDistanceData> _topUsers = [];
  UserDistanceData? _currentUserData;
  bool _isLoading = true;
  String? _currentUserId;
  int _currentUserRank = 0;
  
  @override
  void initState() {
    super.initState();
    _loadLeaderboardData();
  }
  
  Future<void> _loadLeaderboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user ID
      _currentUserId = _auth.currentUser?.uid;
      
      // Fetch top users sorted by distance
      final snapshot = await _firestore
          .collection('users')
          .orderBy('distance', descending: true)
          .limit(20) // Increased limit to ensure we have enough data
          .get();
          
      List<UserDistanceData> users = [];
      
      // First pass: collect all user data
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userId = doc.id;
        final userName = data['name'] ?? 'User';
        double distance = 0.0;
        
        // Handle different types of distance field
        if (data['distance'] != null) {
          if (data['distance'] is double) {
            distance = data['distance'];
          } else if (data['distance'] is int) {
            distance = (data['distance'] as int).toDouble();
          } else {
            distance = double.tryParse(data['distance'].toString()) ?? 0.0;
          }
        }
        
        users.add(UserDistanceData(
          userId: userId,
          name: userName,
          photoUrl: data['photoUrl'],
          distance: distance,
          points: data['points'] ?? 0,
          rank: 0, // Temporary rank
        ));
      }
      
      // Second pass: assign ranks properly
      if (users.isNotEmpty) {
        // Sort users by distance in descending order to ensure proper ranking
        users.sort((a, b) => b.distance.compareTo(a.distance));
        
        // Assign first rank
        users[0].rank = 1;
        
        // Assign remaining ranks
        for (int i = 1; i < users.length; i++) {
          if (users[i].distance == users[i-1].distance) {
            // If this user has the same distance as the previous user, give the same rank
            users[i].rank = users[i-1].rank;
          } else {
            // Otherwise, rank is the position + 1 (ranks start at 1)
            users[i].rank = i + 1;
          }
        }
      }
      
      // Find current user data in the fetched list
      _currentUserData = users.firstWhere(
        (user) => user.userId == _currentUserId,
        orElse: () => null as UserDistanceData,
      );
      
      // If current user not in top users, fetch them separately
      if (_currentUserId != null && _currentUserData == null) {
        await _fetchCurrentUserData(users);
      } else if (_currentUserData != null) {
        _currentUserRank = _currentUserData!.rank;
      }
      
      // Take only top 10 for display
      if (users.length > 10) {
        users = users.sublist(0, 10);
      }
      
      setState(() {
        _topUsers = users;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading leaderboard data: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _fetchCurrentUserData(List<UserDistanceData> existingUsers) async {
    try {
      // Get user document
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      if (!userDoc.exists) return;
      
      final data = userDoc.data()!;
      double userDistance = 0.0;
      
      // Handle different types of distance field
      if (data['distance'] != null) {
        if (data['distance'] is double) {
          userDistance = data['distance'];
        } else if (data['distance'] is int) {
          userDistance = (data['distance'] as int).toDouble();
        } else {
          userDistance = double.tryParse(data['distance'].toString()) ?? 0.0;
        }
      }
      
      // More accurate rank calculation by getting all users with greater distance
      final usersAboveSnapshot = await _firestore
          .collection('users')
          .where('distance', isGreaterThan: userDistance)
          .get();
      
      // Also get users with equal distance to handle ties
      final usersTiedSnapshot = await _firestore
          .collection('users')
          .where('distance', isEqualTo: userDistance)
          .get();
      
      // The number of users with strictly greater distance
      int usersAbove = usersAboveSnapshot.docs.length;
      
      // Calculate rank (ranks start at 1)
      int userRank = usersAbove + 1;
      
      // Create user data
      _currentUserData = UserDistanceData(
        userId: _currentUserId!,
        name: data['name'] ?? 'You',
        photoUrl: data['photoUrl'],
        distance: userDistance,
        points: data['points'] ?? 0,
        rank: userRank,
      );
      
      _currentUserRank = userRank;
    } catch (e) {
      print('Error fetching current user data: $e');
    }
  }
  
  Future<void> _refreshData() async {
    await _loadLeaderboardData();
  }
  
  String _formatNumber(num number) {
    return NumberFormat.decimalPattern().format(number);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: _isLoading ? _buildLoadingView() : _buildLeaderboardView(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading leaderboard...',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLeaderboardView() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // App Bar
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.green.shade700,
          elevation: 0,
          expandedHeight: 20,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: FlexibleSpaceBar(
                title: Text(
                  'Distance Leaderboard',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
        
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Podium section
                if (_topUsers.length >= 3) ...[
                  _buildPodiumSection(),
                  const SizedBox(height: 32),
                ],
                
                // Rest of top 10
                _buildRestOfTopTenSection(),
                const SizedBox(height: 32),
                
                // Current user section
                _buildCurrentUserSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPodiumSection() {
    // Get screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    
    // More responsive widths based on screen size
    final podiumItemWidth = screenWidth * 0.28;
    final spacing = screenWidth * 0.02;
    
    // Dynamic heights for podium steps
    final firstPlaceHeight = screenWidth * 0.35;
    final secondPlaceHeight = screenWidth * 0.28;
    final thirdPlaceHeight = screenWidth * 0.25;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: firstPlaceHeight + 180, // Increased height for floating profiles
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Top Travelers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
          
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // User avatars - positioned to float above podiums
                Positioned(
                  bottom: firstPlaceHeight + 20, // Position above the highest podium
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2nd place profile
                      _buildFloatingAvatar(_topUsers[1]),
                      
                      SizedBox(width: podiumItemWidth * 0.45),
                      
                      // 1st place profile
                      _buildFloatingAvatar(_topUsers[0], isFirst: true),
                      
                      SizedBox(width: podiumItemWidth * 0.45),
                      
                      // 3rd place profile
                      _buildFloatingAvatar(_topUsers[2]),
                    ],
                  ),
                ),
                
                // Podium platforms with ranks and name/distance
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Second place podium
                      _buildPodiumStep(
                        2, 
                        _topUsers[1].name,
                        _topUsers[1].distance, 
                        podiumItemWidth, 
                        secondPlaceHeight,
                        Colors.grey.shade300,
                        Colors.grey.shade800
                      ),
                      
                      SizedBox(width: spacing),
                      
                      // First place podium
                      _buildPodiumStep(
                        1, 
                        _topUsers[0].name,
                        _topUsers[0].distance, 
                        podiumItemWidth, 
                        firstPlaceHeight,
                        Colors.amber.shade300,
                        Colors.amber.shade800
                      ),
                      
                      SizedBox(width: spacing),
                      
                      // Third place podium
                      _buildPodiumStep(
                        3, 
                        _topUsers[2].name,
                        _topUsers[2].distance, 
                        podiumItemWidth, 
                        thirdPlaceHeight,
                        Colors.brown.shade300,
                        Colors.brown.shade700
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method for building floating avatars above podium
  Widget _buildFloatingAvatar(UserDistanceData user, {bool isFirst = false}) {
    return Column(
      children: [
        if (isFirst)
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 20,
            ),
          ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Icon(Icons.person, size: 32, color: Colors.green.shade700)
                : null,
          ),
        ),
      ],
    );
  }
  
  // Helper method for building podium steps with name and distance
  Widget _buildPodiumStep(int rank, String name, double distance, double width, double height, Color color, Color textColor) {
    return Container(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Podium platform
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rank number
                Text(
                  '$rank',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                
                // User name with fitted box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                // Distance
                Text(
                  '${_formatNumber(distance)} km',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRestOfTopTenSection() {
    // Skip the top 3 and show the rest
    final restOfTopTen = _topUsers.length > 3 ? _topUsers.sublist(3) : [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Rest of Top ${_topUsers.length}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: restOfTopTen.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final user = restOfTopTen[index];
                return _buildUserListItem(user);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUserListItem(UserDistanceData user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // Rank
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${user.rank}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // User avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green.shade50,
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Icon(Icons.person, size: 18, color: Colors.green.shade700)
                : null,
          ),
          const SizedBox(width: 12),
          
          // User name
          Expanded(
            child: Text(
              user.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Distance
          Text(
            '${_formatNumber(user.distance)} km',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCurrentUserSection() {
    if (_currentUserData == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your Ranking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // User avatar and rank
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          backgroundImage: _currentUserData!.photoUrl != null 
                              ? NetworkImage(_currentUserData!.photoUrl!) 
                              : null,
                          child: _currentUserData!.photoUrl == null
                              ? Icon(Icons.person, size: 24, color: Colors.green.shade700)
                              : null,
                        ),
                        Positioned(
                          bottom: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.green.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(
                              '#${_currentUserData!.rank}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // User name and distance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUserData!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatNumber(_currentUserData!.distance)} km traveled',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Points display
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatNumber(_currentUserData!.points),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class UserDistanceData {
  final String userId;
  final String name;
  final String? photoUrl;
  final double distance;
  final int points;
  int rank;
  
  UserDistanceData({
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.distance,
    required this.points,
    required this.rank,
  });
}
