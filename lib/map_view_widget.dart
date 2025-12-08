// lib/map_view_widget.dart

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapViewWidget extends StatefulWidget {
  const MapViewWidget({Key? key}) : super(key: key);

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  MapboxMap? mapboxMap;

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    // आप यहाँ मैप लोड होने के बाद और काम कर सकते हैं, जैसे स्टाइल बदलना
    print("Map is successfully created.");
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 यहाँ अपना Mapbox Public Access Token डालें 🔥
    const String accessToken = "pk.YOUR_MAPBOX_PUBLIC_ACCESS_TOKEN_HERE"; 
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mapbox Map"),
      ),
      body: MapWidget(
        // Mapbox SDK को टोकन यहाँ दें
        resourceOptions: ResourceOptions(accessToken: accessToken),
        // मैप की प्रारंभिक स्थिति सेट करें (उदाहरण के लिए, न्यूयॉर्क शहर)
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(-74.0060, 40.7128)),
          zoom: 10.0,
        ),
        // मैप की स्टाइल
        styleUri: MapboxStyles.MAPBOX_STREETS,
        // जब मैप बन जाए तो यह फंक्शन कॉल होगा
        onMapCreated: _onMapCreated,
      ),
    );
  }
}
