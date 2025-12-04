// lib/main.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// -----------------------------------------------------------------------------
// GLOBAL CONFIGURATION (Make sure to replace placeholders)
// -----------------------------------------------------------------------------

// TODO: AUTH0 CONFIG HERE (Currently unused in the logic below)
const String auth0Domain = "YOUR_AUTH0_DOMAIN";
const String auth0ClientId = "YOUR_AUTH0_CLIENT_ID";
const String auth0RedirectUri = "YOUR_REDIRECT_URI";

// TODO: MONGODB API STRING HERE (Backend endpoint for login/register/helpers)
const String mongoApiBase = "YOUR_MONGODB_BACKEND_ENDPOINT";

// TODO: CONTENTFUL CONFIG HERE (Used for image links/placeholders)
const String contentfulSpaceId = "YOUR_SPACE_ID";
const String contentfulToken = "YOUR_CONTENTFUL_TOKEN";

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
      title: "My App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.blue),
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

  Future<void> loginUser() async {
    // Basic validation
    if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and Password are required.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse("$mongoApiBase/login"));
      request.headers.set('Content-Type', 'application/json');
      request.add(utf8.encode(jsonEncode({
        "email": email.text.trim(),
        "password": password.text.trim()
      })));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        // Assuming API returns user data/token, but for now we navigate:
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomePage()));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login failed: ${response.statusCode} ${body}")),
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
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : loginUser,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Login"),
            ),

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

  Future<void> registerUser() async {
    // Basic validation
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse("$mongoApiBase/register"));
      request.headers.set('Content-Type', 'application/json');
      request.add(utf8.encode(jsonEncode({
        "name": name.text.trim(),
        "email": email.text.trim(),
        "password": password.text.trim()
      })));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomePage()));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Register failed: ${response.statusCode} ${body}")),
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
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : registerUser,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// HOME SCREEN — SWIGGY STYLE
// ---------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Helpers list should ideally be of a specific model type, but dynamic is used here
  List<dynamic> helpers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHelpers();
  }

  // -------- LOAD HELPERS (MONGO API) -------- //
  Future<void> loadHelpers() async {
    try {
      final client = HttpClient();
      final request =
          await client.getUrl(Uri.parse("$mongoApiBase/helpers")); // GET CALL

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            helpers = jsonDecode(body);
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
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // -------- TOP BANNER -------- //
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

                  // -------- CATEGORY SCROLLER -------- //
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        categoryItem("Cleaning", Icons.cleaning_services),
                        categoryItem("Electrician", Icons.electrical_services),
                        categoryItem("Plumber", Icons.build),
                        categoryItem("Painter", Icons.format_paint),
                        categoryItem("Carpenter", Icons.carpenter),
                      ],
                    ),
                  ),
                  

                  const SizedBox(height: 10),

                  // -------- FEATURE TITLE -------- //
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Available Helpers",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 12),

                  // -------- HELPERS GRID -------- //
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
                      // Ensure the keys match your API response exactly!
                      return helperCard(
                        h["name"] ?? "Unknown",
                        h["skill"] ?? "Service", // Check if API key is 'skill' or 'specialty'
                        h["price"] ?? 0,
                        h["image"] ?? "", // Check if API key is 'image' or 'photoUrl'
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
          Icon(icon, size: 34, color: Colors.blue),
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
                    // TODO: Implement Booking Logic/Navigation
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
