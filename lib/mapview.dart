import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Controller
  GoogleMapController? _controller;
  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  // Latitude Longitude
  final CameraPosition _initialLocation =
      const CameraPosition(target: LatLng(0, 0), zoom: 12);
  List<LatLng> _polylineCoordinates = [];

  final Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  String _distance = "0.0";
  String _darkMapStyle = '';
  String _lightMapStyle = '';
  bool _isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    _loadMapStyles();
  }

  // Load Map Theme
  Future<void> _loadMapStyles() async {
    _darkMapStyle = await rootBundle.loadString('assets/dark_map_style.json');
    _lightMapStyle = await rootBundle.loadString('assets/light_map_style.json');
  }

  // marker tap manage
  void _handleMapTap(LatLng tappedPosition) {
    _markers.clear(); // Clear all markers
    _polylineCoordinates.clear(); // Clear all polyline coordinates

    _addMarker(tappedPosition);
  }

  // Create Marker
  void _addMarker(LatLng position) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
        ),
      );

      _polylineCoordinates.add(position);
      _distance = '0.0';

      if (_markers.length == 2) {
        _calculateDistanceFromInput();
      }
    });
  }

  // Distance Calculate From Start to Destination
  void _calculateDistanceFromInput() async {
    _polylines.clear(); // Clear any existing polylines

    String startPoint = _startPointController.text;
    String destination = _destinationController.text;

    if (startPoint.isEmpty || destination.isEmpty) {
      _showSnackbar('Please enter both starting point and destination.');
      return;
    }

    var startCoordinates = await _getCoordinates(startPoint);
    var destCoordinates = await _getCoordinates(destination);

    if (startCoordinates != null && destCoordinates != null) {
      _polylineCoordinates = [startCoordinates, destCoordinates];
      _markers = {
        Marker(
          markerId: MarkerId(startCoordinates.toString()),
          position: startCoordinates,
        ),
        Marker(
          markerId: MarkerId(destCoordinates.toString()),
          position: destCoordinates,
        ),
      };
      _drawPolyline();
      _calculateDistance(startCoordinates, destCoordinates);
    } else {
      _showSnackbar('Could not determine coordinates for input points.');
    }
  }

  Future<LatLng?> _getCoordinates(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        return LatLng(location.latitude, location.longitude);
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving coordinates: $e');
      }
      return null;
    }
  }

  void _drawPolyline() {
    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('polyline'),
          visible: true,
          points: _polylineCoordinates,
          color: Colors.blue,
        ),
      );
    });
  }

  void _calculateDistance(LatLng start, LatLng destination) {
    double distance = Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          destination.latitude,
          destination.longitude,
        ) /
        1000; // Convert to kilometers
    setState(() {
      _distance = distance.toStringAsFixed(2);
    });
  }

  void _toggleMapTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
      _setMapStyle();
    });
  }

  void _setMapStyle() {
    if (_controller != null) {
      _controller!.setMapStyle(_isDarkTheme ? _darkMapStyle : _lightMapStyle);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  void _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      LatLng latLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: latLng,
          ),
        );
      });

      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: latLng,
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      _showSnackbar('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined),
            onPressed: _toggleMapTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startPointController,
                    decoration: const InputDecoration(
                      labelText: 'Starting Point',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Destination',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _calculateDistanceFromInput,
                child: const Text('Calculate Distance'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Distance: $_distance km"),
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initialLocation,
              compassEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
                _setMapStyle();
              },
              onTap: _handleMapTap,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        backgroundColor: Colors.transparent,
        elevation: 0.3,
        shape: const CircleBorder(),
        child: const Icon(Icons.location_on, color: Colors.redAccent),
      ),
    );
  }

  @override
  void dispose() {
    _startPointController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}
