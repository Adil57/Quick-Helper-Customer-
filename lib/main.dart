// lib/main.dart (Final Code - Class Order Corrected)

import 'package:flutter/material.dart';
import 'package:auth0_flutter/auth0_flutter.dart'; 
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http; 
// import 'package:provider/provider.dart'; // Provider Subah add karna

// -----------------------------------------------------------------------------
// GLOBAL CONFIGURATION (MANDATORY TO REPLACE)
// -----------------------------------------------------------------------------
const String mongoApiBase = "https://YOUR_LIVE_RENDER_URL/api"; 
const String auth0Domain = "adil888.us.auth0.com"; 
const String auth0ClientId = "OdsfeU9MvAcYGxK0Vd8TAlta9XAprMxx"; 
const String auth0RedirectUri = "com.quickhelper.app://login-callback"; 

// 🟢 Auth0 Instance
final Auth0 auth0 = Auth0(auth0Domain, auth0ClientId);

// -----------------------------------------------------------------------------
// ❌ DUMMY STATE MANAGEMENT (COMPILE ONLY)
// -----------------------------------------------------------------------------
class UserAuth {
  UserProfile? _user;
  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  void setUser(UserProfile? user) { _user = user; }
  String? get userId => "temp_user_id_001";
  Future<void> logout(BuildContext context) async {}
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

// ---------------- LOGIN / REGISTER SCREENS ---------------- //
// [LoginScreen, RegisterScreen, MainNavigator classes remain here]
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

  Future<void> loginWithAuth0() async { /* ... logic ... */ }
  Future<void> registerUser() async { /* ... logic ... */ }

  @override
  Widget build(BuildContext context) { /* ... UI ... */
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
  Future<void> registerUser() async { /* ... logic ... */ }

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

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});
  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}
class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomePage(), 
    const Center(child: Text("Services Screen (TODO)")), 
    const Center(child: Text("Activity/Bookings Screen (TODO)")), 
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], 
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.miscellaneous_services_outlined), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}

// ------------------ 🟢 MOVED: BOOKING SCREEN ------------------
class BookingScreen extends StatefulWidget {
  final String helperName;
  final String helperSkill;
  final int price;

  const BookingScreen({super.key, required this.helperName, required this.helperSkill, required this.price});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}
// ✅ FIX: Missing brace of _BookingScreenState is now correctly closed
class _BookingScreenState extends State<BookingScreen> { 
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  double estimatedHours = 2.0;
  bool isCreatingBooking = false;
  Future<void> _selectDate(BuildContext context) async { /* ... logic ... */ }
  double get totalCost => estimatedHours * widget.price * 1.2; 
  Future<void> _createBooking() async { /* ... logic ... */ }
  Widget _buildDatePicker() { /* ... UI ... */ return ListTile(leading: const Icon(Icons.calendar_month, color: Colors.indigo),title: const Text('Service Date'),subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),trailing: TextButton(onPressed: () => _selectDate(context),child: const Text('CHANGE', style: TextStyle(color: Colors.indigo)),),); }
  Widget _buildTimeSlider() { /* ... UI ... */ return Column(crossAxisAlignment: CrossAxisAlignment.start,children: [Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),child: Text('Estimated Hours: ${estimatedHours.toStringAsFixed(1)} hours',style: const TextStyle(fontWeight: FontWeight.bold),),),Slider(value: estimatedHours,min: 1.0,max: 8.0,divisions: 14,label: estimatedHours.toStringAsFixed(1),activeColor: Colors.indigo,onChanged: (double value) {setState(() {estimatedHours = value;});},),],);}
  Widget _buildCostSummary() { /* ... UI ... */ return Container(padding: const EdgeInsets.all(16),decoration: BoxDecoration(color: Colors.indigo.shade50,borderRadius: BorderRadius.circular(12),),child: Column(children: [_costRow("Helper Rate (${widget.price}/hr)", "₹${(estimatedHours * widget.price).toStringAsFixed(0)}"),_costRow("Service Fee (20%)", "₹${(totalCost - (estimatedHours * widget.price)).toStringAsFixed(0)}"),const Divider(),_costRow("TOTAL COST", "₹${totalCost.toStringAsFixed(0)}", isTotal: true),],),);}
  Widget _costRow(String title, String amount, {bool isTotal = false}) { /* ... UI ... */ return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0),child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [Text(title, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, fontSize: isTotal ? 16 : 14)),Text(amount, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, fontSize: isTotal ? 16 : 14, color: isTotal ? Colors.indigo : Colors.black)),],),);}


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

// ------------------ 🟢 MOVED: HELPER DETAIL PAGE ------------------
class HelperDetailPage extends StatelessWidget {
  final String helperName; 
  final String helperSkill;
  final int price;
  final String imgUrl;

  const HelperDetailPage(
      {super.key,
      required this.helperName,
      required this.helperSkill,
      required this.price,
      required this.imgUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(helperName)),
      body: Column(
        children: [
          Expanded(
            child: imgUrl.isEmpty
                ? Container(color: Colors.grey[300])
                : Image.network(imgUrl, width: double.infinity, fit: BoxFit.cover),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(helperSkill,
                    style:
                        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("₹$price per hour",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // NAVIGATE TO BOOKING SCREEN
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
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.indigo),
                  child: const Text("Book Now", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// HOME SCREEN (CONTENT)
// ---------------------------------------------------------
// [HomePage remains here]
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> helpers = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _loadHelpers();
  }
  // [Load helpers logic]
  Future<void> _loadHelpers() async {
    setState(() => loading = true);
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
               // Navigation to Account tab of MainNavigator (Optional advanced routing)
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
                    // [UI Content (Banner, Categories, Grid) remains the same]
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
                          h["price"] ?? 0
