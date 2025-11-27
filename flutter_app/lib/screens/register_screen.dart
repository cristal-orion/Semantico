import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/pop_theme.dart';
import 'onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool showOnboardingAfter;

  const RegisterScreen({super.key, this.showOnboardingAfter = true});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  // final _emailController = TextEditingController();
  // final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    // _emailController.dispose();
    // _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    try {
      await authProvider.register(
        _usernameController.text.trim(),
        '', // Email opzionale/rimossa
        _passwordController.text,
      );

      if (mounted) {
        if (widget.showOnboardingAfter) {
          // Show onboarding after registration
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(
                onComplete: () {
                  // Go back to home after onboarding
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),
          );
        } else {
          // Pop register screen AND login screen to go back to home/profile
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Error is handled by provider
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PopTheme.cyan,
      appBar: AppBar(
        title: Text('Registrati', style: PopTheme.headingStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: PopTheme.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: PopTheme.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: PopTheme.black, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: PopTheme.black,
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crea Account',
                        style: PopTheme.headingStyle.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      if (auth.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text(
                            auth.error!,
                            style: TextStyle(color: Colors.red.shade900),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: PopTheme.black, width: 2),
                          ),
                          prefixIcon: Icon(Icons.person, color: PopTheme.black),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci un username';
                          }
                          if (value.length < 3) {
                            return 'Minimo 3 caratteri';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email field removed
                      // const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: PopTheme.black, width: 2),
                          ),
                          prefixIcon: Icon(Icons.lock, color: PopTheme.black),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: PopTheme.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci una password';
                          }
                          if (value.length < 6) {
                            return 'Minimo 6 caratteri';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Conferma Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: PopTheme.black, width: 2),
                          ),
                          prefixIcon: Icon(Icons.lock_outline, color: PopTheme.black),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Le password non coincidono';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PopTheme.black,
                          foregroundColor: PopTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'REGISTRATI',
                                style: PopTheme.bodyStyle.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
