import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// Quick Helper - Phase 2 (Swiggy-style scaffold)
// - Mock backend mode (no secrets required to compile)
// - Hooks/placeholders for Auth0, MongoDB (Atlas REST API), Contentful
// - Comments show exactly where to inject keys using --dart-define
// -----------------------------------------------------------------------------

// ------------------------ APP CONSTANTS --------------------------------------
const String APP_NAME = "Quick Helper (Customer)";
const double AVG_HELPER_RATE_PER_HOUR = 145;
const double APP_COMMISSION_PER_HOUR = 20;

// These values SHOULD be supplied at build/run time via dart-define or kept
// outside source (never hardcode secrets!). Example when building:
// flutter build apk --release \ 
//   --dart-define=AUTH0_DOMAIN=your-auth0-domain \ 
//   --dart-define=AUTH0_CLIENT_ID=your-client-id \ 
//   --dart-define=MONGO_API_BASE=https://your-api.example.com \ 
//   --dart-define=CONTENTFUL_SPACE_ID=xxxx \ 
//   --dart-define=CONTENTFUL_DELIVERY_TOKEN=xxxx

// Retrieve environment values (may be null in mock mode)
final String? AUTH0_DOMAIN = const String.fromEnvironment('AUTH0_DOMAIN');
final String? AUTH0_CLIENT_ID = const String.fromEnvironment('AUTH0_CLIENT_ID');
final String? MONGO_API_BASE = const String.fromEnvironment('MONGO_API_BASE');
final String? CONTENTFUL_SPACE_ID = const String.fromEnvironment('CONTENTFUL_SPACE_ID');
final String? CONTENTFUL_DELIVERY_TOKEN = const String.fromEnvironment('CONTENTFUL_DELIVERY_TOKEN');

// ------------------------ UTILITIES -----------------------------------------
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

// ------------------------ SIMPLE MODELS -------------------------------------
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
  final List<String> photos; // URLs

  HelperModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.distanceKm,
    required this.rating,
    this.photos = const [],
  });
}

// ------------------------ SERVICES (PLACEHOLDERS) ---------------------------
// AuthService: placeholder for Auth0. If AUTH0_DOMAIN & CLIENT_ID are provided
// you can implement the real flows (PKCE/OAuth) using packages. For now, we
// keep a simulated login so app compiles and behaves.
class AuthService {
  LocalUser? _user;

  // Simulate sign-in: if real auth is configured, you would replace.
  Future<LocalUser> signInAnonymously() async {
    await Future.delayed(const Duration(seconds: 1));
    _user = LocalUser(uid: 'guest_user_id', email: 'guest@quickhelper.com');
    return _user!;
  }

  Future<LocalUser> signInWithEmail(String email, String password) async {
    // TODO: replace with Auth0 login flow; keep safe token handling.
    await Future.delayed(const Duration(seconds: 1));
    _user = LocalUser(uid: 'user_' + email.hashCode.toString(), email: email, isGuest: false);
    return _user!;
  }

  LocalUser? get currentUser => _user;
}

// ContentfulClient: minimal REST fetcher for Media entries. If Contentful
// credentials are not available we return mock data.
class ContentfulClient {
  final String? spaceId;
  final String? deliveryToken;

  ContentfulClient({this.spaceId, this.deliveryToken});

  Future<List<String>> fetchMediaUrlsForHelper(String helperId) async {
    if (spaceId == null || deliveryToken == null) {
      // Return mock image URLs (placeholders)
      return [
        'https://via.placeholder.com/600x400.png?text=Helper+${Uri.encodeComponent(helperId)}+1',
        'https://via.placeholder.com/600x400.png?text=Helper+${Uri.encodeComponent(helperId)}+2',
      ];
    }

    // Minimal HTTP GET to Contentful Delivery API - no external package needed
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
      // Contentful response formatting can be complex; for now attempt simple extraction
      final items = parsed['items'] as List<dynamic>? ?? [];
      List<String> urls = [];
      for (final item in items) {
        final fields = item['fields'] as Map<String, dynamic>?;
        if (fields != null && fields['images'] != null) {
          final images = fields['images'] as List<dynamic>;
          for (final img in images) {
            if (img is Map && img['fields'] != null && img['fields']['file'] != null) {
              final file = img['fields']['file'] as Map<String, dynamic>;
              final urlStr = file['url'] as String?;
              if (urlStr != null) urls.add(urlStr.startsWith('http') ? urlStr : 'https:$urlStr');
            }
          }
        }
      }
      return urls.isNotEmpty ? urls : [
        'https://via.placeholder.com/600x400.png?text=Helper+${Uri.encodeComponent(helperId)}+1'
      ];
    } catch (e) {
      return ['https://via.placeholder.com/600x400.png?text=Contentful+Error'];
    }
  }
}

