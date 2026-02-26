import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../viewmodels/providers.dart';
import '../main_wrapper.dart';
import 'sign_up_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
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
      await authService.signInWithIdentifier(
        _identifierController.text.trim(),
        _passwordController.text,
      );

      // Login successful → navigate immediately, don't wait for AuthGate
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      // Always stop the spinner if we're still on this screen
      if (mounted) {
        setState(() {
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
                    'Viewly',
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

                  // Identifier Input (Email or Username)
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'E-posta veya Kullanıcı Adı',
                      hintText: 'kullanici@gmail.com veya kullanici_adi',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppTheme.textHint,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta veya kullanıcı adı gerekli';
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
                        final emailController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            backgroundColor: AppTheme.surface,
                            title: const Text('Şifre Sıfırlama'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Kayıtlı e-posta adresinizi girin. Size bir şifre sıfırlama bağlantısı göndereceğiz.',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'E-posta Adresi',
                                    hintText: 'ornek@email.com',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final email = emailController.text.trim();
                                  if (email.isEmpty) return;

                                  // Show brief loading
                                  showDialog(
                                    context: dialogContext,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  try {
                                    await ref
                                        .read(authServiceProvider)
                                        .resetPassword(email);
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext); // loading
                                      Navigator.pop(
                                        dialogContext,
                                      ); // main dialog
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Şifre sıfırlama bağlantısı gönderildi. Lütfen Spam/Gereksiz kutunuzu da kontrol edin.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext); // loading
                                      ScaffoldMessenger.of(
                                        dialogContext,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Gönder'),
                              ),
                            ],
                          ),
                        );
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
                        color: AppTheme.error.withValues(alpha: 0.1),
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Giriş Yap'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sosyal medya ile giriş yakında eklenecektir.',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      _SocialButton(
                        icon: Icons.apple,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sosyal medya ile giriş yakında eklenecektir.',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Navigate to Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Hesabın yok mu?',
                        style: TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Kayıt Ol',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Footer Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _showInfoBottomSheet(
                          context,
                          'Kullanım Koşulları',
                          const TermsOfUseContent(),
                        ),
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
                        onPressed: () => _showInfoBottomSheet(
                          context,
                          'Gizlilik Politikası',
                          const PrivacyPolicyContent(),
                        ),
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
                        onPressed: () => _showInfoBottomSheet(
                          context,
                          'Hakkında',
                          const AboutContent(),
                        ),
                        child: const Text(
                          'Hakkında',
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

  void _showInfoBottomSheet(
    BuildContext context,
    String title,
    Widget content,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Content
              Flexible(child: SingleChildScrollView(child: content)),
              const SizedBox(height: 24),
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        );
      },
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
          border: Border.all(color: AppTheme.textHint.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 32, color: AppTheme.textPrimary),
      ),
    );
  }
}

class TermsOfUseContent extends StatelessWidget {
  const TermsOfUseContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viewly platformuna hoş geldiniz. Uygulamamızı kullanarak aşağıdaki kullanım koşullarını kabul etmiş olursunuz. Viewly, sinemaseverlerin buluştuğu sosyal bir tartışma platformudur.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Kullanıcılar, platform üzerinde açtıkları tartışmalarda ve yaptıkları yorumlarda saygı çerçevesinde hareket etmek zorundadır. Nefret söylemi, hakaret, kişisel haklara saldırı veya aşırı spoiler içeren paylaşımlar yöneticiler tarafından uyarısız silinebilir.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Hesap güvenliğiniz tamamen sizin sorumluluğunuzdadır. Uygulama içerisindeki kuralları ihlal etmeniz durumunda hesabınız dondurulabilir veya kalıcı olarak kapatılabilir. Viewly, bu koşulları önceden haber vermeksizin güncelleme hakkını saklı tutar.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class PrivacyPolicyContent extends StatelessWidget {
  const PrivacyPolicyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Viewly, kullanıcılarının gizliliğine büyük önem vermektedir. Kişisel verileriniz (e-posta adresi, kullanıcı adı vb.) 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında işlenmekte ve güvenli bir şekilde saklanmaktadır.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Kullanıcı verileriniz Firebase altyapısı kullanılarak uluslararası standartlarda güvenli bir şekilde şifrelenip depolanmaktadır. Verileriniz, uygulamanın çekirdek işlevleri dışında hiçbir 3. şahıs kurum veya ticari yapıyla paylaşılmaz.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'İstediğiniz zaman profil sekmesinden hesabınızı silebilirsiniz. Hesap silme işleminin ardından, tarafınıza ait tüm kişisel kayıtlar, veritabanımızdan kalıcı olarak ve geri döndürülemez bir biçimde yok edilecektir.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class AboutContent extends StatelessWidget {
  const AboutContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.movie, size: 50, color: Colors.blue),
        const SizedBox(height: 16),
        const Text(
          'Viewly',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'v1.0.0',
          style: TextStyle(color: AppTheme.textHint, fontSize: 14),
        ),
        const SizedBox(height: 24),
        const Text(
          'This product uses the TMDB API but is not endorsed or certified by TMDB.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final url = Uri.parse('https://www.themoviedb.org/');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'https://www.themoviedb.org/',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}
