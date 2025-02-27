import 'package:flutter/material.dart';
import 'package:kescon_app/backend/backend.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kescon_app/cache/points_cache.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({super.key});

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  final Backend _backend = Backend();
  final PointsCache _cache = PointsCache();
  List<TeamPoints> _teamPoints = [];
  bool _isLoading = true;
  bool _teamsRevealed = false;

  @override
  void initState() {
    super.initState();
    _loadPoints();
    _loadTeamRevealState();
  }

  Future<void> _loadTeamRevealState() async {
    final revealed = await _backend.getTeamRevealState();
    if (mounted) {
      setState(() {
        _teamsRevealed = revealed;
      });
    }
  }

  Future<void> _loadPoints() async {
    setState(() => _isLoading = true);

    // Try to get data from cache first
    final cachedPoints = _cache.getCachedPoints();
    if (cachedPoints != null) {
      setState(() {
        _teamPoints = cachedPoints;
        _isLoading = false;
      });
      return;
    }

    // If no cache, fetch from backend
    await _fetchTeamPoints();
  }

  Future<void> _fetchTeamPoints() async {
    try {
      List<Team> teams = await _backend.getAllTeams();
      List<TeamPoints> points = [];

      // First, collect all team points
      for (var team in teams) {
        List<Point> teamPoints = await _backend.getPointsForTeam(team.teamName);
        points.add(TeamPoints(
          team: team,
          totalPoints: teamPoints.isEmpty ? 0 : teamPoints.fold(0, (sum, point) => sum + point.points),
          rank: 0,
        ));
      }

      // Sort teams by points in descending order
      points.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

      // Updated rank assignment logic
      if (points.isNotEmpty) {
        points[0].rank = 1;
        int prevRank = 1;
        for (int i = 1; i < points.length; i++) {
          if (points[i].totalPoints == points[i - 1].totalPoints) {
            points[i].rank = prevRank;
          } else {
            points[i].rank = prevRank + 1;
            prevRank++;
          }
        }
      }

      // Update cache and state
      _cache.updateCache(points);
      setState(() {
        _teamPoints = points;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching team points: $e');
      setState(() => _isLoading = false);
    }
  }

  // Override dispose to optionally clear cache when leaving the page
  @override
  void dispose() {
    // Uncomment if you want to clear cache when leaving the page
    // _cache.clearCache();
    super.dispose();
  }

  // Modify the refresh indicator to clear cache and fetch new data
  Future<void> _refreshPoints() async {
    _cache.clearCache();
    await _fetchTeamPoints();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildShimmer()
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  // Header with back button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey[200],
                            ),
                            child: const Icon(Icons.arrow_back),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Team Rankings',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40), // Balance the header
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Podium for top 3 teams
                  if (_teamPoints.length >= 3) ...[
                    SizedBox(
                      height: 220, // Increased from 175 to 220
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Second place
                          _buildPodiumItem(_teamPoints[1], 2, size.width * 0.25, 180), // Increased from 160
                          const SizedBox(width: 10),
                          // First place
                          _buildPodiumItem(_teamPoints[0], 1, size.width * 0.25, 220), // Increased from 200
                          const SizedBox(width: 10),
                          // Third place
                          _buildPodiumItem(_teamPoints[2], 3, size.width * 0.25, 140), // Increased from 120
                        ],
                      ),
                    ),
                  ],
                  // Remaining teams
                  if (_teamPoints.length > 3) ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _teamPoints.length - 3,
                      itemBuilder: (context, index) {
                        final teamPoint = _teamPoints[index + 3];
                        return _buildTeamListItem(teamPoint, index + 4);
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          // Shimmer for podium
          SizedBox(
            height: 290,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPodiumShimmer(160),
                const SizedBox(width: 10),
                _buildPodiumShimmer(200),
                const SizedBox(width: 10),
                _buildPodiumShimmer(120),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Shimmer for list items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (_, __) => _buildListItemShimmer(),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumShimmer(double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.25,
          height: 50,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.25,
          height: height * 0.4,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildListItemShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 20,
              color: Colors.white,
            ),
          ),
          Container(
            width: 60,
            height: 20,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(TeamPoints teamPoints, int position, double width, double height) {
    Color podiumColor = position == 1
        ? Colors.amber
        : position == 2
            ? Colors.grey[300]!
            : Colors.brown[300]!;

    Color teamColor = _teamsRevealed 
        ? hexToColor(teamPoints.team.color)
        : Colors.grey;
        
    String displayName = _teamsRevealed 
        ? teamPoints.team.teamName
        : teamPoints.team.secretName;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (position == 1) ...[
          Image.asset(
            'assets/images/crown.png',
            width: 25,
            height: 25,
          ),
        ],
        Container(
          width: width,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: teamColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: teamColor,
                ),
              ),
              Text(
                NumberFormat('#,###').format(teamPoints.totalPoints),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: width,
          height: height * 0.45, // Increased from 0.35 to 0.45
          decoration: BoxDecoration(
            color: podiumColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Center(
            child: Text(
              '$position',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamListItem(TeamPoints teamPoints, int position) {
    Color teamColor = _teamsRevealed 
        ? hexToColor(teamPoints.team.color)
        : Colors.grey;
        
    String displayName = _teamsRevealed 
        ? teamPoints.team.teamName
        : teamPoints.team.secretName;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: teamColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${teamPoints.rank}', // Use the rank instead of position
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: teamColor,
              ),
            ),
          ),
          Text(
            NumberFormat('#,###').format(teamPoints.totalPoints),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class TeamPoints {
  final Team team;
  final int totalPoints;
  int rank; // Add rank property

  TeamPoints({
    required this.team,
    required this.totalPoints,
    this.rank = 0,
  });
}

Color hexToColor(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.parse('0x$hexColor'));
}
