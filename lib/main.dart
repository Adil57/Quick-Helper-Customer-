// lib/main.dart (FINAL CODE: Hardcoded URL, Uri.https, aur Timeout 15s Fixes Applied)

import 'package:flutter/material.dart';
import 'package:auth0_flutter/auth0_flutter.dart'; 
import 'package:auth0_flutter_platform_interface/auth0_flutter_platform_interface.dart'; 
import 'dart:async'; 
import 'dart:convert';
import 'package:http/http.dart' as http; 

// 🟢 MAP IMPORTS
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; 
import 'package:permission_handler/permission_handler.dart'; 
import 'package:geolocator/geolocator.dart' as Geo; 

// -----------------------------------------------------------------------------
// GLOBAL CONFIGURATION
// -----------------------------------------------------------------------------
// Note: Yeh variable abhi bhi rakhenge, lekin niche functions mein hardcoded URL use karenge
const String mongoApiBase = "https://quick-helper-backend.onrender.com/api"; 
const String auth0Domain = "adil888.us.auth0.com"; 
const String auth0ClientId = "OdsfeU9MvAcYGxK0Vd8TAlta9XAprMxx"; 
const String auth0RedirectUri = "com.quickhelper.app://adil888.us.auth0.com/android/com.example.quick_helper_customer/callback"; 

// 🟢 Auth0 Instance
final Auth0 auth0 = Auth0(auth0Domain, auth0ClientId);

// -----------------------------------------------------------------------------
// DUMMY STATE MANAGEMENT (No Change)
// -----------------------------------------------------------------------------
class AppUserProfile {
  final String name;
  final String sub;
  const AppUserProfile({required this.name, required this.sub}); 
}

class UserAuth {
  AppUserProfile? _user; 
  String? _token; 

  UserAuth() {}

  AppUserProfile? get user => _user;
  bool get isAuthenticated => _user != null;

  void setUser(AppUserProfile? user, {String? token}) { 
    _user = user; 
    _token = token;
  }
  String? get userId => _user?.sub ?? "temp_user_id_001";
  
  Future<void> logout(BuildContext context) async {
     _user = null;
     _token = null;
     if (context.mounted) {
       Navigator.of(context).pushAndRemoveUntil(
         MaterialPageRoute(builder: (context) => const AuthGate()), 
         (Route<dynamic> route) => false
       );
     }
  }
}
final UserAuth tempAuth = UserAuth();

// -----------------------------------------------------------------------------
// MAIN ENTRY & APP THEME (No Change)
// -----------------------------------------------------------------------------
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  String accessToken = const String.fromEnvironment('ACCESS_TOKEN');
  
  if (accessToken.isNotEmpty) {
      MapboxOptions.setAccessToken(accessToken);
  } else {
      print('ERROR: MAPBOX ACCESS TOKEN is empty or not defined during build/run.');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Quick Helper",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light, 
          primarySwatch: Colors.indigo,
          appBarTheme: const AppBarTheme(
            color: Colors.white,
            elevation: 0.5,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)
          )
        ),
        home: const AuthGate(), 
      );
  }
}

// ---------------- 🟢 AUTH GATE (No Change) ---------------- //
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (tempAuth.isAuthenticated) { 
      return MainNavigator(); 
    }
    return const LoginChoiceScreen(); 
  }
}

// -----------------------------------------------------------------------------
// LOGIN CHOICE SCREEN (No Change)
// -----------------------------------------------------------------------------
class LoginChoiceScreen extends StatefulWidget {
  const LoginChoiceScreen({super.key});

  @override
  State<LoginChoiceScreen> createState() => _LoginChoiceScreenState();
}

class _LoginChoiceScreenState extends State<LoginChoiceScreen> {
  bool isLoading = false;
  String? _error;

