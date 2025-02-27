import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:navsu/ui/screens/map_screen/components/loading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Components
import 'package:navsu/ui/screens/map_screen/components/current_location_marker.dart';
import 'package:navsu/ui/screens/map_screen/components/search_bar.dart';
import 'package:navsu/ui/screens/map_screen/components/bottom_info.dart';
import 'package:navsu/ui/screens/map_screen/components/search_results.dart'; // Add import at the top
// Dialogs
import 'package:navsu/ui/dialog/landmark_details_dialog.dart';
import 'package:navsu/ui/dialog/add_landmark_dialog.dart';
import 'package:navsu/ui/dialog/arrival_dialog.dart';
import 'package:navsu/ui/dialog/cancel_navigation_dialog.dart';
// Services
import 'package:navsu/backend/firebaseauth.dart';
import 'package:navsu/ui/screens/signin_page.dart';
import 'package:navsu/backend/points_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  List<LatLng> _routePoints = [];
  final TextEditingController _searchController = TextEditingController();
  double _zoom = 15.0;
  final List<Marker> _landmarkMarkers = [];
  final Map<LatLng, dynamic> _landmarkData = {};
  List<Map<String, dynamic>> _searchResults = [];
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final MapController _mapController = MapController(); // Initialize MapController
  String? _selectedLandmarkName;
  double _compassRotation = 0;
  bool _isNavigating = false;
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _mapRotation = 0;
  Timer? _rotationTimer;
  double _bearing = 0.0;
  Timer? _recenterTimer;
  double _lastHeading = 0.0;
  static const double _rotationThreshold = 5.0; // Minimum rotation change to update
  static const Duration _recenterInterval = Duration(seconds: 3);
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _flashlightAnimationController;
  late Animation<double> _flashlightAnimation;
  String? _destinationName;
  bool _hasShownArrivalDialog = false;
  String _walkingEta = '';
  String _drivingEta = '';
  String _distance = '';
  String? _userPhotoUrl;
  String? _userName;
  String? _userPoints; // Add this property
  bool _isMenuOpen = false;
  final LayerLink _menuLayerLink = LayerLink();
  OverlayEntry? _menuOverlay;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<Position>? _locationStream;
  bool _isLocationReady = false;
  StreamSubscription<Position>? _navigationStream;

  // Add these new properties for distance tracking
  final PointsService _pointsService = PointsService();
  LatLng? _lastRecordedLocation;
  double _totalDistanceTraveled = 0.0;
  
  // Minimum distance between points to consider for distance calculation (meters)
  static const double _minDistanceThreshold = 5.0;
  
  // How often to save points to Firebase (in meters)
  static const double _pointSaveThreshold = 100.0;

  Timer? _arrivalCheckTimer;
  int _pointsEarnedThisTrip = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeLocation(); // Replace _getCurrentLocation() with this
    _fetchLandmarks();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _startCompassUpdates();
    _loadUserDetails();
    _setupPointsTracking();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final points = prefs.getInt('points') ?? 0;
    setState(() {
      _userPhotoUrl = prefs.getString('photoUrl');
      _userName = prefs.getString('name');
      _userPoints = _formatNumber(points);
    });
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _toggleMenu() {
    if (_menuOverlay == null) {
      _showMenu();
    } else {
      _hideMenu();
    }
  }

  void _showMenu() {
    _menuOverlay = _createMenuOverlay();
    Overlay.of(context).insert(_menuOverlay!);
    setState(() => _isMenuOpen = true);
  }

  void _hideMenu() {
    _menuOverlay?.remove();
    _menuOverlay = null;
    setState(() => _isMenuOpen = false);
  }

  Future<void> _handleLogout() async {
    try {
      _hideMenu();
      await FirebaseAuthService().signOut();
      
      if (!mounted) return;

      // Use pushAndRemoveUntil to clear the navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const SignIn(),
        ),
        (route) => false, // This will remove all previous routes
      );
    } catch (e) {
      print('Logout error: $e');
      // Still try to navigate to SignIn even if there's an error
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const SignIn(),
        ),
        (route) => false,
      );
    }
  }

  OverlayEntry _createMenuOverlay() {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: 110,
        right: 16,
        width: 250,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: _userPhotoUrl != null
                                ? NetworkImage(_userPhotoUrl!)
                                : null,
                            child: _userPhotoUrl == null
                                ? const Icon(Icons.person, size: 24)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'VSU Student',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade500,
                              Colors.green.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.amber,
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _userPoints ?? '0',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Navigation Points',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setupAnimations() {
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _flashlightAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _flashlightAnimation = Tween<double>(begin: 0.5, end: 0.9).animate( // Increased animation range
      CurvedAnimation(
        parent: _flashlightAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initializeLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Get initial location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLocationReady = true;
        });
      }

      // Start location updates
      _locationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            if (!_isNavigating) {
              _mapController.move(_currentLocation!, _zoom);
            }
          });
        }
      });
    } catch (e) {
      print('Location initialization error: $e');
    }
  }

  @override
  void dispose() {
    _locationStream?.cancel();
    _navigationStream?.cancel();
    // Cancel all subscriptions and timers
    _pulseAnimationController.dispose();
    _flashlightAnimationController.dispose();
    _recenterTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _overlayEntry?.dispose();
    _menuOverlay?.remove();
    _mapController.dispose(); // Dispose MapController
    _compassSubscription?.cancel(); // Cancel compass subscription
    // Save any remaining distance points before disposing
    if (_totalDistanceTraveled > 0) {
      _pointsService.recordDistanceTraveled(_totalDistanceTraveled);
    }
    _arrivalCheckTimer?.cancel();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    if (_overlayEntry != null) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _searchLandmarks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      _hideOverlay(); // Hide overlay when query is empty
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('landmarks')
          .where('status', isEqualTo: 'approved')
          .get();

      List<Map<String, dynamic>> results = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        _searchResults = results.where((landmark) =>
            landmark['name'].toLowerCase().contains(query.toLowerCase())).toList();
        print('Search Results: $_searchResults'); // Print search results
      });

      if (_searchResults.isNotEmpty && _searchFocusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    } catch (e) {
      print('Error searching landmarks: $e');
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      return OverlayEntry(builder: (context) => const SizedBox.shrink());
    }

    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 16,
        top: offset.dy + 60,
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 50),
          child: Material(
            elevation: 0.0,
            color: Colors.white,
            borderRadius: BorderRadius.circular(0),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                print('Building list item for: ${_searchResults[index]['name']}'); // Print each item being built
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(_searchResults[index]['name']),
                  onTap: () {
                    _focusOnLandmark(_searchResults[index]);
                    _searchFocusNode.unfocus();
                    _hideOverlay();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _focusOnLandmark(Map<String, dynamic> landmark) async {
    final GeoPoint point = landmark['location'] as GeoPoint;
    final LatLng landmarkLocation = LatLng(point.latitude, point.longitude);

    setState(() {
      _destinationLocation = null;
      _selectedLandmarkName = landmark['name'];
    });

    _mapController.move(landmarkLocation, 18.49);
    _zoom = 18.49;
    _fetchLandmarks(); // Refresh landmarks to update marker color
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, handle accordingly.
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle accordingly.
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _getRoute() async {
    if (_currentLocation == null || _destinationLocation == null) return;

    // Cancel any existing navigation stream
    await _navigationStream?.cancel();

    setState(() {
      _isNavigating = true;
      _bearing = 0.0;
      _lastHeading = 0.0;
    });

    try {
      const String apiKey = '5b3ce3597851110001cf62483eb0593105fd4f87b3f72ee4aaedca67';
      final String url =
          'https://api.openrouteservice.org/v2/directions/foot-walking?api_key=$apiKey&start=${_currentLocation!.longitude},${_currentLocation!.latitude}&end=${_destinationLocation!.longitude},${_destinationLocation!.latitude}';

      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> coordinates = data['features'][0]['geometry']['coordinates'];
        final double durationSeconds = data['features'][0]['properties']['segments'][0]['duration'];
        final double distanceKm = data['features'][0]['properties']['segments'][0]['distance'] / 1000;
        
        setState(() {
          _routePoints = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
          _zoom = 18.49;
          
          // Update ETAs
          final walkingTotalSeconds = durationSeconds.round();
          final walkingMinutes = walkingTotalSeconds ~/ 60;
          final walkingSeconds = walkingTotalSeconds % 60;
          _walkingEta = '${walkingMinutes}min ${walkingSeconds.toString().padLeft(2, '0')}s';
          
          final drivingTotalSeconds = (durationSeconds / 3).round();
          final drivingMinutes = drivingTotalSeconds ~/ 60;
          final drivingSeconds = drivingTotalSeconds % 60;
          _drivingEta = '${drivingMinutes}min ${drivingSeconds.toString().padLeft(2, '0')}s';
          
          _distance = '${distanceKm.toStringAsFixed(2)} km';
        });

        _mapController.move(_currentLocation!, _zoom);
        _startNavigationUpdates();
      }
    } catch (e) {
      print('Route calculation error: $e');
      setState(() {
        _isNavigating = false;
      });
    }
  }

  void _startNavigationUpdates() {
    if (!_isNavigating) return;
    
    // Cancel previous timers
    _arrivalCheckTimer?.cancel();

    _navigationStream?.cancel();
    _navigationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      if (!mounted || !_isNavigating) return;

      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = newLocation;
        _mapController.moveAndRotate(_currentLocation!, _zoom, _bearing);
      });
      
      // Call _checkArrival directly
      _checkArrival();
    });

    // Set last recorded location to current at start of navigation
    _lastRecordedLocation = _currentLocation;
    
    // Initial arrival check
    _checkArrival();
    
    // Add a dedicated timer for arrival checking with reduced frequency (since _checkArrival is now async)
    _arrivalCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isNavigating && !_hasShownArrivalDialog) {
        _checkArrival();
      }
    });
  }

  void _startCompassUpdates() {
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading != null) {
        double newHeading = event.heading!;
        
        // Normalize heading to 0-360 range
        while (newHeading < 0) newHeading += 360;
        while (newHeading >= 360) newHeading -= 360;
        
        if ((_lastHeading - newHeading).abs() > _rotationThreshold) {
          setState(() {
            _compassRotation = newHeading;
            if (_isNavigating) {
              _bearing = -newHeading;
              _mapRotation = newHeading;
              _mapController.rotate(_bearing);
            }
            _lastHeading = newHeading;
          });
        }
      }
    });
  }

  Future<void> _fetchLandmarks() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('landmarks')
          .where('status', isEqualTo: 'approved')
          .get();

      _landmarkMarkers.clear();
      _landmarkData.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final GeoPoint point = data['location'] as GeoPoint;
        final LatLng location = LatLng(point.latitude, point.longitude);
        final isSelected = _selectedLandmarkName == data['name'];

        _landmarkData[location] = data;

        _landmarkMarkers.add(
          Marker(
            width: 40.0,
            height: 40.0,
            point: location,
            child: GestureDetector(
              onTap: () {
                _showLandmarkDetailsDialog(data, location);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.yellow : Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.circle_sharp,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      setState(() {});
    } catch (e) {
      print('Error fetching landmarks: $e');
    }
  }

  void _showAddLandmarkDialog() async {
    if (_currentLocation == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddLandmarkDialog(
          initialLocation: _currentLocation!,
          onLandmarkAdded: (newLandmark) {
            setState(() {
              final GeoPoint point = newLandmark['location'] as GeoPoint;
              _landmarkMarkers.add(
                Marker(
                  width: 40.0,
                  height: 40.0,
                  point: LatLng(point.latitude, point.longitude),
                  child: GestureDetector(
                    onTap: () => _showLandmarkDetailsDialog(
                        newLandmark, LatLng(point.latitude, point.longitude)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              );
            });
          },
        );
      },
    );
  }

  void _showLandmarkDetailsDialog(
      Map<String, dynamic> landmarkData, LatLng location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LandmarkDetailsDialog(
          name: landmarkData['name'],
          description: landmarkData['description'],
          location: location,
          onNavigate: () {
            Navigator.of(context).pop();
            setState(() {
              _destinationLocation = location;
              _destinationName = landmarkData['name'];
              _hasShownArrivalDialog = false;
              _isNavigating = false; // Reset navigation state
              _routePoints.clear(); // Clear existing route
            });
            _getRoute();
          },
        );
      },
    );
  }

  Future<void> _checkArrival() async {
    if (_currentLocation != null && _destinationLocation != null && _isNavigating && !_hasShownArrivalDialog) {
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );

      print('Distance to destination: $distance meters');

      // Increase threshold to 10 meters for better arrival detection
      if (distance <= 10) {
        // Set flag immediately to prevent multiple dialogs
        _hasShownArrivalDialog = true;
        
        try {
          // Calculate and award points for this trip before showing dialog
          if (_totalDistanceTraveled > 0) {
            // First, round the distance to ensure consistency
            final roundedDistance = double.parse(_totalDistanceTraveled.toStringAsFixed(2));
            
            // Store both the distance and earned points that will be saved
            final pointsToSave = (roundedDistance * PointsService.pointsPerKm).round();
            
            print('Trip complete! Final distance: $roundedDistance km, points: $pointsToSave');
            
            // Update the points for the dialog display
            _pointsEarnedThisTrip = pointsToSave;
            
            // IMPORTANT: Pass the exact same rounded distance to the service
            await _pointsService.recordDistanceTraveled(roundedDistance);
            print('Points recorded successfully: $pointsToSave');
            
            // Reset tracked distance after saving
            _totalDistanceTraveled = 0.0;
            
            // Reload user details to get latest points
            await _loadUserDetails();
            
            // Only now show the dialog, after data is saved
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => ArrivalDialog(
                  landmarkName: _destinationName ?? 'Destination',
                  pointsEarned: _pointsEarnedThisTrip,
                  distanceTraveled: roundedDistance, // Pass the traveled distance
                  onClose: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isNavigating = false;
                      _destinationLocation = null;
                      _destinationName = null;
                      _routePoints.clear();
                      _hasShownArrivalDialog = false;
                      _bearing = 0.0;
                      _mapController.rotate(0.0);
                      _pointsEarnedThisTrip = 0;
                    });
                    
                    _navigationStream?.cancel();
                    _arrivalCheckTimer?.cancel();
                  },
                ),
              );
            }
          } else {
            // Show dialog even if no distance traveled (for direct arrivals)
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => ArrivalDialog(
                  landmarkName: _destinationName ?? 'Destination',
                  pointsEarned: 0,
                  distanceTraveled: 0.0, // Zero distance
                  onClose: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isNavigating = false;
                      _destinationLocation = null;
                      _destinationName = null;
                      _routePoints.clear();
                      _hasShownArrivalDialog = false;
                      _bearing = 0.0;
                      _mapController.rotate(0.0);
                      _pointsEarnedThisTrip = 0;
                    });
                    
                    _navigationStream?.cancel();
                    _arrivalCheckTimer?.cancel();
                  },
                ),
              );
            }
          }
        } catch (e) {
          print('Error processing arrival: $e');
          // Reset the flag in case of error so a retry is possible
          _hasShownArrivalDialog = false;
        }
      }
    }
  }

  void _showCancelNavigationDialog() {
    showDialog(
      context: context,
      builder: (context) => CancelNavigationDialog(
        onConfirm: () async {
          // Save any distance points before canceling navigation
          if (_totalDistanceTraveled > 0) {
            // Apply consistent rounding
            final roundedDistance = double.parse(_totalDistanceTraveled.toStringAsFixed(2));
            await _pointsService.recordDistanceTraveled(roundedDistance);
            _totalDistanceTraveled = 0.0;
            await _loadUserDetails(); // Reload points display
          }
          
          Navigator.pop(context);
          _navigationStream?.cancel();
          setState(() {
            _isNavigating = false;
            _destinationLocation = null;
            _destinationName = null;
            _routePoints.clear();
            _hasShownArrivalDialog = false;
            _bearing = 0.0;
            _mapController.rotate(0.0);
          });
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _setupPointsTracking() {
    // Track location for points every 20 seconds or 5 meters moved
    Timer.periodic(const Duration(seconds: 5), (_) {
      _calculateAndAwardPoints();
    });
  }
  
  void _calculateAndAwardPoints() async {
    if (_currentLocation == null) return;
    
    // Initialize lastRecordedLocation if null
    if (_lastRecordedLocation == null) {
      _lastRecordedLocation = _currentLocation;
      return;
    }
    
    // Calculate distance between current and last recorded location
    final double distanceMeters = Geolocator.distanceBetween(
      _lastRecordedLocation!.latitude,
      _lastRecordedLocation!.longitude, 
      _currentLocation!.latitude,
      _currentLocation!.longitude
    );
    
    print('Distance moved: $distanceMeters meters');
    
    // Only count if moved more than the threshold distance
    if (distanceMeters >= _minDistanceThreshold) {
      // Convert to km with consistent rounding to 2 decimal places
      double distanceKm = double.parse((distanceMeters / 1000).toStringAsFixed(2));
      _totalDistanceTraveled += distanceKm;
      
      print('Total distance accumulated: $_totalDistanceTraveled km');
      
      // Update last recorded location
      _lastRecordedLocation = _currentLocation;
      
      // Save to Firebase when threshold is reached
      if (_totalDistanceTraveled >= _pointSaveThreshold / 1000) { // Convert threshold to km
        // Round total distance to ensure consistency with what's shown in dialog
        final roundedDistance = double.parse(_totalDistanceTraveled.toStringAsFixed(2));
        print('Threshold reached, recording distance: $roundedDistance km');
        
        // Record the distance and update points
        await _pointsService.recordDistanceTraveled(roundedDistance);
        
        // Reload user points after recording
        await _loadUserDetails();
        
        // Reset tracked distance after saving
        _totalDistanceTraveled = 0.0;
      }
    }
  }

  void _handleLandmarkSelection(Map<String, dynamic> landmark) {
    _focusOnLandmark(landmark);
    _searchFocusNode.unfocus();
    _searchController.text = landmark['name'];
  }

  @override
  Widget build(BuildContext context) {
    double markerSize = _zoom > 12 ? 40.0 : 20.0;
    double routeStrokeWidth = _zoom > 12 ? 10.0 : 8.0;

    return Scaffold(
      body: Stack(
        children: [
          !_isLocationReady || _currentLocation == null
              ? const Center(child: LoadingScreen())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _currentLocation!,
                    zoom: _zoom,
                    minZoom: 12.0,
                    maxZoom: 18.49,
                    rotation: _isNavigating ? _bearing : 0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _destinationLocation = point;
                      });
                      _getRoute();
                    },
                    onPositionChanged: (position, hasGesture) {
                      setState(() {
                        _zoom = position.zoom!;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
                      userAgentPackageName: 'com.example.app',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: routeStrokeWidth,
                          gradientColors: [
                            Colors.lime.shade700,
                            Colors.lime.shade400,
                            Colors.lime.shade100,
                          ],
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: markerSize * 6.0,
                          height: markerSize * 6.0,
                          point: _currentLocation!,
                          child: CurrentLocationMarker(
                            markerSize: markerSize,
                            compassRotation: _compassRotation,
                            pulseAnimation: _pulseAnimation,
                            flashlightAnimation: _flashlightAnimation,
                          ),
                        ),
                        if (_destinationLocation != null)
                          Marker(
                            width: markerSize,
                            height: markerSize,
                            point: _destinationLocation!,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(markerSize / 2),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ..._landmarkMarkers,
                      ],
                    ),
                  ],
                ),
          MapSearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _searchLandmarks,
            onProfileTap: _toggleMenu,
            userPhotoUrl: _userPhotoUrl,
            isMenuOpen: _isMenuOpen,
            menuLayerLink: _menuLayerLink,
          ),
          SearchResults(
            searchResults: _searchResults,
            onLandmarkSelected: _handleLandmarkSelection,
            isVisible: _searchResults.isNotEmpty && _searchFocusNode.hasFocus,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomInfo(
              walkingEta: _isNavigating ? _walkingEta : '0 min',
              drivingEta: _isNavigating ? _drivingEta : '0 min',
              distance: _isNavigating ? _distance : '0 km',
              isNavigating: _isNavigating,
              onCancelNavigation: _showCancelNavigationDialog,
              onAddLandmark: _showAddLandmarkDialog,
            ),
          ),
        ],
      ),
    );
  }
}