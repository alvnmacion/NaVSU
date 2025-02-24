import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vector_math/vector_math.dart' as vector;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:navsu/ui/dialog/add_landmark_dialog.dart';
import 'package:navsu/ui/dialog/landmark_details_dialog.dart'; // Import the new dialog
import 'dart:math' as math; // Import math library
import 'package:flutter_compass/flutter_compass.dart'; // Import flutter_compass
import 'dart:ui' as Path;
import 'package:navsu/ui/dialog/arrival_dialog.dart';
import 'package:navsu/ui/dialog/cancel_navigation_dialog.dart';
import 'package:navsu/ui/dialog/add_landmark_confirmation_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _getCurrentLocation();
    _fetchLandmarks();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _startCompassUpdates();
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

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _flashlightAnimationController.dispose();
    _recenterTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _overlayEntry?.dispose();
    _mapController.dispose(); // Dispose MapController
    _compassSubscription?.cancel(); // Cancel compass subscription
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

    setState(() {
      _isNavigating = true;
      _bearing = 0.0; // Reset bearing when starting navigation
      _lastHeading = 0.0; // Reset heading when starting navigation
    });

    const String apiKey =
        '5b3ce3597851110001cf62483eb0593105fd4f87b3f72ee4aaedca67'; // Replace with your API key
    final String url =
        'https://api.openrouteservice.org/v2/directions/foot-walking?api_key=$apiKey&start=${_currentLocation!.longitude},${_currentLocation!.latitude}&end=${_destinationLocation!.longitude},${_destinationLocation!.latitude}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> coordinates =
          data['features'][0]['geometry']['coordinates'];
      final double durationMinutes = data['features'][0]['properties']['segments'][0]['duration'] / 60;
      final double distanceKm = data['features'][0]['properties']['segments'][0]['distance'] / 1000;
      
      setState(() {
        _routePoints = coordinates
            .map((coord) => LatLng(coord[1], coord[0]))
            .toList();
        _zoom = 18.49;
        _walkingEta = '${durationMinutes.round()} min';
        _distance = '${distanceKm.toStringAsFixed(1)} km';
        _drivingEta = '${(durationMinutes / 3).round()} min'; // Rough estimate
      });
      _mapController.move(_currentLocation!, 18.49);
      _startNavigationUpdates();
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  void _startNavigationUpdates() {
    if (!_isNavigating) return;

    // Initial arrival check
    _checkArrival();

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, // Increased accuracy
        distanceFilter: 1, // Update every 1 meter for more precise checks
      ),
    ).listen((Position position) {
      if (!_isNavigating) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.moveAndRotate(
          _currentLocation!,
          _zoom,
          _bearing
        );
      });
      
      // Check arrival after location update
      _checkArrival();
    });

    // Start periodic recentering
    _recenterTimer?.cancel();
    _recenterTimer = Timer.periodic(_recenterInterval, (timer) {
      if (_currentLocation != null && _isNavigating) {
        _mapController.move(_currentLocation!, _zoom);
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
      final snapshot =
          await FirebaseFirestore.instance.collection('landmarks').get();

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

  void _checkArrival() {
    if (_currentLocation != null && _destinationLocation != null && !_hasShownArrivalDialog) {
      final distance = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );

      print('Distance to destination: $distance meters'); // Debug print

      if (distance <= 5) { // 5 meters
        _hasShownArrivalDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => ArrivalDialog(
              landmarkName: _destinationName ?? 'Destination',
              onClose: () {
                Navigator.of(context).pop();
                setState(() {
                  _isNavigating = false;
                  _destinationLocation = null;
                  _destinationName = null;
                  _routePoints.clear();
                  _hasShownArrivalDialog = false;
                });
              },
            ),
          );
        });
      }
    }
  }

  void _showCancelNavigationDialog() {
    showDialog(
      context: context,
      builder: (context) => CancelNavigationDialog(
        onConfirm: () {
          Navigator.pop(context);
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

  Widget _buildCurrentLocationMarker(double markerSize) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _flashlightAnimation]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Flashlight cone
            Transform.rotate(
              angle: _compassRotation * (math.pi / 180),
              child: CustomPaint(
                size: Size(markerSize * 8, markerSize * 8), // Even bigger size
                painter: FlashlightPainter(
                  opacity: _flashlightAnimation.value,
                  color: Colors.green,
                  length: markerSize * 4, // Increased length
                  width: markerSize * 2, // Increased width
                ),
              ),
            ),
            // Outer pulse circle
            Transform.scale(
              scale: 1.0 + (_pulseAnimation.value * 0.5),
              child: Container(
                width: markerSize,
                height: markerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.2 * (1 - _pulseAnimation.value)),
                ),
              ),
            ),
            // Main green circle
            Container(
              width: markerSize * 0.7,
              height: markerSize * 0.7,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            // Center dot
            Container(
              width: markerSize * 0.25,
              height: markerSize * 0.25,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 50, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search VSU Landmarks...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults.clear();
                    });
                  },
                )
              : null,
        ),
        onChanged: _searchLandmarks,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty || !_searchFocusNode.hasFocus) return const SizedBox();

    return Positioned(
      top: 110,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final landmark = _searchResults[index];
            return ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: Text(landmark['name']),
              onTap: () {
                _focusOnLandmark(landmark);
                _searchFocusNode.unfocus();
                _searchController.text = landmark['name'];
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoColumn(
                icon: Icons.directions_walk,
                label: 'Walking',
                value: _isNavigating ? _walkingEta : '0 min',
              ),
              _buildInfoColumn(
                icon: Icons.directions_car,
                label: 'Driving',
                value: _isNavigating ? _drivingEta : '0 min',
              ),
              _buildInfoColumn(
                icon: Icons.straighten,
                label: 'Distance',
                value: _isNavigating ? _distance : '0 km',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_isNavigating)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCancelNavigationDialog, // Updated to show confirmation
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text(
                      'Stop Navigation',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (_isNavigating)
                const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddLandmarkDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.add_location),
                  label: const Text(
                    'Add Landmark',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double markerSize = _zoom > 12 ? 40.0 : 20.0; // Responsive marker size
    double routeStrokeWidth = _zoom > 12 ? 10.0 : 8.0;

    return Scaffold(
      body: Stack(
        children: [
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _currentLocation!,
                    zoom: _zoom,
                    minZoom: 12.0, // Restrict minimum zoom
                    maxZoom: 18.49, // Restrict maximum zoom
                    rotation: _isNavigating ? _bearing : 0, // Only rotate when navigating
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
                      urlTemplate:
                          "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
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
                          width: markerSize * 6.0, // Increased to accommodate larger flashlight
                          height: markerSize * 6.0,
                          point: _currentLocation!,
                          child: _buildCurrentLocationMarker(markerSize),
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
          _buildSearchBar(),
          _buildSearchResults(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class FlashlightPainter extends CustomPainter {
  final double opacity;
  final Color color;
  final double length;
  final double width;

  FlashlightPainter({
    required this.opacity,
    required this.color,
    required this.length,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity * 0.9), // Increased from 0.7 to 0.9
          color.withOpacity(opacity * 0.6), // Increased from 0.3 to 0.6
          color.withOpacity(opacity * 0.3), // Added middle gradient stop
          color.withOpacity(0),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0], // Adjusted stops for smoother gradient
        center: const Alignment(0.0, 0.5),
        focal: const Alignment(0.0, 0.3), // Added focal point for more focused light
        focalRadius: 0.3, // Added focal radius for light concentration
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path.Path()
      ..moveTo(size.width / 2, size.height / 2)
      ..lineTo(size.width / 2 - width, -length) // Wider and longer cone
      ..lineTo(size.width / 2 + width, -length)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FlashlightPainter oldDelegate) =>
      opacity != oldDelegate.opacity ||
      length != oldDelegate.length ||
      width != oldDelegate.width;
}