  // 1. Auth0 Login Function
  Future<void> loginWithAuth0() async { 
      setState(() { _error = null; isLoading = true; });
      try {
        final result = await auth0.webAuthentication(scheme: auth0RedirectUri.split('://').first).login();
        if (mounted) {
          tempAuth.setUser(AppUserProfile(name: result.user.name ?? "User", sub: result.user.sub ?? ""), token: result.accessToken); 
          Navigator.pushReplacement( context, MaterialPageRoute(builder: (_) => MainNavigator()));
        }
      } on Exception catch (e) {
        if (mounted) {
          String message = 'Auth0 Login Failed. Check redirect URL in Auth0 Dashboard.';
          setState(() { _error = message; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          print('Auth0 Login Error: $e'); 
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
  }

  // 2. Normal Login Function (Navigation)
  void navigateToCustomLogin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomLoginScreen()));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text("Welcome to Quick Helper!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                  textAlign: TextAlign.center),
              const SizedBox(height: 60),

              // --- A. LOGIN WITH AUTH0 BUTTON ---
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.lock_open),
                  label: Text(isLoading ? "Logging in..." : 'Log in with Auth0 (Google/Social)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isLoading ? null : loginWithAuth0,
                ),
              ),
              const SizedBox(height: 20),

              const Divider(height: 20, thickness: 1, color: Colors.grey),

              const SizedBox(height: 20),
              
              // --- B. NORMAL LOGIN BUTTON ---
              SizedBox(
                height: 50,
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.email, color: Colors.indigo),
                  label: const Text('Normal Login (Email/Password)', style: TextStyle(color: Colors.indigo)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.indigo),
                  ),
                  onPressed: isLoading ? null : () => navigateToCustomLogin(context),
                ),
              ),
              
              if (_error != null) 
                Padding(padding: const EdgeInsets.only(top: 20), child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- 🟢 MAIN NAVIGATOR (No Change) ----------------- //
class MainNavigator extends StatelessWidget {
  MainNavigator({super.key}); 

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, 
      child: Scaffold(
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), 
          children: [
            HomePage(), 
            MapViewScreen(), 
            const Center(child: Text("Bookings Screen")), 
            const Center(child: Text("Chat Screen")), 
            AccountScreen(), 
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey, width: 0.1)),
          ),
          child: const TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorPadding: EdgeInsets.all(5.0),
            indicatorColor: Colors.indigo,
            tabs: [
              Tab(icon: Icon(Icons.home), text: "Home"),
              Tab(icon: Icon(Icons.map), text: "Map"), 
              Tab(icon: Icon(Icons.receipt), text: "Bookings"), 
              Tab(icon: Icon(Icons.chat), text: "Chat"), 
              Tab(icon: Icon(Icons.person), text: "Account"), 
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- ACCOUNT SCREEN (No Change) ---------------- //
class AccountScreen extends StatelessWidget {
  AccountScreen({super.key}); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Account")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Logged in as: ${tempAuth.user?.name ?? 'N/A'}"),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => tempAuth.logout(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Logout", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🟢 MAP VIEW SCREEN (No Change)
// -----------------------------------------------------------------------------
class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? annotationManager;
  
  bool _isLocationPermissionGranted = false; 
  StreamSubscription<Geo.Position>? _positionStreamSubscription;
  bool isFirstUpdate = true; 


  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission(); 
  }
  
  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); 
    super.dispose();
  }


  // Location Permission check
  Future<void> _checkAndRequestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      setState(() {
        _isLocationPermissionGranted = true;
      });
      if (mapboxMap != null) {
        _startListeningToLocationUpdates();
      }
    } else {
      print("Location permission denied by user. Re-requesting.");
      setState(() {
        _isLocationPermissionGranted = false;
      });
    }
  }


  // Map ko Current Location par Center karna (Geolocator stream se)
  void _startListeningToLocationUpdates() {
      if (mapboxMap == null) return;
      
      _positionStreamSubscription?.cancel();

      final locationSettings = Geo.LocationSettings(
          accuracy: Geo.LocationAccuracy.high, 
          distanceFilter: 1, 
      );
      
      isFirstUpdate = true; 

      _positionStreamSubscription = Geo.Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Geo.Position position) {
        
        mapboxMap!.location.updateSettings(
            LocationComponentSettings(
              enabled: true, 
              pulsingEnabled: false, 
            )
        );

        if (isFirstUpdate) {
            mapboxMap!.flyTo(
                CameraOptions(
                    center: Point(coordinates: Position(position.longitude, position.latitude)),
                    zoom: 16.0, 
                    bearing: position.heading,
                ),
                MapAnimationOptions(duration: 500), 
            );
            isFirstUpdate = false; 
        }
      });
  }


  // Mapbox Location Puck Enable aur Centering call
  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    annotationManager = await mapboxMap.annotations.createPointAnnotationManager();

    if (_isLocationPermissionGranted) {
        await mapboxMap.location.updateSettings(
            LocationComponentSettings(
              enabled: true, 
              pulsingEnabled: false, 
            )
        );
        
        _startListeningToLocationUpdates(); 
    }
    
    // Helper 1 - Ramesh Plumber (Dummy Annotation)
    var options1 = PointAnnotationOptions(
      geometry: Point(coordinates: Position(72.87, 19.07)),
      textField: "Ramesh - Plumber",
    );
    await annotationManager?.create(options1);

    // Helper 2 - Suresh Electrician (Dummy Annotation)
    var options2 = PointAnnotationOptions(
      geometry: Point(coordinates: Position(72.85, 19.09)),
      textField: "Suresh - Electrician",
    );
    await annotationManager?.create(options2);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocationPermissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text("Location Required")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Location access is required to show nearby helpers. Please grant permission.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _checkAndRequestLocationPermission,
                  child: const Text("Grant Location Permission"),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Helpers (MapBox)")),
      body: MapWidget(
        key: GlobalKey(),
        styleUri: MapboxStyles.MAPBOX_STREETS, 
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(72.8777, 19.0760)), 
          zoom: 12.0,
        ),
        onMapCreated: _onMapCreated,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CUSTOM LOGIN SCREEN (No Change)
