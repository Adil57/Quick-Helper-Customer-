import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

// --- Global App Constants ---
const String APP_NAME = "Quick Helper (Customer)";
const double AVG_HELPER_RATE_PER_HOUR = 145;
const double APP_COMMISSION_PER_HOUR = 20;

// --- Utility Functions ---
double calculateCost(double hours) {
  final helperEarnings = hours * AVG_HELPER_RATE_PER_HOUR;
  final appCommission = hours * APP_COMMISSION_PER_HOUR;
  return helperEarnings + appCommission;
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371;
  final dLat = (lat2 - lat1) * (math.pi / 180);
  final dLon = (lon2 - lon1) * (math.pi / 180);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) + 
      math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) * 
      math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.asin(math.sqrt(a));
  return R * c;
}

// --- Dummy Local User ---
class LocalUser {
  final String uid;
  final String email;
  final bool isGuest;

  LocalUser({required this.uid, required this.email, this.isGuest = true});
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

// --- Authentication Wrapper (Mock) ---
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  LocalUser? user;

  @override
  void initState() {
    super.initState();
    // Simulate anonymous login
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        user = LocalUser(uid: 'guest_user_id', email: 'guest@quickhelper.com');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );
    }

    return BookingScreen(user: user!);
  }
}

// --- Main Booking Screen ---
class BookingScreen extends StatefulWidget {
  final LocalUser user;
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

  void _fetchHelperData() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          helperList = [
            {'name': 'Rakesh Sharma', 'specialty': 'Electrician', 'distance': '1.2', 'rating': 4.8, 'id': 'h1'},
            {'name': 'Sunita Devi', 'specialty': 'Cleaning', 'distance': '2.5', 'rating': 4.5, 'id': 'h2'},
          ];
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = calculateCost(estimatedHours);
    final helperEarnings = estimatedHours * AVG_HELPER_RATE_PER_HOUR;
    final appCommission = estimatedHours * APP_COMMISSION_PER_HOUR;
    final nearestHelper = helperList.isNotEmpty ? helperList.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(APP_NAME, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Current Location: Malad West, Mumbai", style: TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Map Placeholder
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
                    const Icon(Icons.map, size: 40, color: Colors.indigo),
                    const SizedBox(height: 8),
                    Text(nearestHelper != null ? "Nearest Helper: ${nearestHelper['distance']} KM" : "Searching...", style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Helper List
            const Text("Available Helpers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (isLoading) const Center(child: CircularProgressIndicator(color: Colors.indigo)),
            if (!isLoading && helperList.isEmpty) const Text("No Helpers Found.", style: TextStyle(color: Colors.red)),
            ...helperList.map((h) => HelperCard(helper: h)).toList(),
            const SizedBox(height: 20),

            // Task Selection
            const Text("1. Select Your Service", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        const SizedBox(height: 4),
                        Text((task['name'] as String).split(' ')[0], textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black)),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Estimated Hours
            const Text("2. Estimated Hours Required", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${estimatedHours.toStringAsFixed(1)} Hour(s)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const Icon(Icons.access_time, color: Colors.indigo),
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

            const SizedBox(height: 20),

            // Cost Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigo.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("3. Cost Breakdown (Estimate)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade800)),
                  const SizedBox(height: 12),
                  _buildCostRow("Helper's Earnings", "₹${helperEarnings.toStringAsFixed(0)}"),
                  _buildCostRow("App Commission", "₹${appCommission.toStringAsFixed(0)}", isCommission: true),
                  Divider(height: 20, color: Colors.indigo.shade200),
                  _buildCostRow("Total Cost", "₹${totalCost.toStringAsFixed(0)}", isTotal: true),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Center(
              child: ElevatedButton(
                onPressed: helperList.isEmpty ? null : () => {}, // Placeholder
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  backgroundColor: helperList.isEmpty ? Colors.grey : Colors.green,
                ),
                child: Text("Proceed to Payment (₹${totalCost.toStringAsFixed(0)})", style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String title, String amount, {bool isCommission = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.indigo.shade900 : Colors.black87)),
          Text(amount, style: TextStyle(fontSize: isTotal ? 22 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, color: isCommission ? Colors.red : Colors.black)),
        ],
      ),
    );
  }
}

class HelperCard extends StatelessWidget {
  final Map<String, dynamic> helper;
  const HelperCard({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.green, width: 4))),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person, color: Colors.indigo)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(helper['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(helper['specialty'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [Icon(Icons.star, color: Colors.yellow.shade800, size: 16), Text(helper['rating']?.toString() ?? 'N/A')]),
                Text("${helper['distance']} KM away", style: const TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
