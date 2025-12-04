// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Quick Helper (Version A) - Full single-file compile-ready app
// - Login / Register / Guest
// - Home (Swiggy-style) with categories, helpers, map placeholder
// - Helper profile modal with Contentful hook
// - Booking summary + createBooking mock (pretend MongoDB backend via REST)
// - NO Firebase usage / imports
//
// How to supply real keys safely (do NOT hardcode keys in source):
// flutter run --dart-define=API_BASE=https://your-api.example.com \
//              --dart-define=CONTENTFUL_SPACE_ID=xxxx \
//              --dart-define=CONTENTFUL_DELIVERY_TOKEN=xxxx \
//              --dart-define=AUTH0_DOMAIN=yourdomain.auth0.com \
//              --dart-define=AUTH0_CLIENT_ID=xxxx
//
// In this mock-ready build, if dart-define values are missing the app uses
// local mock behaviour so it always compiles and runs.
// -----------------------------------------------------------------------------

const String APP_NAME = "Quick Helper (Customer)";
const double AVG_HELPER_RATE_PER_HOUR = 145;
const double APP_COMMISSION_PER_HOUR = 20;

// Read environment values (may be null in mock mode)
final String? API_BASE = const String.fromEnvironment('API_BASE');
final String? CONTENTFUL_SPACE_ID = const String.fromEnvironment('CONTENTFUL_SPACE_ID');
final String? CONTENTFUL_DELIVERY_TOKEN = const String.fromEnvironment('CONTENTFUL_DELIVERY_TOKEN');
final String? AUTH0_DOMAIN = const String.fromEnvironment('AUTH0_DOMAIN');
final String? AUTH0_CLIENT_ID = const String.fromEnvironment('AUTH0_CLIENT_ID');

// ------------------ Utilities ------------------
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

// ------------------ Models ------------------
class LocalUser {
  final String uid;
  final String email;
  final bool isGuest;
  LocalUser({required this.uid, required this.email, this.isGuest = true});
}

class HelperModel {
  final String id;
  final String name;
  final String specialty;
  final double distanceKm;
  final double rating;
  final List<String> photos;
  HelperModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.distanceKm,
    required this.rating,
    this.photos = const [],
  });
}

// ------------------ Auth Service (Mock / Placeholder) ------------------
class AuthService {
  LocalUser? _user;
  Future<LocalUser> signInAnonymously() async {
    await Future.delayed(const Duration(milliseconds: 600));
    _user = LocalUser(uid: 'guest_${DateTime.now().millisecondsSinceEpoch}', email: 'guest@quickhelper.com', isGuest: true);
    return _user!;
  }

  Future<LocalUser> signInWithEmail(String email, String password) async {
    // Replace with Auth0 / real auth later
    await Future.delayed(const Duration(milliseconds: 700));
    _user = LocalUser(uid: 'u_${email.hashCode}', email: email, isGuest: false);
    return _user!;
  }

  Future<LocalUser> registerWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _user = LocalUser(uid: 'u_${email.hashCode}', email: email, isGuest: false);
    return _user!;
  }

  LocalUser? get currentUser => _user;
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _user = null;
  }
}

// ------------------ Contentful Client (minimal) ------------------
class ContentfulClient {
  final String? spaceId;
  final String? deliveryToken;
  ContentfulClient({this.spaceId, this.deliveryToken});

  Future<List<String>> fetchMediaUrlsForHelper(String helperId) async {
    if (spaceId == null || deliveryToken == null) {
      return [
        'https://via.placeholder.com/600x400.png?text=${Uri.encodeComponent(helperId)}+1',
        'https://via.placeholder.com/600x400.png?text=${Uri.encodeComponent(helperId)}+2',
      ];
    }

    // Minimal Contentful call - keep simple and robust
    final base = 'https://cdn.contentful.com/spaces/$spaceId/environments/master';
    final query = '?access_token=$deliveryToken&content_type=helperMedia&fields.helperId=$helperId';
    final url = Uri.parse('$base/entries$query');

    try {
      final client = HttpClient();
      final req = await client.getUrl(url);
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();
      final Map<String, dynamic> parsed = json.decode(body);
      final items = parsed['items'] as List<dynamic>? ?? [];
      final assets = parsed['includes']?['Asset'] as List<dynamic>? ?? [];
      final List<String> urls = [];
      // Try to extract via includes.Asset mapping
      for (final asset in assets) {
        final file = asset['fields']?['file'] as Map<String, dynamic>?;
        final urlStr = file?['url'] as String?;
        if (urlStr != null) urls.add(urlStr.startsWith('http') ? urlStr : 'https:$urlStr');
      }
      return urls.isNotEmpty ? urls : ['https://via.placeholder.com/600x400.png?text=No+Media'];
    } catch (e) {
      return ['https://via.placeholder.com/600x400.png?text=Contentful+Error'];
    }
  }
}

