// lib/main.dart (Final Code - Syntax Fixed for Compile)

import 'package:flutter/material.dart';
import 'package:auth0_flutter/auth0_flutter.dart'; 
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http; 
// import 'package:provider/provider.dart'; // ❌ Provider Temporarily Removed

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
// 🟢 OLD/DUMMY STATE MANAGEMENT (For compile only)
// -----------------------------------------------------------------------------
// Note: Subah tumhein yeh provider se replace karna hai!
class UserAuth {
  UserProfile? _user;
  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  void setUser(UserProfile? user) { _user = user; }
  String? get userId => "temp_user_id_001"; // Dummy ID for compile
  Future<void> logout(BuildContext context) async {}
}
final UserAuth tempAuth = UserAuth(); // Temporary instance

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
    // ❌ FIX: ChangeNotifierProvider removed for compile
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

// ---------------- 🟢 AUTH GATE (Checks Auth Status) ---------------- //
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ FIX: Provider.of replaced with dummy check
    if (tempAuth.isAuthenticated) { 
      return const MainNavigator(); 
    }
    return const LoginScreen();
  }
}


// ---------------- LOGIN SCREEN ---------------- //

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

  // 🟢 AUTH0 LOGIN FUNCTION 
  Future<void> loginWithAuth0() async {
      setState(() {
        _error = null;
        isLoading = true;
      });

      try {
        final result = await auth0.webAuthentication(scheme: auth0RedirectUri.split('://').first).login();
        
        if (mounted) {
          // ❌ FIX: Provider replaced with temporary setter
          tempAuth.setUser(result.user); 
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const MainNavigator()));
        }

      } on Exception catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Auth0 Login Failed: Check Redirect URL/Network.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_error!)),
            );
          });
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
  }

  // 🔴 Register User Function 
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

// ---------------- REGISTER SCREEN ---------------- //
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

// ---------------- 🟢 NEW: MAIN NAVIGATION WIDGET ---------------- //
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(), // 0: Home Page Content
    const Center(child: Text("Services Screen (TODO)")), // 1: Services
    const Center(child: Text("Activity/Bookings Screen (TODO)")), // 2: Activity
    const AccountScreen(), // 3: Account/Profile screen
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

// ---------------------------------------------------------
// HOME SCREEN (CONTENT)
// ---------------------------------------------------------
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

  // -------- LOAD HELPERS (RENDER API) -------- //
  Future<void> _loadHelpers() async {
    setState(() => loading = true);
    // [API call logic remains the same]
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // ❌ FIX: Provider replaced with dummy check
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
                ),
              ),
            ),
    );
  }

  // (categoryItem and helperCard functions remain unchanged)
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
                // ✅ FIX: HelperDetailPage constructor used correct parameters
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


// ---------------- 🟢 NEW: ACCOUNT SCREEN (Profile Page) ---------------- //
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ❌ FIX: Provider replaced with dummy check
    final auth = tempAuth; 
    final userName = auth.user?.name ?? auth.user?.nickname ?? "Customer";

    // ✅ FIX: Missing closing brace of AccountScreen removed from error chain
    return Scaffold(
      appBar: AppBar(title: Text(userName, style: const TextStyle(fontSize: 24))),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            ListTile(
              leading: const CircleAvatar(radius: 25, child: Icon(Icons.person)),
              title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(auth.user?.email ?? "Not Available"),
            ),
            const Divider(height: 10),
            
            // Action Cards 
            _buildActionCard(context, "Help", Icons.help_outline),
            _buildActionCard(context, "Wallet", Icons.account_balance_wallet_outlined),
            _buildActionCard(context, "Safety", Icons.security),
            _buildActionCard(context, "Inbox", Icons.mail_outline),
            
            // Example Promo Card
            _buildPromoCard(), 
            
            // Logout button
            _buildActionCard(context, "Logout", Icons.exit_to_app, isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, {bool isLogout = false}) {
    // ❌ FIX: Provider replaced with dummy logout
    final logoutAction = () => tempAuth.logout(context); 

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title),
        trailing: isLogout ? null : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: isLogout 
            ? logoutAction // Secure Logout
            : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title clicked! (TODO)"))),
      ),
    );
  }

  Widget _buildPromoCard() {
      // ✅ FIX: Missing parentheses fixed, syntax error solved
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
        elevation: 2,
        child: Padding( 
          padding: const EdgeInsets.all(16.0), 
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("You have multiple promos", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("We'll automatically apply the one that saves you the most", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.local_offer, size: 40, color: Colors.purple),
      
