import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  // Google Sign-In
  late GoogleSignIn _googleSignIn;

  // API Configuration - Initialize from AppConfig in initState
  late String _apiBaseUrl;
  late String _nodeOAuthCallbackUrl;

  late AnimationController _gradientController;
  late AnimationController _floatingController;
  late AnimationController _cardController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  // Pastel Color Palette - White, Light Blue, Light Green
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightBlue = Color(0xFFB8D4F1);
  static const Color skyBlue = Color(0xFF87CEEB);
  static const Color paleBlue = Color(0xFFDCEEFC);
  static const Color lightGreen = Color(0xFFC1E8C9);
  static const Color mintGreen = Color(0xFFB0E5D0);
  static const Color deepBlue = Color(0xFF4A90E2);
  static const Color accentBlue = Color(0xFF5B9BD5);

  @override
  void initState() {
    super.initState();

    // Initialize API URLs from AppConfig
    _apiBaseUrl = '${AppConfig.nodeJsBaseUrl}/api';
    _nodeOAuthCallbackUrl = '$_apiBaseUrl/auth/google/callback';

    // Initialize Google Sign-In with config
    _googleSignIn = GoogleSignIn(
      clientId: AppConfig.googleClientId,
      scopes: [
        'email',
        'profile',
      ],
    );

    // Animated gradient
    _gradientController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );

    // Floating animation
    _floatingController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -15.0, end: 15.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Card entrance animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _cardSlideAnimation = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _cardController.forward();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _floatingController.dispose();
    _cardController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          _buildAnimatedBackground(),

          // Floating Decorative Elements
          _buildFloatingElements(),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AnimatedBuilder(
                  animation: _cardController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _cardFadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _cardSlideAnimation.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLoginCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                white,
                Color.lerp(paleBlue, lightBlue, _gradientAnimation.value * 0.5) ?? paleBlue,
                Color.lerp(lightGreen, mintGreen, _gradientAnimation.value * 0.3) ?? lightGreen,
                white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingElements() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Top left circle
            Positioned(
              top: 100 + _floatingAnimation.value,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      lightBlue.withOpacity(0.4),
                      lightBlue.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Top right circle
            Positioned(
              top: 180 - _floatingAnimation.value * 0.8,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      lightGreen.withOpacity(0.35),
                      lightGreen.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom left circle
            Positioned(
              bottom: 150 + _floatingAnimation.value * 0.6,
              left: 30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      mintGreen.withOpacity(0.4),
                      mintGreen.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom right circle
            Positioned(
              bottom: 80 - _floatingAnimation.value,
              right: 50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      paleBlue.withOpacity(0.45),
                      paleBlue.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Card(
        elevation: 24,
        shadowColor: deepBlue.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        color: white,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: lightBlue.withOpacity(0.3),
              width: 1,
            ),
            gradient: LinearGradient(
              colors: [
                white,
                white.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Section
                _buildLogoSection(),
                const SizedBox(height: 48),

                // Username Field
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person_outline_rounded,
                  hint: 'Enter your username',
                ),
                const SizedBox(height: 24),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  hint: 'Enter your password',
                  isPassword: true,
                ),
                const SizedBox(height: 16),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                      _showAlert('Info', 'Please contact your administrator to reset your password.');
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: accentBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Login Button
                _buildLoginButton(),
                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: lightBlue.withOpacity(0.4),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: deepBlue.withOpacity(0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: lightBlue.withOpacity(0.4),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Google Sign In Button
                _buildGoogleSignInButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Logo with glow effect
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                white,
                paleBlue,
                lightBlue.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: lightBlue.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: lightGreen.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: white,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/converted-image.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [paleBlue, lightBlue],
                        ),
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        size: 45,
                        color: deepBlue,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // PBS FinSight Title
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [deepBlue, accentBlue, lightBlue],
          ).createShader(bounds),
          child: const Text(
            'FinSight',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Prophetic Business Solutions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: deepBlue.withOpacity(0.8),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        
        // Feature badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBadge('💰 Smart Payments', lightBlue),
            const SizedBox(width: 8),
            _buildBadge('📊 Analytics', lightGreen),
          ],
        ),
        const SizedBox(height: 12),
        
        Text(
          'Professional CFO Services for Modern Businesses',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: deepBlue.withOpacity(0.7),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: lightBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: lightBlue.withOpacity(0.3),
            ),
          ),
          child: Text(
            '✨ AI-Powered Cash Flow Intelligence ✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: deepBlue,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: deepBlue,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: lightBlue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePassword,
            autocorrect: false,
            enableSuggestions: false,
            style: TextStyle(
              fontSize: 16,
              color: deepBlue,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: deepBlue.withOpacity(0.3),
                fontSize: 15,
              ),
              prefixIcon: Icon(icon, color: accentBlue, size: 22),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: accentBlue,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: paleBlue.withOpacity(0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: lightBlue.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: accentBlue,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _loading
              ? [
                  accentBlue.withOpacity(0.6),
                  deepBlue.withOpacity(0.6),
                ]
              : [
                  accentBlue,
                  deepBlue,
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accentBlue.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _loading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: lightBlue.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: lightBlue.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF4285F4),
                      Color(0xFFEA4335),
                      Color(0xFFFBBC05),
                      Color(0xFF34A853),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Continue with Google',
              style: TextStyle(
                color: deepBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showAlert('Error', 'Please enter both username and password');
      return;
    }

    setState(() => _loading = true);

    try {
      debugPrint('Starting login process...');

      // Make API call to Node.js auth server
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      debugPrint('Login response: ${jsonEncode(responseData)}');

      if (response.statusCode != 200 || responseData['status'] != 'success' || responseData['data']?['token'] == null) {
        final errorMsg = responseData['message'] ?? 'Invalid username or password';
        debugPrint('Login failed: $errorMsg');
        _showAlert('Login Failed', errorMsg);
        return;
      }

      // Store auth data using StorageService so other app pieces use it
      try {
        String token = responseData['data']['token'];
        token = token.replaceFirst(
            RegExp(r'^(Bearer|Token)\s+', caseSensitive: false), '');

        final storage = StorageService();
        await storage.setAccessToken(token);

        // Optional: save refresh token if provided
        if (responseData['data']['refresh_token'] != null) {
          await storage.setRefreshToken(responseData['data']['refresh_token']);
        }

        // Save user data in canonical key
        if (responseData['data']['user'] != null) {
          await storage.setUserData(jsonEncode(responseData['data']['user']));
        }

        debugPrint('Authentication data stored to StorageService');
      } catch (storageError) {
        debugPrint('Failed to store auth data: $storageError');
        _showAlert('Error', 'Failed to save login data. Please try again.');
        return;
      }

      // Set company context
      final user = responseData['data']['user'];
      try {
        final storage = StorageService();
        await storage.setString('companyContext', jsonEncode({
          'companyId': user['company_id'] ?? user['companyId'] ?? user['companyId'],
          'companyName': user['company_name'] ?? user['companyName'],
          'userCompanyName': user['user_company_name'] ?? user['userCompanyName'],
        }));
      } catch (e) {
        debugPrint('Failed to store company context: $e');
      }

      // Check model status
      try {
        final modelStatusResponse = await _simulateModelStatusCheck();
        final modelData = modelStatusResponse['data'] ?? {};
        final needsTraining = !(modelData['isReady'] ?? false);

        await prefs.setBool('modelTrained', !needsTraining);

        if (mounted) {
          // Navigate to dashboard on success
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      } catch (modelError) {
        debugPrint('Error checking model status: $modelError');
        if (mounted) {
          _showAlert('Success', 'Welcome to PBS FinSight!');
        }
      }
    } catch (error) {
      debugPrint('Login process error: $error');
      _showAlert('Login Error', error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    debugPrint('Google Sign In initiated');
    
    setState(() => _loading = true);

    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('Google sign in cancelled');
        setState(() => _loading = false);
        return;
      }

      debugPrint('Google user signed in: ${googleUser.email}');

      // Get the authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      
      debugPrint('ID Token obtained: ${idToken?.substring(0, 20) ?? 'null'}...');
      debugPrint('Access Token obtained: ${accessToken?.substring(0, 20) ?? 'null'}...');

      if (idToken == null) {
        _showAlert('Error', 'Failed to obtain ID token from Google');
        setState(() => _loading = false);
        return;
      }

      // Send tokens to Node.js gateway (NOT directly to Django)
      // Node.js will validate and proxy to Django
      final response = await http.post(
        Uri.parse(_nodeOAuthCallbackUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
          'access_token': accessToken,
          'provider': 'google',
        }),
      ).timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);
      debugPrint('Node.js OAuth response status: ${response.statusCode}');
      debugPrint('Node.js OAuth response: $responseData');

      if (response.statusCode == 200 && responseData['status'] == 'success') {
        final data = responseData['data'];
        
        // Store auth tokens and user via StorageService
        final storage = StorageService();
        if (data['access_token'] != null) await storage.setAccessToken(data['access_token']);
        if (data['refresh_token'] != null) await storage.setRefreshToken(data['refresh_token']);
        if (data['user'] != null) await storage.setUserData(jsonEncode(data['user']));

        debugPrint('Google login successful for ${googleUser.email}');
        
        // Navigate to dashboard
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        final errorMsg = responseData['message'] ?? 'Failed to authenticate through Node.js gateway';
        debugPrint('Node.js auth failed: $errorMsg');
        _showAlert('Login Failed', errorMsg);
      }
    } catch (e) {
      debugPrint('Google sign in error: $e');
      _showAlert('Google Sign In Error', 'An error occurred during Google sign in: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _simulateLogin(
      String username, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    if (username == 'admin' && password == 'password') {
      return {
        'status': 'success',
        'data': {
          'token': 'demo_token_12345',
          'user': {
            'company_id': 1,
            'company_name': 'Demo Company',
            'user_company_name': 'Demo Company Ltd',
          }
        }
      };
    } else {
      return {'status': 'error', 'message': 'Invalid username or password'};
    }
  }

  Future<Map<String, dynamic>> _simulateModelStatusCheck() async {
    await Future.delayed(const Duration(seconds: 1));
    return {
      'data': {
        'isReady': true,
        'lastTrainingDate': DateTime.now().toIso8601String(),
        'hasTrainingData': true,
      }
    };
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: deepBlue,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: deepBlue.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: paleBlue.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: deepBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}