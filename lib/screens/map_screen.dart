import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../providers/alarm_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {

  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  LatLng? _fetchedLocation;
  double _radius = 500; // default 500m

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    
    _fetchedLocation = LatLng(position.latitude, position.longitude);
    if (_isMapReady) {
      _mapController.move(_fetchedLocation!, 15.0);
    }
  }

  void _onSave() {
    if (_selectedLocation == null) return;
    
    showDialog(
      context: context,
      builder: (context) {
        String name = "New Location";
        String contactNumber = "";
        return AlertDialog(
          title: const Text("Save Alarm"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(labelText: "Alarm Name"),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Contact to Notify (Optional)"),
                onChanged: (val) => contactNumber = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(alarmProvider.notifier).addAlarm(
                  name.isEmpty ? "New Location" : name,
                  _selectedLocation!.latitude,
                  _selectedLocation!.longitude,
                  _radius,
                  contactNumber: contactNumber.isEmpty ? null : contactNumber,
                );
                Navigator.pop(context);
                context.pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(0, 0),
              initialZoom: 2,
              onMapReady: () {
                _isMapReady = true;
                if (_fetchedLocation != null) {
                  _mapController.move(_fetchedLocation!, 15.0);
                }
              },
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sanat.geo_alarm',
              ),
              if (_selectedLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _selectedLocation!,
                      color: Colors.blue.withValues(alpha: 0.3),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                      useRadiusInMeter: true,
                      radius: _radius,
                    )
                  ],
                ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                    )
                  ],
                ),
            ],
          ),
          if (_selectedLocation != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Card(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Radius: ${_radius.toInt()} meters"),
                      Slider(
                        value: _radius,
                        min: 100,
                        max: 5000,
                        divisions: 49,
                        onChanged: (val) => setState(() => _radius = val),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onSave,
                          child: const Text("Set Alarm Here"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
