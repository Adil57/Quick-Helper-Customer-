// lib/main.dart (FINAL CODE WITH ALL FIXES: The Definitive const Fix)

import 'package:flutter/material.dart';
import 'package:auth0_flutter/auth0_flutter.dart'; 
import 'package:auth0_flutter_platform_interface/auth0_flutter_platform_interface.dart'; 
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http; 

// 🟢 MAP IMPORTS
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; 
import 'package:permission_handler/permission_handler.dart'; // Run-time Permission
// 🟢 FIX: Geolocator ko 'Geo' alias se import karna taaki Position/Geolocator conflict na ho
import 'package:geolocator/geolocator.dart' as Geo; 

// -----------------------------------------------------------------------------
// GLOBAL CONFIGURATION
// -----------------------------------------------------------------------------
const String mongoApiBase = "https://quick-helper-backend.onrender.com/api"; 
const String auth0Domain = "adil888.us.auth0.com"; 
const String auth0ClientId = "OdsfeU9MvAcYGxK0Vd8TAlta9XAprMxx"; 
const String auth0RedirectUri = "com.quickhelper.app://adil888.us.auth0.com/android/com.example.quick_helper_customer/callback"; 

// 🟢 Auth0 Instance
final Auth0 auth0 = Auth0(auth0Domain, auth0ClientId);

