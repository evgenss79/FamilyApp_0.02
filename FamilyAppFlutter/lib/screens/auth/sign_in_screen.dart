import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _familyController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();

  bool _registerMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _familyController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    context.read<AuthProvider>().clearError();
    setState(() {
      _registerMode = !_registerMode;
    });
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    final AuthProvider auth = context.read<AuthProvider>();
    auth.clearError();
    if (_registerMode) {
      await auth.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
        familyName: _familyController.text.trim(),
        relationship: _relationshipController.text.trim().isEmpty
            ? null
            : _relationshipController.text.trim(),
      );
    } else {
      await auth.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
    final String? error = auth.errorMessage;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _googleSignIn() async {
    final AuthProvider auth = context.read<AuthProvider>();
    auth.clearError();
    await auth.signInWithGoogle();
    final String? error = auth.errorMessage;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    final AuthProvider auth = context.watch<AuthProvider>();
    final bool busy = auth.isBusy;

    return Scaffold(
      appBar: AppBar(
        title: Text(_registerMode ? loc.tr('registerTitle') : loc.tr('signInTitle')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _registerMode
                    ? loc.tr('registerSubtitle')
                    : loc.tr('signInSubtitle'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: loc.tr('emailLabel')),
                keyboardType: TextInputType.emailAddress,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return loc.tr('emailRequired');
                  }
                  if (!value.contains('@')) {
                    return loc.tr('emailInvalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: loc.tr('passwordLabel')),
                obscureText: true,
                validator: (String? value) {
                  if (value == null || value.length < 6) {
                    return loc.tr('passwordTooShort');
                  }
                  return null;
                },
              ),
              if (_registerMode) ...<Widget>[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration:
                      InputDecoration(labelText: loc.tr('displayNameLabel')),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return loc.tr('displayNameRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _familyController,
                  decoration:
                      InputDecoration(labelText: loc.tr('familyNameLabel')),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return loc.tr('familyNameRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _relationshipController,
                  decoration:
                      InputDecoration(labelText: loc.tr('relationshipLabel')),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: busy ? null : _submit,
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_registerMode
                        ? loc.tr('createAccountButton')
                        : loc.tr('signInButton')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy ? null : _googleSignIn,
                icon: const Icon(Icons.account_circle),
                label: Text(loc.tr('signInWithGoogle')),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: busy ? null : _toggleMode,
                child: Text(
                  _registerMode
                      ? loc.tr('haveAccountQuestion')
                      : loc.tr('needAccountQuestion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
