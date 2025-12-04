// lib/main.dart (Final Code: MongoDB + Auth0 SDK)

import 'package:flutter/material.dart';
import 'package:auth0_flutter/auth0_flutter.dart'; // 🟢 New Auth0 SDK
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http; 


// -----------------------------------------------------------------------------
// GLOBAL CONFIGURATION (MANDATORY TO REPLACE)
// -----------------------------------------------------------------------------

// ⚠️ 1. RENDER SERVER BASE URL (Tumhara Render deploy kiya hua URL)
const String mongoApiBase = "https://quick-helper-backend.onrender.com/api"; 

// ⚠️ 2. AUTH0 DOMAIN (e.g., dev-abc1234.us.auth0.com)
const String auth0Domain = "YOUR_AUTH0_DOMAIN"; 

// ⚠️ 3. AUTH0 CLIENT ID
const String auth0ClientId = "YOUR_AUTH0_CLIENT_ID"; 

// ⚠️ 4. AUTH0 REDIRECT URI (Must match Auth0 dashboard's 'Allowed Callback URLs')
const String auth0RedirectUri = "com.quickhelper.app://login-callback"; 


// 🟢 Auth0 Instance
final Auth0 auth0 = Auth0(auth0Domain, auth0ClientId);


// -----------------------------------------------------------------------------
// MAIN ENTRY
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
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.indigo),
      home: const LoginScreen(),
    );
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

  // 🟢 AUTH0 LOGIN FUNCTION (Using auth0_flutter SDK)
  Future<void> loginWithAuth0() async {
      setState(() {
        _error = null;
        isLoading = true;
      });

      try {
        await auth0.webAuthentication(scheme: auth0RedirectUri.split('://').first).login();
        
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomePage()));
        }

      } on Exception catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Auth0 Login Failed: ${e.toString()}';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_error!)),
            );
          });
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
  }

  // 🔴 Register User Function (Backend API call placeholder)
  Future<void> registerUser() async {
    setState(() => isLoading = true);
    // [... API call logic ... Removed for brevity, same as last time]
    try {
      final response = await http.post(
        Uri.parse("$mongoApiBase/register"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": "Test User",
          "email": email.text.trim(),
          "password": password.text.trim()
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomePage()));
        }
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle network error
    }

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
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
                  : const Text("Log in with Auth0"),
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

// [Rest of RegisterScreen, HomePage, HelperDetailPage classes remains the same as before]
// ... (The rest of your code from RegisterScreen onwards)
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

    try {
      final response = await http.post(
        Uri.parse("$mongoApiBase/register"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": name.text.trim(),
          "email": email.text.trim(),
          "password": password.text.trim()
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomePage()));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Register failed: ${response.statusCode} ${response.body}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network Error: $e")),
        );
      }
    }

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
// HOME SCREEN — FETCHING DATA FROM RENDER API
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
    loadHelpers();
  }

  // -------- LOAD HELPERS (RENDER API) -------- //
  Future<void> loadHelpers() async {
    setState(() => loading = true);

    try {
      final response = await http.get(Uri.parse("$mongoApiBase/helpers"));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            helpers = jsonDecode(response.body);
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            loading = false;
            helpers = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load helpers: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          helpers = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network Error loading helpers: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Welcome!",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
               // Log out and navigate back to LoginScreen
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
    );
  }

  // -------- CATEGORY WIDGET -------- //
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
  
  // -------- HELPER CARD -------- //
  Widget helperCard(String name, String skill, int price, String imgUrl) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => HelperDetailPage(
                      name: name,
                      skill: skill,
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

// ---------------------------------------------------------
// HELPER DETAIL PAGE
// ---------------------------------------------------------

class HelperDetailPage extends StatelessWidget {
  final String name;
  final String skill;
  final int price;
  final String imgUrl;

  const HelperDetailPage(
      {super.key,
      required this.name,
      required this.skill,
      required this.price,
      required this.imgUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
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
                Text(skill,
                    style:
                        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("₹$price per hour",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Booking ${name}...")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                  child: const Text("Book Now"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
