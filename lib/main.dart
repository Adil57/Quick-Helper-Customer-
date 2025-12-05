// lib/main.dart (FINAL FIXED CODE - CLEANED SYNTAX)

import 'package:flutter/material.dart';
import 'package:auth0_flutter/auth0_flutter.dart'; 
import 'package:auth0_flutter_platform_interface/auth0_flutter_platform_interface.dart'; 
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http; 
// import 'package:provider/provider.dart'; 


// -----------------------------------------------------------------------------
// GLOBAL CONFIGURATION (MANDATORY TO REPLACE)
// -----------------------------------------------------------------------------

const String mongoApiBase = "https://quick-helper-backend.onrender.com/api"; 
const String auth0Domain = "adil888.us.auth0.com"; 
const String auth0ClientId = "OdsfeU9MvAcYGxK0Vd8TAlta9XAprMxx"; 
const String auth0RedirectUri = "com.quickhelper.app://login-callback"; 


// 🟢 Auth0 Instance
final Auth0 auth0 = Auth0(auth0Domain, auth0ClientId);


// -----------------------------------------------------------------------------
// ❌ DUMMY STATE MANAGEMENT 
// -----------------------------------------------------------------------------
class UserAuth {
  UserProfile? _user = const UserProfile(name: "Test User", sub: "auth0|test"); 
  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
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
      return const MainNavigator(); 
    }
    return const LoginScreen();
  }
}

// ----------------- 🟢 MAIN NAVIGATOR ----------------- //
class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

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


// ---------------- LOGIN / REGISTER SCREENS ---------------- //
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isLoading = false;
  String? _error;

  Future<void> loginWithAuth0() async { 
      setState(() { _error = null; isLoading = true; });
      try {
        final result = await auth0.webAuthentication(scheme: auth0RedirectUri.split('://').first).login();
        if (mounted) {
          tempAuth.setUser(result.user); 
          Navigator.pushReplacement( context, MaterialPageRoute(builder: (_) => const MainNavigator()));
        }
      } on Exception catch (e) {
        if (mounted) {
          setState(() { _error = 'Auth0 Login Failed: Check Redirect URL/Network.'; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_error!)));
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
  }

  Future<void> registerUser() async {
    setState(() => isLoading = true);
    // [API call logic]
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome Back!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 40),

            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email (Ignored by Auth0)"),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password (Ignored by Auth0)"),
            ),

            const SizedBox(height: 20),
            
            // 🟢 AUTH0 LOGIN BUTTON
            ElevatedButton(
              onPressed: isLoading ? null : loginWithAuth0, 
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.indigo),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Log in with Auth0", style: TextStyle(color: Colors.white)),
            ),
            
            if (_error != null) 
              Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),

            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              child: const Text("Create an account (API Test)"),
            )
          ],
        ),
      ),
    );
  }
}

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
  Future<void> registerUser() async {
    setState(() => isLoading = true);
    // [API call logic]
    if (mounted) setState(() => isLoading = false);
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


// ---------------------------------------------------------
// HOME SCREEN (CONTENT)
// ---------------------------------------------------------
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


// ------------------ 🟢 BOOKING SCREEN (FIXED SYNTAX) ------------------
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
       // We should navigate back to the previous screen or root navigator
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

  // FIX: _buildTimeSlider code is now correctly closed
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
          activeColor
