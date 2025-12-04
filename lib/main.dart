import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:math' as math; // CRITICAL FIX 1: math library ko prefix (math.) diya taaki functions clash na hon

// --- SERVICE API KEYS (Placeholders) ---
const String RAZORPAY_PUBLISHABLE_KEY = "rzp_test_YOUR_RAZORPAY_PUBLISHABLE_KEY_HERE"; 

// --- Global App Constants ---
const String APP_NAME = "Quick Helper (Customer)";
const double AVG_HELPER_RATE_PER_HOUR = 145;
const double APP_COMMISSION_PER_HOUR = 20;
const Map<String, double> USER_LOCATION = {'lat': 19.1834, 'lng': 72.8407}; // Mumbai location

// --- Utility Functions ---
double calculateCost(double hours) {
  final helperEarnings = hours * AVG_HELPER_RATE_PER_HOUR;
  final appCommission = hours * APP_COMMISSION_PER_HOUR;
  return helperEarnings + appCommission;
}

// Haversine formula FIX
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    // CRITICAL FIX 2: math.pi use kiya
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);
    final a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) + // FIX: math.sin()
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) * math.sin(dLon / 2) * math.sin(dLon / 2); // FIX: math.cos()
    final c = 2 * math.asin(math.sqrt(a)); // FIX: math.asin(math.sqrt(a))
    return R * c;
}

// --- MAIN WIDGET ---

void main() async {
  runApp(const QuickHelperApp());
}

class QuickHelperApp extends StatelessWidget {
  const QuickHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: APP_NAME,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
    );
  }
}

// --- Authentication Wrapper ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
          );
        }
        
        final user = snapshot.data;
        if (user == null || user.isAnonymous) {
          return LoginPage();
        }
        
        return BookingScreen(user: user);
      },
    );
  }
}