// -----------------------------------------------------------------------------
// DUMMY STATE MANAGEMENT (FIX: super.key removed)
// -----------------------------------------------------------------------------
class AppUserProfile {
  final String name;
  final String sub;
  // FIX: super.key hata diya
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
// MAIN ENTRY & APP THEME (FIXED: Token + Initialization)
// -----------------------------------------------------------------------------
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX 1: Mapbox Token load
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

// ---------------- 🟢 AUTH GATE ---------------- //
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

// ----------------- 🟢 MAIN NAVIGATOR (Finalized Const Fix) ----------------- //
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
            HomePage(),  // ✅ CONST REMOVED
            MapViewScreen(), // ✅ CONST REMOVED
            const Center(child: Text("Bookings Screen")), 
            const Center(child: Text("Chat Screen")), 
            AccountScreen(), // ✅ CONST REMOVED
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
              Tab(icon: Icon(Icons.map), text: "Map"), // Tab 1
              Tab(icon: Icon(Icons.receipt), text: "Bookings"), // Tab 2
              Tab(icon: Icon(Icons.chat), text: "Chat"), // Tab 3
              Tab(icon: Icon(Icons.person), text: "Account"), // Tab 4
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- ACCOUNT SCREEN (Const Removed) ---------------- //
class AccountScreen extends StatelessWidget {
  AccountScreen({super.key}); // FIX: const removed

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
// 🟢 MAP VIEW SCREEN (ALL LOCATION AND API FIXES APPLIED)
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
  bool isFirstUpdate = true; // Sirf pehli baar center/flyTo use karenge


  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission(); 
  }
  
  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // Stream ko dispose karna
    super.dispose();
  }


  // FIX 2: Location Permission check
  Future<void> _checkAndRequestLocationPermission() async {
    // Permission Handler se request
    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      setState(() {
        _isLocationPermissionGranted = true;
      });
      // Permission milte hi stream shuru karni chahiye
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


  // 🌟 FIX 4: Map ko Current Location par Center karna (Geolocator stream se)
  void _startListeningToLocationUpdates() {
      if (mapboxMap == null) return;
      
      // Stop previous listener if any
      _positionStreamSubscription?.cancel();

      // Location request settings (Geolocator use karke)
      final locationSettings = Geo.LocationSettings(
          accuracy: Geo.LocationAccuracy.high, // FIX: LocationAccuracy par Geo. prefix
          distanceFilter: 1, // Har 1 meter pe update
      );
      
      isFirstUpdate = true; // Har baar stream start hone par centering reset

      // Stream start karo
      _positionStreamSubscription = Geo.Geolocator.getPositionStream(locationSettings: locationSettings)
          .listen((Geo.Position position) {
        
        // 🟢 FIX 1: Location Puck ko forcefully update/re-enable karo har update par
        mapboxMap!.location.updateSettings(
            LocationComponentSettings(
              enabled: true, 
              pulsingEnabled: false, // Stable dot
              // locationPuck ko yahan se HATA diya taaki default puck render ho
            )
        );

        // Camera ko naye location par move karo
        if (isFirstUpdate) {
            mapboxMap!.flyTo(
                CameraOptions(
                    center: Point(coordinates: Position(position.longitude, position.latitude)),
                    zoom: 16.0, 
                    bearing: position.heading,
                ),
                MapAnimationOptions(duration: 500), 
            );
            isFirstUpdate = false; // Next time flyTo nahi chalega
        }
      });
  }


  // 🌟 FINAL FIX: Mapbox Location Puck Enable aur Centering call
  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    annotationManager = await mapboxMap.annotations.createPointAnnotationManager();

    if (_isLocationPermissionGranted) {
        // 🟢 FIX 3: Location Puck ON karna (Yahan initial settings set karenge)
        await mapboxMap.location.updateSettings(
            LocationComponentSettings(
              enabled: true, 
              pulsingEnabled: false, 
              // locationPuck ko yahan se HATA diya taaki default puck render ho
            )
        );
        
        // Geoloactor stream shuru karna
        _startListeningToLocationUpdates(); 
    }
    
    // Helper 1 - Ramesh Plumber
    var options1 = PointAnnotationOptions(
      geometry: Point(coordinates: Position(72.87, 19.07)),
      textField: "Ramesh - Plumber",
    );
    await annotationManager?.create(options1);

    // Helper 2 - Suresh Electrician
    var options2 = PointAnnotationOptions(
      geometry: Point(coordinates: Position(72.85, 19.09)),
      textField: "Suresh - Electrician",
    );
    await annotationManager?.create(options2);
  }

  @override
  Widget build(BuildContext context) {
    // Permission check hone tak loading/Permission UI dikhana
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
    
    // Permission milne par Map dikhana
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Helpers (MapBox)")),
      body: MapWidget(
        key: GlobalKey(),
        styleUri: MapboxStyles.MAPBOX_STREETS, 
        // Initial fallback coordinates (ye code se override ho jayega)
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
// MODIFIED: CUSTOM LOGIN SCREEN (API LOGIN FIX)
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


  // MODIFIED: API Login Call (Functional)
  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) {
        return; 
    }
    
    setState(() => isLoading = true); // Loading state chalu karna
    String? error;

    final loginPayload = {
        'email': email.text.trim(), 
        'password': password.text,
    };
    
    // API Endpoint: Auth ke liye aapka endpoint
    final uri = Uri.parse('$mongoApiBase/auth/login'); 
    
    try {
        final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(loginPayload),
        );

        if (response.statusCode == 200) {
            // SUCCESS: Token aur User ID receive karna
            final responseData = json.decode(response.body);
            final token = responseData['token'];
            final user = responseData['user']; 
            
            // Token save karna aur Main app mein navigate karna
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
            return; // Success hone par return
        } else {
            // FAILURE: Server se galti aane par
            final errorData = json.decode(response.body);
            error = errorData['message'] ?? 'Login failed. Please check your credentials.';
        }

    } catch (e) {
        // NETWORK/CONNECTION ERROR: Server tak na pahunchne par
        error = 'Network error: Could not connect to the login service.';
        print('Login API Error: $e');
    } 

    // Error handling aur Loading state band karna
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
        key: _formKey, // Form key add kiya
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Login with Email/Password",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 40),
  
              TextFormField( // TextFormField use kiya for validation
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.isEmpty ? 'Email cannot be empty' : null,
              ),
              TextFormField( // TextFormField use kiya for validation
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
              
              // Error message field hata diya, SnackBar use hoga
              
              TextButton(
                onPressed: () {
                  // FIX: const hata diya
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

// ---------------- REGISTER SCREEN (Const Removed) ---------------- //
class RegisterScreen extends StatefulWidget {
  RegisterScreen({super.key}); // FIX: const removed
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  // MODIFIED: Start OTP Registration Process (API Ready)
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
      // API Endpoint: Register and Send OTP
      final response = await http.post(
        Uri.parse('$mongoApiBase/auth/register-otp'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) { 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP sent to your email. Please verify."), backgroundColor: Colors.indigo)
          );
          // SUCCESS: Navigate to OTP Verification Screen
          // FIX: OTPVerificationScreen se const hata diya
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              name: name.text, 
              email: email.text, 
              password: password.text,
              isRegistration: true, // Registration flow hai
            )
          ));
          return; // Success hone par return
        }
      } else {
         // FAILURE: Agar user already exist karta hai ya server error hai
         final errorData = json.decode(response.body);
         error = errorData['message'] ?? 'Registration failed. Server error: ${response.statusCode}';
      }
    } catch (e) {
      // NETWORK/CONNECTION ERROR
      error = 'Network error: Could not connect to registration service.';
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register (OTP Required)")),
      body: Form(
        key: _formKey, // Form key add kiya
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            children: [
              TextFormField( // TextFormField use kiya for validation
                controller: name,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
              ),
              TextFormField( // TextFormField use kiya for validation
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.isEmpty ? 'Email cannot be empty' : null,
              ),
              TextFormField( // TextFormField use kiya for validation
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
              // Error message field hata diya, SnackBar use hoga
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- NEW: OTP VERIFICATION SCREEN (Const Fix) ---------------- //
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


  // MODIFIED: Verify OTP (Functional)
  Future<void> verifyOTP() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }
    setState(() => isLoading = true);
    String? error;

    final verifyPayload = {
      'email': widget.email, 
      'otp': otp.text,
      // Registration ke case mein name aur password bhi bhejenge
      'name': widget.isRegistration ? widget.name : null, 
      'password': widget.isRegistration ? widget.password : null,
    };
    
    final uri = Uri.parse('$mongoApiBase/auth/verify-otp'); 

    try {
      final response = await http.post(
        uri, 
        headers: {'Content-Type': 'application/json'},
        body: json.encode(verifyPayload),
      );

      if (response.statusCode == 200) {
        // SUCCESS: Verification Done, Token aur User ID mil gaye
        final data = json.decode(response.body);
        final token = data['token'];
        final user = data['user']; 
        
        // Token save karna aur UserAuth state update karna
        tempAuth.setUser(
          AppUserProfile(name: user['name'] ?? widget.name, sub: user['id'] ?? widget.email), 
          token: token
        );
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Verification successful! Logging in..."), backgroundColor: Colors.green)
           );
           // Navigate to Main App
           Navigator.pushReplacement( context, MaterialPageRoute(builder: (_) => MainNavigator()));
           return; // Success hone par return
        }
      } else {
         // FAILURE: OTP galat hai ya server error hai
         final errorData = json.decode(response.body);
         error = errorData['message'] ?? 'OTP verification failed. Status: ${response.statusCode}';
      }
    } catch (e) {
      // NETWORK/CONNECTION ERROR
      error = 'Network error: Could not connect to verification service.';
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
        key: _formKey, // Form key add kiya
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("OTP sent to ${widget.email}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.indigo)),
              const SizedBox(height: 20),
              TextFormField( // TextFormField use kiya for validation
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
              // Error message field hata diya, SnackBar use hoga
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------ 🟢 HOME SCREEN (Const Removed) ------------------
class HomePage extends StatefulWidget {
  HomePage({super.key}); // FIX: const removed
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> helpers = [
    {"name": "Ramesh", "skill": "Electrician", "price": 450, "image": ""},
    {"name": "Suresh", "skill": "Plumber", "price": 300, "image": ""},
    {"name": "Anita", "skill": "Cleaner", "price": 250, "image": ""},
    {"name": "Babu", "skill": "Carpenter", "price": 600, "image": ""},
  ];
  bool loading = false; 

  @override
  void initState() {
    super.initState();
    // _loadHelpers();
  }

  void _filterByCategory(String category) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filtering helpers by: $category'))
    );
    print('Filtered by: $category');
  }

  Future<void> _loadHelpers() async {
    setState(() => loading = true);
    await Future.delayed(const Duration(seconds: 1)); 
    if (mounted) setState(() => loading = false);
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
                    GridView.builder(
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
                      child: Image.network(imgUrl, fit: BoxFit.cover),
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

// ------------------ 🟢 BOOKING SCREEN ------------------
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
  
  // 🌟 FINAL FIX: Real API Call structure for booking
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
        // NOTE: Yahan par customer ki current location bhi bhej sakte hain (Geolocator se lekar)
    };
    
    // 1. API Endpoint
    final uri = Uri.parse('$mongoApiBase/bookings/create'); 
    
    try {
        final response = await http.post(
            uri,
            headers: {
                'Content-Type': 'application/json',
                // Auth Token bhejna mandatory hai
                'Authorization': 'Bearer ${tempAuth._token}', 
            },
            body: json.encode(bookingPayload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
            // SUCCESS
            if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                      content: Text('Booking Successful! Helper ${widget.helperName} assigned.'),
                      backgroundColor: Colors.green,
                   )
                 );
                 // Navigate to Bookings Tab/Home
                 Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(builder: (context) => MainNavigator()), 
                   (Route<dynamic> route) => false
                 );
            }
        } else {
            // FAILURE: Agar server se error (e.g., 400, 500) aaya
            final errorData = json.decode(response.body);
            error = errorData['message'] ?? 'Booking failed with status code ${response.statusCode}';
        }

    } catch (e) {
        // NETWORK/CONNECTION ERROR
        error = 'Network error: Could not connect to booking service.';
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

// ------------------ 🟢 HELPER DETAIL PAGE ------------------
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
