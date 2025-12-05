// lib/main.dart (FINAL FIXES APPLIED)

import 'package:flutter/material.dart';
import 'package:auth0_flutter/auth0_flutter.dart'; 
import 'package:auth0_flutter_platform_interface/auth0_flutter_platform_interface.dart'; 
// IMPORT: Auth0 ki UserProfile class is package se aati hai
// import 'package:auth0_flutter_platform_interface/src/user_profile.dart'; 
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http; 


// -----------------------------------------------------------------------------
// GLOBAL CONFIGURATION (MANDATORY TO REPLACE)
// -----------------------------------------------------------------------------

const String mongoApiBase = "https://quick-helper-backend.onrender.com/api"; 
const String auth0Domain = "adil888.us.auth0.com"; 
const String auth0ClientId = "OdsfeU9MvAcYGxK0Vd8TAlta9XAprMxx"; 
const String auth0RedirectUri = "com.quickhelper.app://adil888.us.auth0.com/android/com.example.quick_helper_customer/callback"; 


// 🟢 Auth0 Instance
final Auth0 auth0 = Auth0(auth0Domain, auth0ClientId);


// -----------------------------------------------------------------------------
// ❌ DUMMY STATE MANAGEMENT (FIXED: Using Auth0's UserProfile)
// -----------------------------------------------------------------------------
// ***************************************************************
// ERROR FIX 1: Duplicate UserProfile hata di gayi hai.
// Ab UserAuth class Auth0's UserProfile (jo auth0_flutter_platform_interface se aati hai) use karegi.
// ***************************************************************

class UserAuth {
  // tempAuth ko non-nullable se nullable kiya gaya
  UserProfile? _user; 
  // Initialization mein dummy user set kiya gaya
  UserAuth() {
    _user = const UserProfile(name: "Test User", sub: "auth0|test");
  }

  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  // setUser function mein parameter ko nullable kiya gaya
  void setUser(UserProfile? user) { _user = user; }
  String? get userId => _user?.sub ?? "temp_user_id_001";
  
  Future<void> logout(BuildContext context) async {
     _user = null;
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
// MAIN ENTRY & APP THEME
// -----------------------------------------------------------------------------

void main() {
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
      // ERROR FIX 2: const hataya
      return MainNavigator(); 
    }
    // Now directs to the choice screen
    return const LoginChoiceScreen(); 
  }
}

// -----------------------------------------------------------------------------
// NEW: LOGIN CHOICE SCREEN (The two buttons)
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
          // ERROR FIX 3: Type mismatch solved, setUser now accepts Auth0's UserProfile
          tempAuth.setUser(result.user); 
          // After successful Auth0 login, navigate to main app
          // ERROR FIX 4: const hataya
          Navigator.pushReplacement( context, MaterialPageRoute(builder: (_) => MainNavigator()));
        }
      } on Exception catch (e) {
        if (mounted) {
          // Display a friendly error message for Auth0 issues
          String message = 'Login Failed. Ensure redirect URL and internet connection are correct.';
          setState(() { _error = message; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          print('Auth0 Login Error: $e'); // Print detailed error to console
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
              ElevatedButton.icon(
                icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.lock_open),
                label: Text(isLoading ? "Logging in..." : 'Log in with Auth0 (Google/Social)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                ),
                onPressed: isLoading ? null : loginWithAuth0,
              ),
              const SizedBox(height: 20),

              const Divider(height: 20, thickness: 1, color: Colors.grey),

              const SizedBox(height: 20),
              
              // --- B. NORMAL LOGIN BUTTON ---
              OutlinedButton.icon(
                icon: const Icon(Icons.email, color: Colors.indigo),
                label: const Text('Normal Login (Email/Password)', style: TextStyle(color: Colors.indigo)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.indigo),
                ),
                onPressed: isLoading ? null : () => navigateToCustomLogin(context),
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


// ----------------- 🟢 MAIN NAVIGATOR ----------------- //
class MainNavigator extends StatelessWidget {
  // ERROR FIX 5: const hataya
  MainNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(), 
          children: [
            HomePage(),
            Center(child: Text("Bookings Screen")),
            Center(child: Text("Chat Screen")),
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

// ---------------- ACCOUNT SCREEN ---------------- //
class AccountScreen extends StatelessWidget {
// ... (No major changes here)
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
            ElevatedButton(
              onPressed: () => tempAuth.logout(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MODIFIED: CUSTOM LOGIN SCREEN (For MongoDB/Render API)
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

  // Function for API/MongoDB Login (Simulated)
  Future<void> loginUser() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      setState(() => _error = "Please enter email and password.");
      return;
    }
    setState(() => isLoading = true);
    
    // TODO: Yahan tumhara actual MongoDB/Render API login call aayega
    
    // Simulated Success after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    // Assuming successful login returns user details
    // ERROR FIX 6: const hataya
    tempAuth.setUser(UserProfile(name: "Local User", sub: "local_${email.text}")); 
    
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Login successful!"))
       );
       // ERROR FIX 7: const hataya
       Navigator.pushReplacement( context, MaterialPageRoute(builder: (_) => MainNavigator()));
    }
    
    if (mounted) setState(() {
      isLoading = false;
      _error = null;
    });
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
            ElevatedButton(
              onPressed: isLoading ? null : loginUser, 
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.indigo),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Log in", style: TextStyle(color: Colors.white)),
            ),
            
            if (_error != null) 
              Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),

            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              child: const Text("Create an account"),
            )
          ],
        ),
      ),
    );
  }
}
// lib/main.dart (PART 2/3) - Register, and Home Page (Rest of the code follows...)

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
  
  // FIX: Simulated API call for registration
  Future<void> registerUser() async {
    if (name.text.isEmpty || email.text.isEmpty || password.text.isEmpty) {
      setState(() => _error = "Please fill all fields.");
      return;
    }
    setState(() => isLoading = true);
    
    // TODO: Yahan tumhara actual MongoDB/Render API registration call aayega
    // API Call Simulation: Success after 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // After successful dummy registration, set a temporary user and navigate
    // ERROR FIX 8: const hataya
    tempAuth.setUser(UserProfile(name: name.text, sub: "local_user_${DateTime.now().millisecondsSinceEpoch}"));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful! Logging you in."))
      );
      // ERROR FIX 9: const hataya
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainNavigator()));
    }
    
    if (mounted) setState(() {
      isLoading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
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
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password (min 6 chars)"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : registerUser,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Register"),
            ),
            if (_error != null) 
              Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}