// ------------------ API Service (Mock / placeholder for backend) ----------
class ApiService {
  final String? baseUrl;
  ApiService({this.baseUrl});

  Future<List<HelperModel>> fetchHelpers({double lat = 19.1834, double lng = 72.8407}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (baseUrl == null) {
      return [
        HelperModel(id: 'h1', name: 'Rakesh Sharma', specialty: 'Electrician', distanceKm: 1.2, rating: 4.8),
        HelperModel(id: 'h2', name: 'Sunita Devi', specialty: 'Cleaning', distanceKm: 2.5, rating: 4.5),
        HelperModel(id: 'h3', name: 'Aman Gupta', specialty: 'Plumber', distanceKm: 3.0, rating: 4.6),
      ];
    }
    try {
      final uri = Uri.parse('$baseUrl/helpers?lat=$lat&lng=$lng');
      final client = HttpClient();
      final req = await client.getUrl(uri);
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();
      final List<dynamic> data = json.decode(body);
      return data.map((d) => HelperModel(
        id: d['id'],
        name: d['name'],
        specialty: d['specialty'],
        distanceKm: (d['distanceKm'] as num).toDouble(),
        rating: (d['rating'] as num).toDouble(),
        photos: (d['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      )).toList();
    } catch (e) {
      // fallback mock
      return [
        HelperModel(id: 'h1', name: 'Rakesh Sharma', specialty: 'Electrician', distanceKm: 1.2, rating: 4.8),
      ];
    }
  }

  Future<bool> createBooking(Map<String, dynamic> booking) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (baseUrl == null) return true;
    try {
      final uri = Uri.parse('$baseUrl/bookings');
      final client = HttpClient();
      final req = await client.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.add(utf8.encode(json.encode(booking)));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      client.close();
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

// ------------------ App ------------------
void main() {
  runApp(const QuickHelperApp());
}

class QuickHelperApp extends StatelessWidget {
  const QuickHelperApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: APP_NAME,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const AuthEntry(),
    );
  }
}

// ------------------ Auth Entry (chooses login or home) ------------------
class AuthEntry extends StatefulWidget {
  const AuthEntry({super.key});
  @override
  State<AuthEntry> createState() => _AuthEntryState();
}

class _AuthEntryState extends State<AuthEntry> {
  final AuthService _auth = AuthService();
  LocalUser? _user;
  late final ApiService apiService;
  late final ContentfulClient contentful;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: API_BASE);
    contentful = ContentfulClient(spaceId: CONTENTFUL_SPACE_ID, deliveryToken: CONTENTFUL_DELIVERY_TOKEN);
    // Attempt silent anonymous sign-in so app is usable immediately
    _auth.signInAnonymously().then((u) {
      if (mounted) setState(() => _user = u);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.indigo)));
    }
    // If guest, show LoginPage (user can choose to sign in or continue)
    return LoginPage(auth: _auth, api: apiService, contentful: contentful, initialUser: _user);
  }
}

// ------------------ Login Page ------------------
class LoginPage extends StatefulWidget {
  final AuthService auth;
  final ApiService api;
  final ContentfulClient contentful;
  final LocalUser? initialUser;
  const LoginPage({super.key, required this.auth, required this.api, required this.contentful, this.initialUser});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtr = TextEditingController();
  final _passCtr = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isRegisterMode = false;

  void _toggleMode() => setState(() => _isRegisterMode = !_isRegisterMode);

  Future<void> _submit() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      if (_isRegisterMode) {
        final u = await widget.auth.registerWithEmail(_emailCtr.text.trim(), _passCtr.text.trim());
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => BookingScreen(user: u, api: widget.api, contentful: widget.contentful, auth: widget.auth)));
      } else {
        final u = await widget.auth.signInWithEmail(_emailCtr.text.trim(), _passCtr.text.trim());
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => BookingScreen(user: u, api: widget.api, contentful: widget.contentful, auth: widget.auth)));
      }
    } catch (e) {
      setState(() { _error = 'Auth failed. Try again.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueAsGuest() {
    final u = widget.initialUser ?? widget.auth.currentUser;
    if (u != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => BookingScreen(user: u, api: widget.api, contentful: widget.contentful, auth: widget.auth)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(APP_NAME), backgroundColor: Colors.indigo),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 20),
          Text(_isRegisterMode ? 'Create your account' : 'Customer Login', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 20),
          TextField(controller: _emailCtr, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _passCtr, obscureText: true, decoration: const InputDecoration(labelText: 'Password (min 6 chars)', border: OutlineInputBorder())),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isRegisterMode ? 'Create Account' : 'Log In'),
          ),
          TextButton(onPressed: _toggleMode, child: Text(_isRegisterMode ? 'Already have an account? Log In' : 'Don\'t have an account? Sign Up')),
          const SizedBox(height: 6),
          OutlinedButton(onPressed: _continueAsGuest, child: const Text('Continue as Guest')),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ------------------ Booking / Home Screen ------------------