// -----------------------------------------------------------------------------
class CustomLoginScreen extends StatefulWidget {
  const CustomLoginScreen({super.key});
  @override
  State<CustomLoginScreen> createState() => _CustomLoginScreenState();
}
class _CustomLoginScreenState extends State<CustomLoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();


  // API Login Call (Functional)
  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) {
        return; 
    }
    
    setState(() => isLoading = true); 
    String? error;

    final loginPayload = {
        'email': email.text.trim(), 
        'password': password.text,
    };
    
    final uri = Uri.parse('$mongoApiBase/auth/login'); 
    
    try {
        final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(loginPayload),
        ).timeout(const Duration(seconds: 30)); 

        if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            final token = responseData['token'];
            final user = responseData['user']; 
            
            tempAuth.setUser(
              AppUserProfile(name: user['name'] ?? 'Local User', sub: user['id'] ?? user['email']), 
              token: token
            );
            
            if (mounted) {
                 Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(builder: (context) => MainNavigator()), 
                   (Route<dynamic> route) => false
                 );
            }
            return; 
        } else {
            final errorData = json.decode(response.body);
            error = errorData['message'] ?? 'Login failed. Please check your credentials.';
        }

    } catch (e) {
        if (e is TimeoutException) {
          error = 'Network Timeout: Server took too long to respond. Please try again.';
        } else {
          error = 'Network error: Could not connect to the login service.';
        }
        print('Login API Error: $e');
    } 

    if (mounted) {
      setState(() => isLoading = false);
      if (error != null) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(error!), backgroundColor: Colors.red)
         );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Custom Login")),
      body: Form(
        key: _formKey, 
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Login with Email/Password",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 40),
  
              TextFormField( 
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.isEmpty ? 'Email cannot be empty' : null,
              ),
              TextFormField( 
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (value) => value!.isEmpty ? 'Password cannot be empty' : null,
              ),
  
              const SizedBox(height: 20),
              
              // 🟢 CUSTOM LOGIN BUTTON
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginUser, 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Log in", style: TextStyle(color: Colors.white)),
                ),
              ),
              
              TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => RegisterScreen())); 
                },
                child: const Text("Create an account (OTP Required)"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- REGISTER SCREEN (Helper Registration Button Added) ---------------- //
class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key}); 
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  // Start OTP Registration Process (API Ready)
  Future<void> registerUserStartOTP() async {
    if (!_formKey.currentState!.validate()) {
        return; 
    }
    
    setState(() => isLoading = true);
    String? error;
    
    final payload = {
      'name': name.text.trim(), 
      'email': email.text.trim(), 
      'password': password.text,
    };

    try {
      // 🌟 FINAL FIX 1: URL ko hardcode kiya taaki koi invisible character ya encoding issue na ho
      final response = await http.post(
        Uri.parse('https://quick-helper-backend.onrender.com/api/auth/register-otp'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
        // 🌟 FINAL FIX 2: Timeout ko 15s kiya taaki jaldi error de agar server tak request nahi pahunchti
      ).timeout(const Duration(seconds: 15)); 

      if (response.statusCode == 200 || response.statusCode == 201) { 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP sent to your email. Please verify."), backgroundColor: Colors.indigo)
          );
          // SUCCESS: Navigate to OTP Verification Screen
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              name: name.text, 
              email: email.text, 
              password: password.text,
              isRegistration: true, 
            )
          ));
          return; 
        }
      } else {
         // FAILURE: Agar user already exist karta hai ya server error hai
         final errorData = json.decode(response.body);
         error = errorData['message'] ?? 'Registration failed. Server error: ${response.statusCode}';
      }
    } catch (e) {
      if (e is TimeoutException) {
          // Timeout error (server tak nahi pahuncha ya server crash hua)
          error = 'Network Timeout: Server took too long to respond. Please try again.';
      } else {
          // General connection error
          error = 'Network error: Could not connect to registration service.';
      }
      print('Registration Start OTP Error: $e');
    }
    
    if (mounted) {
      setState(() => isLoading = false);
      if (error != null) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(error!), backgroundColor: Colors.red)
         );
      }
    }
  }


  // 🟢 FIXED FUNCTION: Background Login + Helper Registration
  Future<void> _registerHelper() async {
      setState(() => isLoading = true);
      String? error;
      
      try {
          // 1. Pehle background mein ek valid user se login karo taaki Token mile
          // 🛑 Yahan apna koi bhi purana registered email/password dal do
          final loginPayload = {
            'email': 'testuser@example.com', 
            'password': 'password123'
          };

          final loginResponse = await http.post(
            Uri.parse('https://quick-helper-backend.onrender.com/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(loginPayload),
          ).timeout(const Duration(seconds: 10));

          if (loginResponse.statusCode == 200) {
              final authData = json.decode(loginResponse.body);
              final String token = authData['token'];
              final String userId = authData['user']['id'];

              // 2. Ab is Token ko use karke Helper register karo
              final helperPayload = {
                'userId': userId, 
                'name': name.text.isEmpty ? "Test Helper" : name.text.trim(), 
                'skill': "Electrician", 
                'price': 500,           
                'latitude': 19.0760,
                'longitude': 72.8777,
              };

              final response = await http.post(
                Uri.parse('https://quick-helper-backend.onrender.com/api/helpers/register'), 
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token', // 🟢 Token yahan bhej diya
                },
                body: json.encode(helperPayload),
              ).timeout(const Duration(seconds: 15));

              if (response.statusCode == 200 || response.statusCode == 201) { 
                 if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("SUCCESS! Saved with Token."), backgroundColor: Colors.green)
                    );
                 }
                 setState(() => isLoading = false);
                 return; 
              } else {
                 error = 'Helper API Error: ${response.statusCode}';
              }
          } else {
              error = "Auth Failed: Pehle ek manual account banao testing ke liye.";
          }
      } catch (e) {
          error = 'Network error: Server shayad so raha hai.';
          print('Helper Registration Error: $e');
      }

      if (mounted) {
        setState(() => isLoading = false);
        if (error != null) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(error!), backgroundColor: Colors.red)
           );
        }
      }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register (OTP Required)")),
      body: Form(
        key: _formKey, 
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              TextFormField( 
                controller: name,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
              ),
              TextFormField( 
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.isEmpty ? 'Email cannot be empty' : null,
              ),
              TextFormField( 
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password (min 6 chars)"),
                validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
  
              const SizedBox(height: 20),
  
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : registerUserStartOTP,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register & Send OTP"),
                ),
              ),

              const SizedBox(height: 20),
              // 🟢 TEMPORARY HELPER REGISTRATION BUTTON
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _registerHelper,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("TEMPORARY: REGISTER ME AS A HELPER", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- NEW: OTP VERIFICATION SCREEN (No Change) ---------------- //
class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  final String password;
  final bool isRegistration;

  const OTPVerificationScreen({
    super.key, 
    required this.email, 
    required this.name, 
    required this.password,
    required this.isRegistration,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}
class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController otp = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();


  // Verify OTP (Functional)
  Future<void> verifyOTP() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }
    setState(() => isLoading = true);
    String? error;

    final verifyPayload = {
      'email': widget.email, 
      'otp': otp.text,
      'name': widget.isRegistration ? widget.name : null, 
      'password': widget.isRegistration ? widget.password : null,
    };
    
    // 🌟 URL hardcoded
    final uri = Uri.parse('https://quick-helper-backend.onrender.com/api/auth/verify-otp'); 

    try {
      final response = await http.post(
        uri, 
        headers: {'Content-Type': 'application/json'},
        body: json.encode(verifyPayload),
      ).timeout(const Duration(seconds: 15)); // Timeout 15s

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final user = data['user']; 
        
        tempAuth.setUser(
          AppUserProfile(name: user['name'] ?? widget.name, sub: user['id'] ?? widget.email), 
          token: token
        );
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Verification successful! Logging in..."), backgroundColor: Colors.green)
           );
           Navigator.pushReplacement( context, MaterialPageRoute(builder: (_) => MainNavigator()));
           return; 
        }
      } else {
         final errorData = json.decode(response.body);
         error = errorData['message'] ?? 'OTP verification failed. Status: ${response.statusCode}';
      }
    } catch (e) {
      if (e is TimeoutException) {
          error = 'Network Timeout: Server took too long to respond. Please try again.';
      } else {
          error = 'Network error: Could not connect to verification service.';
      }
      print('OTP Verification Error: $e');
    }
    
    if (mounted) {
      setState(() => isLoading = false);
      if (error != null) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(error!), backgroundColor: Colors.red)
         );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Form(
        key: _formKey, 
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("OTP sent to ${widget.email}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.indigo)),
              const SizedBox(height: 20),
              TextFormField( 
                controller: otp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(labelText: "OTP Code"),
                validator: (value) => value!.length != 6 ? 'Enter the 6-digit OTP' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyOTP,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Verify & Complete"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ 🟢 HOME SCREEN (Uri.https FIX Applied) ------------------
class HomePage extends StatefulWidget {
  HomePage({super.key}); 
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> helpers = []; 
  bool loading = false; 

  // Fallback data
  List<Map<String, dynamic>> fallbackHelpers = [
    {"name": "Ramesh", "skill": "Electrician", "price": 450, "image": ""},
    {"name": "Suresh", "skill": "Plumber", "price": 300, "image": ""},
    {"name": "Anita", "skill": "Cleaner", "price": 250, "image": ""},
    {"name": "Babu", "skill": "Carpenter", "price": 600, "image": ""},
  ];


  @override
  void initState() {
    super.initState();
    _loadHelpers(); 
  }

  void _filterByCategory(String category) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filtering helpers by: $category'))
    );
    print('Filtered by: $category');
  }

  // MODIFIED: Fetch helpers from the backend API with Uri.https FIX
  Future<void> _loadHelpers() async {
    setState(() => loading = true);
    String? error;
    
     // 🌟 FINAL FIX 1: Uri.https use kiya (URL Encoding Fix)
    final uri = Uri.https(
        'quick-helper-backend.onrender.com', 
        'api/helpers/list'                  
    ); 

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15)); // Timeout 15s

      if (response.statusCode == 200) {
        // SUCCESS
        final responseData = json.decode(response.body);
        
        if (responseData is List) {
           helpers = responseData.map((h) => h as Map<String, dynamic>).toList(); 
        } else {
           error = 'Invalid data format from server. Using fallback.';
           helpers = fallbackHelpers;
        }

      } else {
        error = 'Server Error (${response.statusCode}): Failed to load helpers. Using fallback data.';
        helpers = fallbackHelpers; 
      }

    } on TimeoutException {
      error = 'Network Timeout: Server took too long to respond. Using fallback data.';
      helpers = fallbackHelpers; 
    } catch (e) {
      error = 'Connection Error: Could not reach the API server. Using fallback data.';
      print('Helper List API Error: $e');
      helpers = fallbackHelpers; 
    } 

    if (mounted) {
      setState(() => loading = false);
      if (error != null) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(error!), backgroundColor: Colors.orange) 
         );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final userName = tempAuth.user?.name ?? "Customer"; 

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Welcome, $userName!", style: const TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_pin_outlined, color: Colors.black),
            onPressed: () {
               DefaultTabController.of(context).animateTo(4);
            },
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator( 
              onRefresh: _loadHelpers,
              child: SingleChildScrollView( 
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column( 
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [ 
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Find Helpers Near You",
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          SizedBox(height: 3),
                          Text("Plumbers, Electricians, Cleaners, all nearby"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          categoryItem("Cleaning", Icons.cleaning_services),
                          categoryItem("Electrician", Icons.electrical_services),
                          categoryItem("Plumber", Icons.plumbing),
                          categoryItem("Painter", Icons.format_paint),
                          categoryItem("Carpenter", Icons.carpenter),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("Available Helpers",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    // Check if helpers list is empty or not
                    helpers.isEmpty 
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text("No helpers found or failed to load data.")),
                      )
                    : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: helpers.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: .78,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final h = helpers[index];
                        return helperCard(
                          h["name"] ?? "Unknown",
                          h["skill"] ?? "Service", 
                          h["price"] ?? 0,
                          h["image"] ?? "", 
                        );
                      },
                    )
                  ],
                )
              )
            )
    );
  } 

  Widget categoryItem(String title, IconData icon) {
    return InkWell(
      onTap: () => _filterByCategory(title),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: Colors.indigo), 
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
  
  Widget helperCard(String name, String skill, int price, String imgUrl) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => HelperDetailPage( 
                      helperName: name, 
                      helperSkill: skill,
                      price: price,
                      imgUrl: imgUrl,
                    )));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: imgUrl.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12)),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(imgUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 8),
            Text(name,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(skill, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text("₹$price /hr",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ------------------ 🟢 BOOKING SCREEN (No Change) ------------------
class BookingScreen extends StatefulWidget {
  final String helperName;
  final String helperSkill;
  final int price;

  const BookingScreen({super.key, required this.helperName, required this.helperSkill, required this.price});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}
class _BookingScreenState extends State<BookingScreen> { 
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  double estimatedHours = 2.0;
  bool isCreatingBooking = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  double get totalCost => estimatedHours * widget.price * 1.2; 
  
  // Real API Call structure for booking
  Future<void> _createBooking() async {
    setState(() => isCreatingBooking = true);
    String? error;

    final bookingPayload = {
        'helperId': widget.helperName, 
        'customerId': tempAuth.userId,
        'serviceType': widget.helperSkill,
        'bookingDate': selectedDate.toIso8601String(),
        'estimatedHours': estimatedHours.toStringAsFixed(1),
        'totalCost': totalCost.toStringAsFixed(0),
    };
    
    // 1. API Endpoint
    final uri = Uri.parse('$mongoApiBase/bookings/create'); 
    
    try {
        final response = await http.post(
            uri,
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${tempAuth._token}', 
            },
            body: json.encode(bookingPayload),
        ).timeout(const Duration(seconds: 15)); // Timeout 15s

        if (response.statusCode == 200 || response.statusCode == 201) {
            // SUCCESS
            if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                      content: Text('Booking Successful! Helper ${widget.helperName} assigned.'),
                      backgroundColor: Colors.green,
                   )
                 );
                 Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(builder: (context) => MainNavigator()), 
                   (Route<dynamic> route) => false
                 );
            }
        } else {
            final errorData = json.decode(response.body);
            error = errorData['message'] ?? 'Booking failed with status code ${response.statusCode}';
        }

    } catch (e) {
        if (e is TimeoutException) {
            error = 'Network Timeout: Server took too long to respond. Please try again.';
        } else {
            error = 'Network error: Could not connect to booking service.';
        }
        print('Booking API Error: $e');
    } 

    if (mounted) {
      setState(() => isCreatingBooking = false);
      if (error != null) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
              content: Text(error!),
              backgroundColor: Colors.red,
           )
         );
      }
    }
  }


  Widget _buildDatePicker() { 
    return ListTile(
      leading: const Icon(Icons.calendar_month, color: Colors.indigo),
      title: const Text('Service Date'),
      subtitle: Text('\( {selectedDate.day}/ \){selectedDate.month}/${selectedDate.year}'),
      trailing: TextButton(
        onPressed: () => _selectDate(context),
        child: const Text('CHANGE', style: TextStyle(color: Colors.indigo)),
      ),
    );
  }

  
  Widget _buildTimeSlider() { 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text('Estimated Hours: ${estimatedHours.toStringAsFixed(1)} hours',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Slider( 
          value: estimatedHours,
          min: 1.0,
          max: 8.0,
          divisions: 14,
          label: estimatedHours.toStringAsFixed(1),
          activeColor: Colors.indigo, 
          onChanged: (double value) {
            setState(() {
              estimatedHours = value;
            });
          },
        ),
      ],
    );
  }


  Widget _buildCostSummary() { 
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _costRow("Helper Rate (\( {widget.price}/hr)", "₹ \){(estimatedHours * widget.price).toStringAsFixed(0)}"),
          _costRow("Service Fee (20%)", "₹${(totalCost - (estimatedHours * widget.price)).toStringAsFixed(0)}"),
          const Divider(),
          _costRow("TOTAL COST", "₹${totalCost.toStringAsFixed(0)}", isTotal: true),
        ],
      ),
    );
  }
  
  
  Widget _costRow(String title, String amount, {bool isTotal = false}) { 
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, fontSize: isTotal ? 16 : 14)),
          Text(amount, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, fontSize: isTotal ? 16 : 14, color: isTotal ? Colors.indigo : Colors.black)),
        ],
      ),
    );
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Booking")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.indigo,
              child: Text("Booking \( {widget.helperName} ( \){widget.helperSkill})", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Card(margin: const EdgeInsets.all(16), child: _buildDatePicker()),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text("Service Duration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: _buildTimeSlider()),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text("Cost Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildCostSummary(),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCreatingBooking ? null : _createBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: isCreatingBooking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("CONFIRM & PROCEED TO PAYMENT", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ------------------ 🟢 HELPER DETAIL PAGE (No Change) ------------------
class HelperDetailPage extends StatelessWidget {
  final String helperName;
  final String helperSkill;
  final int price;
  final String imgUrl;

  const HelperDetailPage({
    super.key,
    required this.helperName,
    required this.helperSkill,
    required this.price,
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(helperName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imgUrl.isEmpty
                ? Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Icon(Icons.person, size: 50, color: Colors.grey)),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imgUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
            
            const SizedBox(height: 16),
            Text(helperName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(helperSkill, style: const TextStyle(fontSize: 18, color: Colors.indigo)),
            const SizedBox(height: 8),
            Text("Rate: ₹$price / hour", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            const Divider(),
            const Text("About the Helper", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Rating, location, and review details will be loaded here.",
                style: TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 40),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BookingScreen(
                                helperName: helperName,
                                helperSkill: helperSkill,
                                price: price,
                              )));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("BOOK THIS HELPER", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}