// --- Login/Signup Screen (No changes needed) ---
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;
  String? error;

  Future<void> handleSubmit() async {
    try {
      // Simulate auth process
      await Future.delayed(Duration(seconds: 1)); 
      
    } on FirebaseAuthException catch (e) {
      setState(() { error = e.message; });
    } catch (e) {
      setState(() { error = "Auth Failed (Check Firebase setup in APK)"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(APP_NAME, style: TextStyle(color: Colors.white)), backgroundColor: Colors.indigo, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isLogin ? "Customer Login" : "Create Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
              SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email Address", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password (min 6 chars)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              if (error != null) 
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(error!, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: handleSubmit,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.indigo,
                ),
                child: Text(isLogin ? "Log In" : "Create Account", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    error = null;
                  });
                },
                child: Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Log In", style: TextStyle(color: Colors.indigo)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Main Booking Screen (Logic intact) ---
class BookingScreen extends StatefulWidget {
  final User user;
  const BookingScreen({super.key, required this.user});

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String selectedTask = 'General Assistant';
  double estimatedHours = 2.0;
  List<Map<String, dynamic>> helperList = [];
  bool isLoading = true;

  final List<Map<String, dynamic>> tasks = [
    {'name': 'General Assistant', 'icon': Icons.handyman},
    {'name': 'Plumbing Service', 'icon': Icons.plumbing},
    {'name': 'Deep Cleaning', 'icon': Icons.cleaning_services},
    {'name': 'Electrician', 'icon': Icons.flash_on},
  ];

  @override
  void initState() {
    super.initState();
    _fetchHelperData();
  }

  // Helper Data Fetching Logic (Live APK mein chalta hai)
  void _fetchHelperData() {
    Future.delayed(Duration(seconds: 2)).then((_) {
      if(mounted) {
          setState(() {
            // Simulated Data
            helperList = [
                {'name': 'Rakesh Sharma', 'specialty': 'Electrician', 'distance': '1.2', 'rating': 4.8, 'id': 'h1'},
                {'name': 'Sunita Devi', 'specialty': 'Cleaning', 'distance': '2.5', 'rating': 4.5, 'id': 'h2'},
            ];
            isLoading = false;
          });
      }
    });
  }

  // Booking Logic (Called after Payment Simulation)
  Future<void> handleBooking() async {
    final nearestHelper = helperList.isNotEmpty ? helperList.first : null;
    if (nearestHelper == null) return;

    final totalCost = calculateCost(estimatedHours);
    // Firestore setup and order saving logic here...
    
    // Show Success Message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Order Processed! Total: ₹${totalCost.toStringAsFixed(0)}"),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = calculateCost(estimatedHours);
    final helperEarnings = estimatedHours * AVG_HELPER_RATE_PER_HOUR;
    final appCommission = estimatedHours * APP_COMMISSION_PER_HOUR;
    final nearestHelper = helperList.isNotEmpty ? helperList.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(APP_NAME, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Location Bar ---
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.indigo),
                  SizedBox(width: 8),
                  Expanded(child: Text("Current Location: Malad West, Mumbai", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            SizedBox(height: 20),

            // --- Map Tracker Simulation (This will be a real map in the final APK) ---
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 40, color: Colors.indigo),
                    SizedBox(height: 8),
                    Text("Live Map Tracker (Placeholder)", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(nearestHelper != null ? "Nearest Helper: ${nearestHelper['distance']} KM" : "Searching...", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // --- Helper List ---
            Text("Available Helpers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            if (isLoading) Center(child: CircularProgressIndicator(color: Colors.indigo, strokeWidth: 3)),
            if (!isLoading && helperList.isEmpty) Text("No Helpers Found.", style: TextStyle(color: Colors.red)),
            ...helperList.map((h) => HelperCard(helper: h)).toList(),
            SizedBox(height: 20),


            // --- Task Selection ---
            Text("1. Select Your Service", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final isSelected = selectedTask == task['name'];
                return GestureDetector(
                  onTap: () => setState(() => selectedTask = task['name'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      border: Border.all(color: isSelected ? Colors.indigo.shade800 : Colors.grey.shade300, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(task['icon'] as IconData, color: isSelected ? Colors.white : Colors.indigo),
                        SizedBox(height: 4),
                        Text((task['name'] as String).split(' ')[0], textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black)),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),

            // --- Estimated Hours ---
            Text("2. Estimated Hours Required", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${estimatedHours.toStringAsFixed(1)} Hour(s)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      Icon(Icons.access_time, color: Colors.indigo),
                    ],
                  ),
                  Slider(
                    value: estimatedHours,
                    min: 1.0,
                    max: 8.0,
                    divisions: 14, 
                    label: estimatedHours.toStringAsFixed(1),
                    onChanged: (double value) {
                      setState(() { estimatedHours = value; });
                    },
                    activeColor: Colors.indigo,
                    inactiveColor: Colors.indigo.shade100,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // --- Cost Breakdown ---
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigo.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("3. Cost Breakdown (Estimate)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade800)),
                  SizedBox(height: 12),
                  _buildCostRow("Helper's Earnings", "₹${helperEarnings.toStringAsFixed(0)}"),
                  _buildCostRow("App Commission", "₹${appCommission.toStringAsFixed(0)}", isCommission: true),
                  Divider(height: 20, color: Colors.indigo.shade200),
                  _buildCostRow("Total Cost", "₹${totalCost.toStringAsFixed(0)}", isTotal: true),
                ],
              ),
            ),
            SizedBox(height: 32),

            // --- Proceed to Payment Button ---
            Center(
              child: ElevatedButton(
                onPressed: helperList.isEmpty ? null : () => {}, // Payment modal call
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  backgroundColor: helperList.isEmpty ? Colors.grey : Colors.green,
                ),
                child: Text("Proceed to Payment (₹${totalCost.toStringAsFixed(0)})", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildCostRow(String title, String amount, {bool isCommission = false, bool isTotal = false}) {
    // ... Cost Row UI logic
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.indigo.shade900 : Colors.black87)),
          Text(amount, style: TextStyle(
            fontSize: isTotal ? 22 : 14, 
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isCommission ? Colors.red : Colors.black,
          )),
        ],
      ),
    );
  }

  void _showPaymentModal(BuildContext context, double amount) {
    // ... Payment modal logic
  }
}

class HelperCard extends StatelessWidget {
  final Map<String, dynamic> helper;
  const HelperCard({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Container(
            decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.green, width: 4)),
            ),
            padding: EdgeInsets.all(12),
            child: Row(
                children: [
                    CircleAvatar(child: Icon(Icons.person, color: Colors.indigo)),
                    SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(helper['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(helper['specialty'], style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                        ),
                    ),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                            Row(children: [Icon(Icons.star, color: Colors.yellow.shade800, size: 16), Text(helper['rating']?.toString() ?? 'N/A')]),
                            Text("${helper['distance']} KM away", style: TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                    ),
                ],
            ),
        ),
    );
  }
}

class UserPlaceholder extends User {
    // ... UserPlaceholder implementation
    @override String get uid => 'guest_user_id';
    @override String? get email => 'guest@quickhelper.com';
    @override bool get isAnonymous => true;
    @override String? get displayName => 'Quick Helper Guest';
    @override String? get phoneNumber => null;
    @override String? get photoURL => null;
    @override List<UserInfo> get providerData => [];
    @override String get providerId => 'firebase';
    @override String get tenantId => 'tenant';
    @override DateTime get metadataCreationTime => DateTime.now();
    @override DateTime get metadataLastSignInTime => DateTime.now();
    @override bool get emailVerified => true;
    @override void delete() {}
    @override Future<String> getIdToken([bool forceRefresh = false]) => Future.value('token');
    @override Future<void> reload() async {}
    @override Future<void> linkWithCredential(AuthCredential credential) async {}
    @override List<String> get providerIds => [];
    @override Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) => throw UnimplementedError();
    @override Future<void> updateEmail(String newEmail) async {}
    @override Future<void> updatePassword(String newPassword) async {}
    @override Future<void> updatePhoneNumber(PhoneAuthCredential credential) async {}
    @override Future<void> updatePhotoURL(String? photoURL) async {}
    @override Future<void> updateProfile({String? displayName, String? photoURL}) async {}
    @override Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) async => t
