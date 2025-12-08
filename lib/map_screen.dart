// lib/map_screen.dart

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? mapboxMap;

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    print("Map is successfully created.");
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 यहाँ अपना Mapbox Public Access Token डालें 🔥
    const String accessToken = "pk.YOUR_MAPBOX_PUBLIC_ACCESS_TOKEN_HERE"; 
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapbox Screen"),
        backgroundColor: Colors.blueAccent,
      ),
      body: MapWidget(
        resourceOptions: ResourceOptions(accessToken: accessToken),
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(-74.0060, 40.7128)), // New York
          zoom: 10.0,
        ),
        styleUri: MapboxStyles.MAPBOX_STREETS,
        onMapCreated: _onMapCreated,
      ),
    );
  }
}
