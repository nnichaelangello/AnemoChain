import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PrismaApp());
}

class PrismaApp extends StatelessWidget {
  const PrismaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnemoChain Medical AI',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1E88E5), // Medical Blue
        scaffoldBackgroundColor: const Color(
          0xFFF5F7FA,
        ), // Very light greyish blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          secondary: const Color(0xFF00B4D8),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      initialRoute: '/home',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String serverIp = "http://192.168.1.100:8000"; // Default IP
  String patientId = ""; // Persisted ID
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('patient_id');
    if (storedId == null || storedId.isEmpty) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    setState(() {
      serverIp = prefs.getString('server_ip') ?? serverIp;
      patientId = storedId;
    });
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
    setState(() => serverIp = ip);
  }

  void _showSettings() {
    final TextEditingController controller = TextEditingController(
      text: serverIp,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.router, color: Color(0xFF1E88E5)),
              SizedBox(width: 10),
              Text(
                'Network Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your Backend Server IP.',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "http://192.168.1.x:8000",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.link, color: Colors.blueGrey),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                _saveIp(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Server IP updated.')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
      );
      if (image == null) return;
      if (!mounted) return;

      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmation'),
            content: const Text(
              'Are you sure you want to use this image for anemia screening?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Analyze'),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              AnalyzingScreen(
                imageFile: File(image.path),
                serverIp: serverIp,
                patientId: patientId,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open camera/gallery.')),
      );
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            HistoryScreen(serverIp: serverIp, patientId: patientId),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [Colors.white, color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF00B4D8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.medical_services,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'AnemoChain',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                              ),
                              onPressed: _showSettings,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.remove('patient_id');
                                if (!mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello, Patient/Staff!',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Fast Screening',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Your ID: $patientId',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Screening Tips: Point the camera ONLY at the eyelid flesh. Avoid facial skin or the white of the eye for more accurate results!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildActionCard(
                            title: 'Take Photo Directly',
                            subtitle: 'Use camera to take a picture',
                            icon: Icons.camera_alt_rounded,
                            color: const Color(0xFF1E88E5),
                            onTap: () => _processImage(ImageSource.camera),
                          ),
                          const SizedBox(height: 16),
                          _buildActionCard(
                            title: 'Upload from Gallery',
                            subtitle: 'Choose a saved photo',
                            icon: Icons.photo_library_rounded,
                            color: const Color(0xFF00B4D8),
                            onTap: () => _processImage(ImageSource.gallery),
                          ),
                          const SizedBox(height: 16),
                          _buildActionCard(
                            title: 'History & Synchronization',
                            subtitle: 'View local screenings and upload images',
                            icon: Icons.cloud_sync_rounded,
                            color: const Color(0xFF43A047),
                            onTap: _openHistory,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalyzingScreen extends StatefulWidget {
  final File imageFile;
  final String serverIp;
  final String patientId;

  const AnalyzingScreen({
    super.key,
    required this.imageFile,
    required this.serverIp,
    required this.patientId,
  });

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final List<String> _steps = [
    "Extracting Image Features...",
    "Edge AI Inference...",
    "Saving Medical Record Data...",
  ];

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    try {
      // 1. Predict
      if (mounted) setState(() => _currentStep = 0);
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.serverIp}/api/predict'),
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', widget.imageFile.path),
      );
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 400) {
        // Gambar tidak valid sebagai konjungtiva (ditolak oleh validasi biologis backend)
        String errorBody = responseData;
        try {
          final errJson = jsonDecode(responseData);
          errorBody = errJson['detail'] ?? responseData;
        } catch (_) {}
        _showInvalidImageError(errorBody);
        return;
      }
      if (response.statusCode != 200)
        throw Exception("Prediction failed (HTTP ${response.statusCode})");
      var json = jsonDecode(responseData);

      // 2. Automatically sync JSON to Blockchain immediately (Blockchain First logic)
      if (mounted) setState(() => _currentStep = 2);
      final syncResponse = await http.post(
        Uri.parse('${widget.serverIp}/api/blockchain_sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "patient_id": widget.patientId,
          "redness_index": json['redness_index'],
          "confidence_score": json['confidence'],
          "anemia_status": json['status'],
          "color_details": json['color_details'],
        }),
      );

      if (syncResponse.statusCode != 200)
        throw Exception("Blockchain sync failed");
      var syncData = jsonDecode(syncResponse.body);
      String txId = syncData['tx_id'];
      String timestamp = syncData['timestamp'];
      String dataHash = syncData['data_hash'];

      // 3. Save EVERYTHING offline to SharedPreferences (Database Last logic)
      final prefs = await SharedPreferences.getInstance();
      String key = 'local_history_${widget.patientId}';
      List<String> historyStrings = prefs.getStringList(key) ?? [];

      Map<String, dynamic> localRecord = {
        "tx_id": txId,
        "timestamp": timestamp,
        "data_hash": dataHash,
        "redness_index": json['redness_index'],
        "confidence_score": json['confidence'],
        "anemia_status": json['status'],
        "color_details": json['color_details'],
        "image_path": widget.imageFile.path,
        "is_synced_to_db": false,
      };
      historyStrings.add(jsonEncode(localRecord));
      await prefs.setStringList(key, historyStrings);

      if (mounted) {
        json['data_hash'] = dataHash;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, anim, secondAnim) => ResultScreen(
              result: json,
              txId: txId,
              imagePath: widget.imageFile.path,
            ),
            transitionsBuilder: (context, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    } catch (e) {
      _showError(
        "Connection error: Ensure API Server and Blockchain Node are active. (${e.toString()})",
      );
    }
  }

  void _showInvalidImageError(String detail) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.remove_red_eye_outlined,
              color: Color(0xFFE53935),
              size: 28,
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                "Invalid Image",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF9800)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "The image you submitted is not a valid photo of the eye conjunctiva.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Ensure the photo meets these requirements:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              "• The photo shows the conjunctiva area (inner lining of the lower eyelid)",
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              "• Sufficient lighting and not too dark",
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              "• Not a photo of the floor, wall, or other objects",
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              "• The camera is focused directly on the eye area",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.camera_alt),
            label: const Text("Foto Ulang"),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Connection Error"),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.black87)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Back"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue[100]!,
                    ),
                    strokeWidth: 8,
                  ),
                ),
                const SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1E88E5),
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                const Icon(Icons.analytics, size: 50, color: Color(0xFF1E88E5)),
              ],
            ),
            const SizedBox(height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _steps[_currentStep],
                key: ValueKey<int>(_currentStep),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Decentralized System...",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final String txId;
  final String imagePath;

  const ResultScreen({
    super.key,
    required this.result,
    required this.txId,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final status = result['status'];
    final confidence = (result['confidence'] * 100).toStringAsFixed(1);
    final isAnemia = status == "Anemia";
    final rednessIndex = result['redness_index'].toStringAsFixed(4);

    final statusColor = isAnemia
        ? const Color(0xFFE53935)
        : const Color(0xFF43A047);
    final statusBgColor = isAnemia
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFE8F5E9);
    final statusIcon = isAnemia
        ? Icons.warning_rounded
        : Icons.check_circle_rounded;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Screening Report',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(statusIcon, size: 70, color: statusColor),
                    const SizedBox(height: 16),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Confidence Score: $confidence%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.file(File(imagePath), fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: Color(0xFF1E88E5),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Optical Clinical Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pallor Indicator (Redness Index)',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        Text(
                          rednessIndex,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                    if (result['color_details'] != null) ...[
                      const Divider(height: 24),
                      const Text(
                        'Color Analysis Spectrum (Conjunctiva):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          try {
                            Map<String, dynamic> cData =
                                result['color_details'] is String
                                ? jsonDecode(result['color_details'])
                                : result['color_details'];
                            return Column(
                              children: [
                                _buildMedRow(
                                  'Erythema / Red Component (R)',
                                  cData['R'].toStringAsFixed(2),
                                ),
                                _buildMedRow(
                                  'Conjunctiva Green Pigment (G)',
                                  cData['G'].toStringAsFixed(2),
                                ),
                                _buildMedRow(
                                  'Conjunctiva Blue Pigment (B)',
                                  cData['B'].toStringAsFixed(2),
                                ),
                                _buildMedRow(
                                  'Lightness Pallor Estimation (L*)',
                                  cData['L'].toStringAsFixed(2),
                                ),
                                _buildMedRow(
                                  'Red/Green Chromaticity (a*)',
                                  cData['a'].toStringAsFixed(2),
                                ),
                                _buildMedRow(
                                  'Yellow/Blue Chromaticity (b*)',
                                  cData['b'].toStringAsFixed(2),
                                ),
                                _buildMedRow(
                                  'Optical Hue Degree (H)',
                                  '${cData['H'].toStringAsFixed(1)}°',
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.shade100,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'AI Interpretation',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isAnemia
                                            ? 'Optical analysis indicates a decrease in the red component (R) and an increase in lightness (L*) in the conjunctiva area, visually indicating pallor. Conjunctival pallor is an early clinical sign often associated with Anemia risk. Laboratory testing is recommended for definitive results.'
                                            : 'The conjunctival color spectrum is within the optimal redness range and shows no significant visual signs of pallor. Optically, the tissue color condition appears within normal limits for an initial screening tool.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue.shade900,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } catch (e) {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          color: Color(0xFF43A047),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Health Advice',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      isAnemia
                          ? 'We detect indications of pallor in your eye conjunctiva pointing towards an Anemia condition. Immediately consult this initial screening result with a nearby doctor or healthcare provider. Increase intake of iron-rich foods such as meat, spinach, and blood-building supplements if recommended.'
                          : 'Your eye conjunctiva color condition appears normal and not pale. Maintain your health with a balanced nutritious diet, adequate rest, and regular exercise.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link, color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'DATA REFERENCE ID',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.white38, height: 1),
                    ),
                    const Text(
                      'This data has a unique system reference code.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      txId,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Note: New Data and Images are saved ONLY in your device\'s local storage. You can upload them to the Hospital Database anytime via the History Menu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                icon: const Icon(Icons.home, color: Color(0xFF1E88E5)),
                label: const Text(
                  'Back to Home',
                  style: TextStyle(
                    color: Color(0xFF1E88E5),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  final String serverIp;
  final String patientId;

  const HistoryScreen({
    super.key,
    required this.serverIp,
    required this.patientId,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> localHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalHistory();
  }

  Future<void> _loadLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'local_history_${widget.patientId}';
    List<String> historyStrings = prefs.getStringList(key) ?? [];

    List<Map<String, dynamic>> temp = [];
    for (String s in historyStrings) {
      temp.add(jsonDecode(s) as Map<String, dynamic>);
    }

    // Reverse to show newest first
    setState(() {
      localHistory = temp.reversed.toList();
      isLoading = false;
    });
  }

  Future<void> _saveHistory(List<Map<String, dynamic>> updatedHistory) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'local_history_${widget.patientId}';
    // Must reverse back to original order before saving
    List<String> stringsToSave = updatedHistory.reversed
        .map((e) => jsonEncode(e))
        .toList();
    await prefs.setStringList(key, stringsToSave);
  }

  Future<void> _uploadToDatabase(int index) async {
    Map<String, dynamic> record = localHistory[index];

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending to Hospital Database...')),
      );
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.serverIp}/api/screenings'),
      );

      request.fields['patient_id'] = widget.patientId;
      request.fields['redness_index'] = record['redness_index'].toString();
      request.fields['confidence_score'] = record['confidence_score']
          .toString();
      request.fields['anemia_status'] = record['anemia_status'];
      request.fields['timestamp'] = record['timestamp'];
      request.fields['data_hash'] = record['data_hash'];
      request.fields['blockchain_tx_id'] = record['tx_id'];
      if (record.containsKey('color_details') &&
          record['color_details'] != null) {
        request.fields['color_details'] = record['color_details'] is String
            ? record['color_details']
            : jsonEncode(record['color_details']);
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', record['image_path']),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        setState(() {
          record['is_synced_to_db'] = true;
        });
        await _saveHistory(localHistory);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Successfully saved to Hospital Database!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to send to Hospital. Check connection.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteLocalRecord(int index) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete History'),
          content: const Text(
            'Are you sure you want to delete this data from your device\'s local history?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      localHistory.removeAt(index);
    });
    await _saveHistory(localHistory);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History deleted from device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Local History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : localHistory.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sd_card, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No data saved on device.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: localHistory.length,
              itemBuilder: (context, index) {
                final record = localHistory[index];
                final isAnemia = record['anemia_status'] == 'Anemia';
                final bool isSynced = record['is_synced_to_db'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultScreen(
                            result: {
                              'status': record['anemia_status'],
                              'confidence': record['confidence_score'] != null
                                  ? double.tryParse(
                                          record['confidence_score'].toString(),
                                        ) ??
                                        0.0
                                  : 0.0,
                              'redness_index': record['redness_index'],
                              'color_details': record['color_details'],
                              'data_hash': record['data_hash'],
                            },
                            txId: record['tx_id'] ?? '-',
                            imagePath: record['image_path'] ?? '',
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: isAnemia
                                ? Colors.red[50]
                                : Colors.green[50],
                            radius: 25,
                            child: Icon(
                              isAnemia
                                  ? Icons.warning_rounded
                                  : Icons.check_circle_rounded,
                              color: isAnemia ? Colors.red : Colors.green,
                            ),
                          ),
                          title: Text(
                            record['anemia_status'].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Waktu: ${DateTime.parse(record['timestamp'] + (record['timestamp'].endsWith('Z') ? '' : 'Z')).toLocal().toString().split('.')[0]}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Skor Keyakinan: ${(record['confidence_score'] * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isSynced)
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.cloud_done,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Saved in Hospital DB",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Konfirmasi Sinkronisasi',
                                        ),
                                        content: const Text(
                                          'Are you sure you want to permanently save this optical medical record and photo to the Hospital Database?',
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _uploadToDatabase(index);
                                            },
                                            child: const Text('Yes, Save'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.cloud_upload,
                                    size: 16,
                                  ),
                                  label: const Text('Save to Hospital DB'),
                                ),

                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteLocalRecord(index),
                                tooltip: "Delete from Device",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// LOGIN & REGISTER SCREENS
// ==========================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nikController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String serverIp = "http://192.168.1.100:8000";

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      serverIp = prefs.getString('server_ip') ?? serverIp;
    });
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
    setState(() => serverIp = ip);
  }

  void _showSettings() {
    final TextEditingController controller = TextEditingController(
      text: serverIp,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.router, color: Color(0xFF1E88E5)),
              SizedBox(width: 10),
              Text(
                'Network Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter Backend laptop IP Address:',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Example: http://192.168.x.x:8000",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _saveIp(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Server IP saved successfully!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String currentIp =
          prefs.getString('server_ip') ?? "http://192.168.1.100:8000";

      var response = await http.post(
        Uri.parse('$currentIp/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "nik": _nikController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await prefs.setString('patient_id', data['patient_id']);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Gagal. Periksa NIK/Password.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Network error: $e. Ensure the IP is correct in settings (Gear icon).',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF1E88E5)),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services,
                size: 80,
                color: Color(0xFF1E88E5),
              ),
              const SizedBox(height: 20),
              const Text(
                'AnemoChain',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nikController,
                decoration: const InputDecoration(
                  labelText: 'NIK (Nomor Induk Kependudukan)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: const Color(0xFF1E88E5),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text(
                  "Don't have an account? Register Patient ID here",
                ),
              ),
            ],
          ),
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
  final _nikController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String serverIp = "http://192.168.1.100:8000";

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      serverIp = prefs.getString('server_ip') ?? serverIp;
    });
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
    setState(() => serverIp = ip);
  }

  void _showSettings() {
    final TextEditingController controller = TextEditingController(
      text: serverIp,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.router, color: Color(0xFF1E88E5)),
              SizedBox(width: 10),
              Text(
                'Network Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter Backend laptop IP Address:',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Example: http://192.168.x.x:8000",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _saveIp(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Server IP saved successfully!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String currentIp =
          prefs.getString('server_ip') ?? "http://192.168.1.100:8000";

      var response = await http.post(
        Uri.parse('$currentIp/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "nik": _nikController.text,
          "name": _nameController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Successful! Please Login.'),
          ),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration Failed. Patient ID might already be registered.',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e. Ensure the IP is correct.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Account'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nikController,
              decoration: const InputDecoration(
                labelText: 'Full NIK (National ID)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Patient Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFF1E88E5),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
