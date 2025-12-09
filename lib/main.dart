// lib/main.dart (FINAL WORKING VERSION WITH LIVE MAP & OTP FLOW - SIZE FIXES)

import 'package:flutter/material.dart';
import 'package:auth0_flutter/auth0_flutter.dart'; 
import 'package:auth0_flutter_platform_interface/auth0_flutter_platform_interface.dart'; 
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http; 

// 🟢 MAP IMPORT: Mapbox library
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; 

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
// DUMMY STATE MANAGEMENT (Renamed to avoid conflict with Auth0's UserProfile)
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
// MAIN ENTRY & APP THEME (FIXED: Token + Initialization)
// -----------------------------------------------------------------------------
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  MapboxOptions.setAccessToken(
    const String.fromEnvironment('ACCESS_TOKEN'),
  );

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

// ----------------- 🟢 MAIN NAVIGATOR (Tab Order Updated) ----------------- //
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
            const HomePage(),
            const MapViewScreen(), // Tab 1: Map View Screen
            const Center(child: Text("Bookings Screen")), // Tab 2: Bookings
            const Center(child: Text("Chat Screen")), // Tab 3: Chat
            const AccountScreen(), // Tab 4: Account
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

// ---------------- ACCOUNT SCREEN (No Change) ---------------- //
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

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
// 🟢 MAP VIEW SCREEN (MAPBOX + KILL SWITCH IMPLEMENTATION - FIXED)
// -----------------------------------------------------------------------------
class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? annotationManager;
  
  // 🌟 KILL SWITCH VARIABLES
  bool _isMapServiceEnabled = true; // Default: Enabled
  bool _isLoadingStatus = true;    // Check status in initState

  @override
  void initState() {
    super.initState();
    _checkMapStatus(); // Map status check karo
  }

  // 🌟 Function to check the Kill Switch Status from Backend
  Future<void> _checkMapStatus() async {
    setState(() {
      _isLoadingStatus = true;
    });
    try {
      final response = await http.get(Uri.parse('$mongoApiBase/map/status'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'disabled') {
          _isMapServiceEnabled = false;
        }
      } else {
        _isMapServiceEnabled = false; 
      }
    } catch (e) {
      print('Map status check failed: $e');
      _isMapServiceEnabled = false;
    }
    setState(() {
      _isLoadingStatus = false;
    });
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    annotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    
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
    // 1. Loading State
    if (_isLoadingStatus) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // 2. 🌟 Kill Switch Applied (Service Disabled)
    if (!_isMapServiceEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text("Map Service Disabled")),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Map service is temporarily unavailable due to potential budget limits. Please check back later.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    // 3. Map Active (Default)
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Helpers (MapBox)")),
      body: MapWidget(
        key: GlobalKey(),
        styleUri: MapboxStyles.MAPBOX_STREETS, 
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(72.8777, 19.0760)), // Mumbai
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
  String? _error;

  // MODIFIED: API Login Call
  Future<void> loginUser() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      setState(() => _error = "Please enter email and password.");
      return;
    }
    setState(() => isLoading = true);
    _error = null;

    try {
      final response = await http.post(
        // TODO: Login API Endpoint
        Uri.parse('$mongoApiBase/auth/login'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email.text, 'password': password.text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = data['user'];
        final token = data['token'];

        tempAuth.setUser(
          AppUserProfile(name: user['name'] ?? 'Local User', sub: user['id'] ?? user['email']), 
          token: token
        );
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Login successful!"))
           );
           Navigator.pushReplacement( context, MaterialPageRoute(builder: (_) => MainNavigator()));
        }
      } else {
         final errorData = json.decode(response.body);
         setState(() => _error = errorData['message'] ?? 'Login failed. Check credentials.');
      }
    } catch (e) {
      setState(() => _error = 'Network error or Invalid API response.');
      print('Login Error: $e');
    }
    
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Custom Login")),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Login with Email/Password",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 40),

            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
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
            
            if (_error != null) 
              Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),

            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              child: const Text("Create an account (OTP Required)"),
            )
          ],
        ),
      ),
    );
  }
}

// ---------------- REGISTER SCREEN (OTP FLOW START) ---------------- //
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isLoading = false;
  String? _error;
  
  // MODIFIED: Start OTP Registration Process
  Future<void> registerUserStartOTP() async {
    if (name.text.isEmpty || email.text.isEmpty || password.text.isEmpty) {
      setState(() => _error = "Please fill all fields.");
      return;
    }
    setState(() => isLoading = true);
    _error = null;

    try {
      final response = await http.post(
        // TODO: Register API Endpoint (OTP Send)
        Uri.parse('$mongoApiBase/auth/register-otp'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name.text, 'email': email.text, 'password': password.text}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) { 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP sent to your email. Please verify."))
          );
          // Navigate to OTP Verification Screen
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              name: name.text, 
              email: email.text, 
              password: password.text,
              isRegistration: true, // Registration flow hai
            )
          ));
        }
      } else {
         final errorData = json.decode(response.body);
         setState(() => _error = errorData['message'] ?? 'Registration failed. User may already exist.');
      }
    } catch (e) {
      setState(() => _error = 'Network error or Invalid API response.');
      print('Registration Start OTP Error: $e');
    }
    
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register (OTP Required)")),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password (min 6 chars)"),
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
            if (_error != null) 
              Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}

// ---------------- NEW: OTP VERIFICATION SCREEN ---------------- //
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
  String? _error;

  Future<void> verifyOTP() async {
    if (otp.text.isEmpty || otp.text.length < 4) { // Assuming 4 digit OTP
      setState(() => _error = "Please enter the 4-digit OTP.");
      return;
    }
    setState(() => isLoading = true);
    _error = null;

    try {
      final response = await http.post(
        // TODO: Verify OTP API Endpoint
        Uri.parse('$mongoApiBase/auth/verify-otp'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email, 
          'otp': otp.text,
          'name': widget.isRegistration ? widget.name : null, // Name sirf registration mein chahiye
          'password': widget.isRegistration ? widget.password : null,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = data['user'];
        final token = data['token'];

        tempAuth.setUser(
          AppUserProfile(name: user['name'] ?? widget.name, sub: user['id'] ?? widget.email), 
          token: token
        );
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("${widget.isRegistration ? 'Registration' : 'Login'} successful!"))
           );
           Navigator.pushReplacement( context, MaterialPageRoute(builder: (_) => MainNavigator()));
        }
      } else {
         final errorData = json.decode(response.body);
         setState(() => _error = errorData['message'] ?? 'OTP verification failed. Try again.');
      }
    } catch (e) {
      setState(() => _error = 'Network error or Invalid API response.');
      print('OTP Verification Error: $e');
    }
    
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("OTP sent to ${widget.email}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.indigo)),
            const SizedBox(height: 20),
            TextField(
              controller: otp,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(labelText: "OTP Code"),
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
            if (_error != null) 
              Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// HOME SCREEN
// ---------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});
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
  
  Future<void> _createBooking() async {
    setState(() => isCreatingBooking = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Booking confirmed for \( {widget.helperName}! Total: ₹ \){totalCost.toStringAsFixed(0)}'))
       );
       Navigator.pop(context); 
    }
    if (mounted) setState(() => isCreatingBooking = false);
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
              child: Text("Service Duration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: _buildTimeSlider()),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text("Cost Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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