class BookingScreen extends StatefulWidget {
  final LocalUser user;
  final ApiService api;
  final ContentfulClient contentful;
  final AuthService auth;
  const BookingScreen({super.key, required this.user, required this.api, required this.contentful, required this.auth});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String selectedTask = 'General Assistant';
  double estimatedHours = 2.0;
  List<HelperModel> helperList = [];
  bool isLoading = true;
  HelperModel? selectedHelper;
  bool favouriteMode = false;

  final List<Map<String, dynamic>> categories = [
    {'id': 'cleaning', 'label': 'Cleaning', 'icon': Icons.cleaning_services},
    {'id': 'electrician', 'label': 'Electrician', 'icon': Icons.flash_on},
    {'id': 'plumbing', 'label': 'Plumbing', 'icon': Icons.plumbing},
    {'id': 'delivery', 'label': 'Delivery', 'icon': Icons.delivery_dining},
    {'id': 'handyman', 'label': 'Handyman', 'icon': Icons.handyman},
    {'id': 'deep', 'label': 'Deep Clean', 'icon': Icons.bubble_chart},
  ];

  @override
  void initState() {
    super.initState();
    _loadHelpers();
  }

  Future<void> _loadHelpers() async {
    setState(() => isLoading = true);
    final list = await widget.api.fetchHelpers();
    if (mounted) setState(() { helperList = list; isLoading = false; });
  }

  void _openHelperProfile(HelperModel helper) async {
    final media = await widget.contentful.fetchMediaUrlsForHelper(helper.id);
    if (!mounted) return;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
      return DraggableScrollableSheet(expand: false, builder: (context, ctl) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: ListView(controller: ctl, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(helper.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ]),
            const SizedBox(height: 8),
            Text(helper.specialty, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.star, color: Colors.amber), Text('${helper.rating}'), const SizedBox(width: 12), Text('${helper.distanceKm} km away')]),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (c, i) => ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(media[i], width: 260, fit: BoxFit.cover)),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: media.length,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() { selectedHelper = helper; });
                _openBookingSummary();
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Book Now'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline), label: const Text('Chat with Helper')),
            const SizedBox(height: 12),
            const Text('Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(3, (i) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text('Customer ${i+1}'), subtitle: const Text('Good work — recommended'), trailing: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.star, color: Colors.amber), SizedBox(width: 4), Text('4.5')])))
          ]),
        );
      });
    });
  }

  void _openBookingSummary() {
    final totalCost = calculateCost(estimatedHours);
    showDialog(context: context, builder: (_) {
      return AlertDialog(
        title: const Text('Booking Summary'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.work), title: Text(selectedTask), subtitle: Text('Hours: ${estimatedHours.toStringAsFixed(1)}')),
          ListTile(leading: const Icon(Icons.person), title: Text(selectedHelper?.name ?? 'Auto assign')),
          const Divider(),
          _costRow('Helper', '₹${(estimatedHours * AVG_HELPER_RATE_PER_HOUR).toStringAsFixed(0)}'),
          _costRow('Commission', '₹${(estimatedHours * APP_COMMISSION_PER_HOUR).toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _costRow('Total', '₹${totalCost.toStringAsFixed(0)}', isTotal: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: _confirmBooking, child: const Text('Confirm & Pay')),
        ],
      );
    });
  }

  Widget _costRow(String title, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(amount, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.w600)),
      ]),
    );
  }

  Future<void> _confirmBooking() async {
    Navigator.of(context).pop();
    final bookingPayload = {
      'userId': widget.user.uid,
      'task': selectedTask,
      'hours': estimatedHours,
      'helperId': selectedHelper?.id,
      'amount': calculateCost(estimatedHours),
      'createdAt': DateTime.now().toIso8601String(),
    };
    final success = await widget.api.createBooking(bookingPayload);
    if (!mounted) return;
    if (success) {
      showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Booking Confirmed'), content: const Text('Your booking has been placed successfully.'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))]));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking failed. Try again.'), backgroundColor: Colors.red));
    }
  }

  Widget _buildHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
     
