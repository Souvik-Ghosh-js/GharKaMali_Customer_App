import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/location_provider.dart';
import '../../utils/app_theme.dart';

class LocationMapScreen extends StatefulWidget {
  final Function(LatLng, String) onLocationSelected;
  const LocationMapScreen({super.key, required this.onLocationSelected});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  LatLng? _currentP;
  final MapController _mapController = MapController();
  String _address = "Detecting address...";

  @override
  void initState() {
    super.initState();
    final loc = context.read<LocationProvider>();
    if (loc.lat != null && loc.lng != null) {
      _currentP = LatLng(loc.lat!, loc.lng!);
    } else {
      _currentP = const LatLng(28.6139, 77.2090); // Delhi default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Service Location"),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentP!,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                setState(() {
                  _currentP = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.gharkamali.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentP!,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Position(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Tap on map to select precise location",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'latlng': _currentP,
                        'address': "Selected from map", // In a real app, use geocoding
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Confirm Location",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Position extends StatelessWidget {
  final double? top, bottom, left, right;
  final Widget child;
  const Position({super.key, this.top, this.bottom, this.left, this.right, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}
