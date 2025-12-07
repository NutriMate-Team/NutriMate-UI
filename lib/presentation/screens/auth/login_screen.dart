import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  bool _rememberMe = false; // Remember Me checkbox state
  AuthStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    // Load saved email and password when screen initializes
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Load saved email and password from preferences
  Future<void> _loadSavedCredentials() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final credentials = await authProvider.loadSavedCredentials();
    
    final savedEmail = credentials['email'];
    final savedPassword = credentials['password'];
    
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        // Only pre-fill password if it exists
        if (savedPassword != null && savedPassword.isNotEmpty) {
          _passwordController.text = savedPassword;
        }
        _rememberMe = true; // Auto-check if credentials were saved
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.login(
        _emailController.text,
        _passwordController.text,
        rememberMe: _rememberMe,
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;
    setState(() {
      _isGoogleLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signInWithGoogle();

    if (!mounted) return;

    setState(() {
      _isGoogleLoading = false;
    });

    if (authProvider.status == AuthStatus.success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } else if (authProvider.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Primary green color extracted from logo (vibrant nature green)
    const primaryGreen = Color(0xFF4CAF50);
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Handle status changes for navigation
        if (_previousStatus != null && _previousStatus != authProvider.status) {
          if (authProvider.status == AuthStatus.success) {
            // Navigate to dashboard on successful login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                  (route) => false,
                );
              }
            });
          } else if (authProvider.status == AuthStatus.error) {
            // Show error message
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(authProvider.errorMessage),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            });
          }
        }
        _previousStatus = authProvider.status;
        
        return Scaffold(
          body: Container(
            // Clean gradient background
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                  Colors.grey[100]!,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Center(
                          child: Image.asset(
                            'assets/images/nutrimate_logo.png',
                            width: 240,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Welcome text
                        Text(
                          'Chào mừng trở lại!',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đăng nhập để tiếp tục hành trình sức khỏe',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey[600],
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: primaryGreen,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.red[300]!),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.poppins(),
                          validator: (value) {
                            if (value == null || value.isEmpty || !value.contains('@')) {
                              return 'Vui lòng nhập email hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Password field with visibility toggle
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey[600],
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: Colors.grey[600],
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: primaryGreen,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.red[300]!),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          style: GoogleFonts.poppins(),
                          validator: (value) {
                            if (value == null || value.isEmpty || value.length < 6) {
                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Remember Me checkbox and Forgot Password row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Remember Me checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                  },
                                  child: Text(
                                    'Ghi nhớ tài khoản',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Forgot Password
                            TextButton(
                              onPressed: () {
                                // TODO: Implement forgot password
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tính năng quên mật khẩu đang được phát triển')),
                                );
                              },
                              child: Text(
                                'Quên mật khẩu?',
                                style: GoogleFonts.poppins(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _GoogleButton(
                          onPressed: _signInWithGoogle,
                          isLoading: _isGoogleLoading,
                          label: 'Đăng nhập bằng Google',
                        ),
                        const SizedBox(height: 20),
                        // Login button
                        Consumer<AuthProvider>(
                          builder: (context, auth, child) {
                            if (auth.status == AuthStatus.loading) {
                              return SizedBox(
                                height: 50,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                                  ),
                                ),
                              );
                            }
                            return SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  'Đăng nhập',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Chưa có tài khoản? ',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/register');
                              },
                              child: Text(
                                'Đăng ký',
                                style: GoogleFonts.poppins(
                                  color: primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String label;

  const _GoogleButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFF4285F4), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: const Color(0xFF4285F4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.g_mobiledata, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}