// ApiService: placeholder for MongoDB backend (recommended: create a small
// Node/Express API that talks to MongoDB Atlas). If MONGO_API_BASE is not set,
// the functions return mock values for local testing.
class ApiService {
  final String? baseUrl;

  ApiService({this.baseUrl});

  Future<List<HelperModel>> fetchHelpers({double lat = 19.1834, double lng = 72.8407}) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (baseUrl == null) {
      // Mock data
      return [
        HelperModel(id: 'h1', name: 'Rakesh Sharma', specialty: 'Electrician', distanceKm: 1.2, rating: 4.8, photos: []),
        HelperModel(id: 'h2', name: 'Sunita Devi', specialty: 'Cleaning', distanceKm: 2.5, rating: 4.5, photos: []),
        HelperModel(id: 'h3', name: 'Aman Gupta', specialty: 'Plumber', distanceKm: 3.1, rating: 4.6, photos: []),
      ];
    }

    // Example: GET $baseUrl/helpers?lat=...&lng=...
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
      // On any error fall back to mock
      return [
        HelperModel(id: 'h1', name: 'Rakesh Sharma', specialty: 'Electrician', distanceKm: 1.2, rating: 4.8, photos: []),
      ];
    }
  }

  Future<bool> createBooking(Map<String, dynamic> booking) async {
    // If no baseUrl, simulate success
    await Future.delayed(const Duration(seconds: 1));
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
      return resp.statusCode == 201 || resp.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ------------------------ MAIN APP ------------------------------------------
void main() {
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

// ------------------------ AUTH WRAPPER --------------------------------------
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _auth = AuthService();
  LocalUser? user;
  late final ApiService apiService;
  late final ContentfulClient contentful;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(baseUrl: MONGO_API_BASE);
    contentful = ContentfulClient(spaceId: CONTENTFUL_SPACE_ID, deliveryToken: CONTENTFUL_DELIVERY_TOKEN);

    // Initialize guest user automatically so app is usable without keys
    _auth.signInAnonymously().then((u) {
      if (mounted) setState(() => user = u);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.indigo)));
    }
    return BookingScreen(user: user!, api: apiService, contentful: contentful, auth: _auth);
  }
}

// ------------------------ BOOKING SCREEN -----------------------------------
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
    // Fetch media for helper (Contentful) when opening profile
    final media = await widget.contentful.fetchMediaUrlsForHelper(helper.id);
    if (!mounted) return;

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) {
      return DraggableScrollableSheet(
        expand: false,
        builder: (context, ctl) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: ListView(
              controller: ctl,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(helper.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ]),
                const SizedBox(height: 8),
                Text(helper.specialty, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Row(children: [Icon(Icons.star, color: Colors.amber), Text('${helper.rating}'), const SizedBox(width: 12), Text('${helper.distanceKm} km away')]),
                const SizedBox(height: 12),
                // Media carousel (simple horizontal)
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
                TextButton.icon(onPressed: () { /* open chat placeholder */ }, icon: const Icon(Icons.chat_bubble_outline), label: const Text('Chat with Helper')),
                const SizedBox(height: 12),
                const Text('Reviews', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Mock reviews
                ...List.generate(3, (i) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text('Customer ${i+1}'), subtitle: const Text('Good work — recommended'), trailing: Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.star, color: Colors.amber), Text('4.5')])))
              ],
            ),
          );
        }
      );
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
    Navigator.of(context).pop(); // close summary
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
      // Show success confirmation screen (simple)
      showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Booking Confirmed'), content: const Text('Your booking has been placed successfully.'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))]));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking failed. Try again.'), backgroundColor: Colors.red));
    }
  }

  Widget _buildHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hello, ${widget.user.email.split('@').first}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Find trusted helpers near you', style: TextStyle(color: Colors.indigo.shade700)),
      ]),
      IconButton(
        onPressed: () { setState(() { favouriteMode = !favouriteMode; }); },
        icon: Icon(favouriteMode ? Icons.favorite : Icons.favorite_border, color: Colors.red),
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = calculateCost(estimatedHours);

    return Scaffold(
      appBar: AppBar(
        title: Text(APP_NAME, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHelpers),
          IconButton(icon: const Icon(Icons.person), onPressed: () {
            // Profile / Settings placeholder
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile pressed')));
          })
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHelpers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(),
            const SizedBox(height: 16),

            // Map placeholder with ETA
            Container(
              height: 180,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigo.shade100)),
              child: Stack(children: [
                Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.map, size: 48, color: Colors.indigo.shade400), const SizedBox(height: 8), const Text('Live Map Placeholder')])),
                Positioned(right: 12, top: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Row(children: const [Icon(Icons.timer, size: 14), SizedBox(width: 6
