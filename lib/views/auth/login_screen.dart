import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../viewmodels/providers.dart';
import '../../data/models/user_model.dart';
import '../home/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        // Create user profile in Firestore
        final firestoreService = ref.read(firestoreServiceProvider);
        final userModel = UserModel(
          uid: user.uid,
          email: user.email!,
          createdAt: DateTime.now(),
        );
        await firestoreService.saveUser(userModel);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.movie_outlined,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'CineTalk',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Sinema tutkunlarının buluşma noktası',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.secondary),
                  ),
                  const SizedBox(height: 48),

                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'E-posta veya Kullanıcı Adı',
                      hintText: 'kullanici@cine.talk',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppTheme.textHint,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta gerekli';
                      }
                      if (!value.contains('@')) {
                        return 'Geçerli bir e-posta girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      hintText: '••••••••',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppTheme.textHint,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textHint,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre gerekli';
                      }
                      if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalı';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      child: Text(
                        'Şifremi Unuttum',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Giriş Yap'),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      child: const Text('Kayıt Ol'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.textHint)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'VEYA ŞUNUNLA DEVAM ET',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.textHint)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social Login Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(
                        icon: Icons.g_mobiledata,
                        onTap: () {
                          // TODO: Google Sign In
                        },
                      ),
                      const SizedBox(width: 16),
                      _SocialButton(
                        icon: Icons.apple,
                        onTap: () {
                          // TODO: Apple Sign In
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Footer Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Kullanım Koşulları',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Text(
                        '•',
                        style: TextStyle(color: AppTheme.textHint),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Gizlilik Politikası',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Text(
                        '•',
                        style: TextStyle(color: AppTheme.textHint),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Yardım',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 12,
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
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textHint.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 32, color: AppTheme.textPrimary),
      ),
    );
  }
}