// lib/main.dart (PART 2/3) - Home Page (Rest of the code follows...)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Dummy data for testing HelperDetailPage navigation
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

  // -------- LOAD HELPERS (RENDER API) -------- //
  Future<void> _loadHelpers() async {
    setState(() => loading = true);
    // [API call logic remains the same]
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
               DefaultTabController.of(context).animateTo(3); 
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
    return Container(
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
// lib/main.dart (PART 3/3) - Booking and Helper Detail Pages (Rest of the code follows...)
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
    // [API call logic]
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Booking confirmed for ${widget.helperName}! Total: ₹${totalCost.toStringAsFixed(0)}'))
       );
       Navigator.pop(context); 
    }
    if (mounted) setState(() => isCreatingBooking = false);
  }


  Widget _buildDatePicker() { 
    return ListTile(
      leading: const Icon(Icons.calendar_month, color: Colors.indigo),
      title: const Text('Service Date'),
      subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
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
          _costRow("Helper Rate (${widget.price}/hr)", "₹${(estimatedHours * widget.price).toStringAsFixed(0)}"),
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
            // Helper Info Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.indigo,
              child: Text("Booking ${widget.helperName} (${widget.helperSkill})", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            
            // Date Picker 
            Card(margin: const EdgeInsets.all(16), child: _buildDatePicker()),
            
            // Time Slider
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text("Service Duration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Card(margin: const EdgeInsets.symmetric(horizontal: 16), child: _buildTimeSlider()),
            
            const SizedBox(height: 20),

            // Cost Summary
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text("Cost Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildCostSummary(),
            ),

            const SizedBox(height: 30),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: isCreatingBooking ? null : _createBooking,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: isCreatingBooking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("CONFIRM & PROCEED TO PAYMENT", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
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
            // Helper Image (Placeholder)
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

            // Details
            Text(helperName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(helperSkill, style: const TextStyle(fontSize: 18, color: Colors.indigo)),
            const SizedBox(height: 8),
            Text("Rate: ₹$price / hour", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            
            const SizedBox(height: 20),
            const Divider(),
            
            // Description Placeholder
            const Text("About the Helper", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Rating, location, and review details will be loaded here.",
                style: TextStyle(fontSize: 14, height: 1.5)),
            
            const SizedBox(height: 40),

            // Book Now Button
            ElevatedButton(
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
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("BOOK THIS HELPER", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ... End of file
