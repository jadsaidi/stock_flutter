import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/quantum_background.dart';
import '../widgets/neon_button.dart';
import '../widgets/glass_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clientIdController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _clientIdController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      if (_isLogin) {
        await authService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authService.registerWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _clientIdController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QuantumBackground(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glow
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.quantumGradient,
                      boxShadow: [
                        BoxShadow(color: AppColors.neonPurple.withOpacity(0.5), blurRadius: 30, spreadRadius: 2),
                        BoxShadow(color: AppColors.neonCyan.withOpacity(0.3), blurRadius: 40, spreadRadius: 0),
                      ],
                    ),
                    child: const Icon(Icons.inventory_2_rounded, size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 28),
                  
                  // Title with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
                    child: Text(
                      'VIP CODING STOCK',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestion de stock SaaS simplifiée',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 48),

                  // Login Card
                  GlassCard(
                    child: Column(
                      children: [
                        // Tabs
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _isLogin ? AppColors.neonCyan : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Connexion',
                                      style: TextStyle(
                                        color: _isLogin ? AppColors.neonCyan : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isLogin = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: !_isLogin ? AppColors.neonPurple : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Inscription',
                                      style: TextStyle(
                                        color: !_isLogin ? AppColors.neonPurple : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Fields
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: ShaderMask(
                              shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
                              child: const Icon(Icons.email_outlined, color: Colors.white),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: ShaderMask(
                              shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
                              child: const Icon(Icons.lock_outline, color: Colors.white),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Column(
                            children: [
                              const SizedBox(height: 16),
                              TextField(
                                controller: _clientIdController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'ID Client (Entreprise)',
                                  prefixIcon: ShaderMask(
                                    shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
                                    child: const Icon(Icons.business, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          crossFadeState: _isLogin ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 300),
                        ),
                        const SizedBox(height: 32),

                        // Submit
                        NeonButton(
                          text: _isLogin ? 'SE CONNECTER' : 'CRÉER UN COMPTE',
                          isLoading: _isLoading,
                          icon: _isLogin ? Icons.login : Icons.person_add,
                          onPressed: _submit,
                        ),
                      ],
                    ),
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
