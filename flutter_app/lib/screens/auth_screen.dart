import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/cosmic_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscure = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    bool success;
    if (_isLogin) {
      success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    } else {
      success = await auth.signup(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
    }
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: CosmicTheme.cosmicGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: CosmicTheme.goldGradient,
                        boxShadow: [BoxShadow(color: CosmicTheme.starGold.withOpacity(0.3), blurRadius: 24)],
                      ),
                      child: const Icon(Icons.auto_awesome, size: 36, color: Color(0xFF0A0E1A)),
                    ),
                    const SizedBox(height: 24),
                    Text('JYOTISH AI', style: Theme.of(context).textTheme.headlineLarge?.copyWith(letterSpacing: 4)),
                    const SizedBox(height: 8),
                    Text(_isLogin ? 'Welcome Back' : 'Begin Your Journey',
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 40),

                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (!_isLogin && (v == null || v.isEmpty)) ? 'Name required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passCtrl,
                      decoration: InputDecoration(
                        labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 8),

                    if (auth.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(auth.error!, style: const TextStyle(color: CosmicTheme.marsRed, fontSize: 13)),
                      ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_isLogin ? 'Sign In' : 'Create Account'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? "Don't have an account? Sign Up" : 'Already have an account? Sign In',
                        style: TextStyle(color: CosmicTheme.moonSilver.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
