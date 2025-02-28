import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:navsu/backend/backend_service.dart';
import 'package:navsu/models/reward.dart';
import 'package:navsu/models/redemption.dart';
import 'package:navsu/cache/points_cache.dart';
import 'package:navsu/ui/components/reward_card.dart';
import 'package:navsu/ui/components/redemption_history_item.dart';
import 'package:navsu/ui/dialog/reward_redemption_dialog.dart';
import 'package:navsu/ui/components/empty_state.dart';
import 'dart:async';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Backend _backend = Backend();
  final PointsCache _pointsCache = PointsCache();
  int _userPoints = 0;
  bool _isLoading = true;
  bool _isProcessing = false;
  List<Reward> _rewards = [];
  List<Redemption> _redemptions = [];
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initial load of user points (will be quick from cache)
    _loadUserPoints();
    
    // Start real-time listener for user data updates
    _startUserDataListener();
    
    // Load other data
    _loadRewards();
    _loadRedemptionHistory();
  }

  @override
  void dispose() {
    // Cancel the stream subscription
    _userDataSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startUserDataListener() {
    final userStream = _backend.getUserDataStream();
    
    if (userStream == null) {
      debugPrint('Could not get user data stream. User might not be logged in.');
      return;
    }
    
    _userDataSubscription = userStream.listen((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>?;
        if (userData != null) {
          // Extract points from user data
          final int points = userData['points'] is int ? 
              userData['points'] : 
              int.tryParse(userData['points'].toString()) ?? 0;
          
          // Update points cache
          _pointsCache.updatePoints(points);
          
          // Update UI if mounted
          if (mounted) {
            setState(() {
              _userPoints = points;
            });
            debugPrint('Real-time points update: $_userPoints');
          }
        }
      }
    }, onError: (error) {
      debugPrint('Error in user data stream: $error');
    });
  }

  Future<void> _loadUserPoints() async {
    setState(() => _isLoading = true);
    
    try {
      // First try to get from cache for immediate display
      final cachedPoints = await _pointsCache.getPoints();
      if (mounted) {
        setState(() {
          _userPoints = cachedPoints;
          _isLoading = false;
        });
      }
      
      // Then get fresh data from backend
      final userData = await _backend.getUserData();
      if (userData != null && mounted) {
        final int points = userData['points'] is int ? 
            userData['points'] : 
            int.tryParse(userData['points'].toString()) ?? 0;
            
        // Update the UI with the most current data
        setState(() {
          _userPoints = points;
        });
        
        // Update cache if different
        if (points != cachedPoints) {
          await _pointsCache.updatePoints(points);
        }
      }
    } catch (e) {
      debugPrint('Error loading user points: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRewards() async {
    try {
      final rewardsData = await _backend.getAvailableRewards();
      final rewards = rewardsData.map((data) => Reward.fromMap(data)).toList();
      
      setState(() {
        _rewards = rewards;
      });
    } catch (e) {
      debugPrint('Error loading rewards: $e');
      _showErrorSnackBar('Failed to load rewards');
    }
  }

  Future<void> _loadRedemptionHistory() async {
    try {
      final redemptionData = await _backend.getUserRedemptionHistory();
      final redemptions = redemptionData.map((data) => Redemption.fromMap(data)).toList();
      
      setState(() {
        _redemptions = redemptions;
      });
    } catch (e) {
      debugPrint('Error loading redemption history: $e');
      _showErrorSnackBar('Failed to load redemption history');
    }
  }

  Future<void> _redeemReward(Reward reward) async {
    // Basic validation
    if (_userPoints < reward.points) {
      _showInsufficientPointsDialog();
      return;
    }

    // Check if already processing
    if (_isProcessing) return;

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => RewardRedemptionDialog(
        rewardName: reward.name,
        rewardPoints: reward.points,
        rewardImage: reward.photoUrl,
        userPoints: _userPoints,
      ),
    );

    // Return if user canceled
    if (confirmed != true) return;

    // Start processing
    setState(() => _isProcessing = true);

    try {
      // Perform redemption
      final success = await _backend.redeemReward(reward.id);
      
      if (!mounted) return;

      if (success) {
        // Update local state
        setState(() {
          _userPoints -= reward.points;
        });
        
        // Update cache
        await _pointsCache.updatePoints(_userPoints);
        
        // Reload data
        await _loadRewards();
        await _loadRedemptionHistory();
        
        // Show success message
        _showSuccessSnackBar('Successfully redeemed ${reward.name}');
      } else {
        _showErrorSnackBar('Failed to redeem reward');
      }
    } catch (e) {
      debugPrint('Error redeeming reward: $e');
      _showErrorSnackBar('Error processing redemption');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showInsufficientPointsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Points'),
        content: const Text('You don\'t have enough points to redeem this reward.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine if the device is in a portrait orientation or very narrow
          final isNarrow = constraints.maxWidth < 400;
          
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.yellow.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(isNarrow),
                  _buildTabs(),
                  if (_isProcessing)
                    LinearProgressIndicator(
                      backgroundColor: Colors.yellow.shade100,
                      color: Colors.yellow.shade400,
                    ),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildAvailableRewardsTab(constraints),
                              _buildRedemptionHistoryTab(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 8 : 16, 
        vertical: isNarrow ? 8 : 16
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: isNarrow ? 20 : 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rewards',
              style: TextStyle(
                fontSize: isNarrow ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.yellow.shade700,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildPointsDisplay(),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(
          text: MediaQuery.of(context).size.width < 360 
              ? 'Rewards'
              : 'Available Rewards',
        ),
        Tab(
          text: MediaQuery.of(context).size.width < 360 
              ? 'History'
              : 'Redemption History',
        ),
      ],
      labelColor: Colors.yellow.shade700,
      unselectedLabelColor: Colors.grey,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
      indicatorColor: Colors.yellow.shade700,
      indicatorWeight: 3,
    );
  }

  Widget _buildPointsDisplay() {
    final bool isCompact = MediaQuery.of(context).size.width < 360;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: isCompact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            NumberFormat.decimalPattern().format(_userPoints),
            style: TextStyle(
              fontSize: isCompact ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableRewardsTab(BoxConstraints constraints) {
    if (_rewards.isEmpty) {
      return const EmptyState(
        icon: Icons.card_giftcard,
        message: 'No rewards available at the moment',
      );
    }

    // More fine-tuned responsive grid
    final width = constraints.maxWidth;
    
    // Calculate columns and aspect ratio based on width
    final crossAxisCount = width < 300 ? 1 : 
                          width < 500 ? 2 : 
                          width < 700 ? 3 : 
                          width < 900 ? 4 : 5;
    
    // Fixed aspect ratio values for different screen sizes
    // Make cards taller to avoid content overflow
    final childAspectRatio = width < 300 ? 1.0 :    // More space for single column
                            width < 500 ? 0.65 :   // Taller for small phones
                            width < 700 ? 0.7 :    // Standard for tablets/larger phones
                            0.75;                  // Wider for larger screens
    
    return RefreshIndicator(
      onRefresh: () async {
        await _loadRewards();
        await _loadUserPoints();
      },
      color: Colors.yellow,
      child: GridView.builder(
        padding: EdgeInsets.all(width < 300 ? 8 : 12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: width < 300 ? 8 : 12,
          mainAxisSpacing: width < 300 ? 8 : 12,
        ),
        itemCount: _rewards.length,
        itemBuilder: (context, index) {
          final reward = _rewards[index];
          final bool canAfford = _userPoints >= reward.points;
          
          return RewardCard(
            reward: reward,
            canAfford: canAfford,
            onTap: () => _redeemReward(reward),
          );
        },
      ),
    );
  }

  Widget _buildRedemptionHistoryTab() {
    if (_redemptions.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        message: 'No redemption history yet',
      );
    }

    final bool isNarrowScreen = MediaQuery.of(context).size.width < 360;
    final bool isVeryNarrow = MediaQuery.of(context).size.width < 280;

    return RefreshIndicator(
      onRefresh: _loadRedemptionHistory,
      color: Colors.yellow,
      child: ListView.builder(
        // Reduce padding for the overall list
        padding: EdgeInsets.all(isVeryNarrow ? 6 : isNarrowScreen ? 8 : 12),
        // Remove fixed itemExtent to allow items to size themselves naturally
        itemCount: _redemptions.length,
        itemBuilder: (context, index) {
          final redemption = _redemptions[index];
          return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: RedemptionHistoryItem(
          redemption: redemption,
          isCompact: isNarrowScreen,
        ),
          );
        },
      ),
    );
  }
}
