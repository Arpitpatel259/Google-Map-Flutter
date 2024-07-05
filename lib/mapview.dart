import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' show max, min;

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late GoogleMapController mapController;
  final CameraPosition _initialLocation =
      const CameraPosition(target: LatLng(0.0, 0.0));
  Position? _currentPosition;
  String _currentAddress = '';

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final destinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';

  Set<Marker> markers = {};
  late PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    startAddressFocusNode.dispose();
    destinationAddressFocusNode.dispose();
    startAddressController.dispose();
    destinationAddressController.dispose();
    super.dispose();
  }

  // Method for retrieving the current location
  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied, we cannot request permissions.';
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = position;
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18.0,
          ),
        ),
      );
    });

    await _getAddress();
  }

  // Method for retrieving the address
  Future<void> _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        startAddressController.text = _currentAddress;
        _startAddress = _currentAddress;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  // Method for calculating the distance between two places
  Future<bool> _calculateDistance() async {
    try {
      // Fetching start and destination locations
      List<Location> startPlacemark = await locationFromAddress(_startAddress);
      List<Location> destinationPlacemark =
          await locationFromAddress(_destinationAddress);

      double startLatitude = _startAddress == _currentAddress
          ? _currentPosition!.latitude
          : startPlacemark[0].latitude;
      double startLongitude = _startAddress == _currentAddress
          ? _currentPosition!.longitude
          : startPlacemark[0].longitude;

      double destinationLatitude = destinationPlacemark[0].latitude;
      double destinationLongitude = destinationPlacemark[0].longitude;

      markers.clear();

      // Creating markers for start and destination
      String startCoordinatesString = '($startLatitude, $startLongitude)';
      String destinationCoordinatesString =
          '($destinationLatitude, $destinationLongitude)';

      Marker startMarker = Marker(
        markerId: MarkerId(startCoordinatesString),
        position: LatLng(startLatitude, startLongitude),
        infoWindow: InfoWindow(
          title: 'Start $startCoordinatesString',
          snippet: _startAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      Marker destinationMarker = Marker(
        markerId: MarkerId(destinationCoordinatesString),
        position: LatLng(destinationLatitude, destinationLongitude),
        infoWindow: InfoWindow(
          title: 'Destination $destinationCoordinatesString',
          snippet: _destinationAddress,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );

      // Adding markers to the map
      setState(() {
        markers.add(startMarker);
        markers.add(destinationMarker);
      });

      // Adjusting camera to fit both markers
      double miny = min(startLatitude, destinationLatitude);
      double minx = min(startLongitude, destinationLongitude);
      double maxy = max(startLatitude, destinationLatitude);
      double maxx = max(startLongitude, destinationLongitude);

      mapController.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            northeast: LatLng(maxy, maxx),
            southwest: LatLng(miny, minx),
          ),
          100.0,
        ),
      );

      // Creating polylines and calculating distance
      await _createPolylines(startLatitude, startLongitude, destinationLatitude,
          destinationLongitude);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return false;
    }
  }

  // Create the polylines for showing the route between two places
  Future<void> _createPolylines(double startLatitude, double startLongitude,
      double destinationLatitude, double destinationLongitude) async {
    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyCl4Yjbq5GiZYPBS3TfoqV7YOmHCEjQCIU', // Replace with your Google Maps API Key
        PointLatLng(startLatitude, startLongitude),
        PointLatLng(destinationLatitude, destinationLongitude),
        travelMode: TravelMode.driving,
      );

      if (result.points.isNotEmpty) {
        List<LatLng> newPolylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        PolylineId id = const PolylineId('poly');
        Polyline polyline = Polyline(
          polylineId: id,
          color: Colors.blue,
          points: newPolylineCoordinates,
          width: 3,
          jointType: JointType.round,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        );

        setState(() {
          polylines[id] = polyline;
        });
      } else {
        if (kDebugMode) {
          print('No polyline points found');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: _initialLocation,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            markers: markers,
            polylines: Set<Polyline>.of(polylines.values),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
          ),
          Positioned(
            top: 50.0,
            right: 15.0,
            left: 15.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    offset: Offset(0.0, 1.0), // (x, y)
                    blurRadius: 6.0,
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: startAddressController,
                    focusNode: startAddressFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Start Address',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(left: 15.0, top: 15.0),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () => startAddressController.clear(),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _startAddress = value;
                      });
                    },
                  ),
                  const Divider(height: 1.0, color: Colors.grey),
                  TextField(
                    controller: destinationAddressController,
                    focusNode: destinationAddressFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Destination Address',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(left: 15.0, top: 15.0),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () => destinationAddressController.clear(),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _destinationAddress = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10.0),
                  ElevatedButton(
                    onPressed:
                        (_startAddress != '' && _destinationAddress != '')
                            ? () async {
                                await _calculateDistance();
                              }
                            : null,
                    child: const Text('Show Route'),
                  ),
                  const SizedBox(height: 10.0),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _getCurrentLocation();
        },
        child: const Icon(Icons.location_searching),
      ),
    );
  }
}
