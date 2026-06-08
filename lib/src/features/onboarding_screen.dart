import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../data/username_validator.dart';
import '../localization/app_strings.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _signInIdentifierController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _createPasswordController = TextEditingController();
  String? _signInError;
  String? _createError;
  bool _isSigningIn = false;
  bool _isCreating = false;
  bool _isResettingPassword = false;

  @override
  void dispose() {
    _signInIdentifierController.dispose();
    _signInPasswordController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _createPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    if (currentUser != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.welcome(currentUser.username),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(strings.alreadySignedIn),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/bracket'),
                    child: Text(strings.openBracket),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.accountAccess,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(strings.onboardingIntro),
                    const SizedBox(height: 20),
                    TabBar(
                      tabs: [
                        Tab(text: strings.signIn),
                        Tab(text: strings.createAccount),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 430,
                      child: TabBarView(
                        children: [
                          _SignInForm(parent: this),
                          _CreateForm(parent: this),
                        ],
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

  Future<void> _createAccount() async {
    final validationError = UsernameValidator.validate(
      _usernameController.text,
    );
    if (validationError != null) {
      setState(() => _createError = validationError);
      return;
    }
    if (_createPasswordController.text.length < 6) {
      setState(() => _createError = context.strings.passwordMinLength);
      return;
    }
    if (_emailController.text.trim().isEmpty &&
        _phoneController.text.trim().isEmpty) {
      setState(() => _createError = context.strings.emailOrPhoneRequired);
      return;
    }
    setState(() {
      _isCreating = true;
      _createError = null;
    });
    try {
      await ref
          .read(appRepositoryProvider)
          .createAccount(
            username: _usernameController.text,
            password: _createPasswordController.text,
            email: _emailController.text,
            phone: _phoneController.text,
          );
      if (mounted) {
        context.go('/');
      }
    } catch (error) {
      setState(() => _createError = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _signIn() async {
    final strings = context.strings;
    if (_signInIdentifierController.text.trim().isEmpty) {
      setState(() => _signInError = strings.usernameOrEmailRequired);
      return;
    }
    if (_signInPasswordController.text.isEmpty) {
      setState(() => _signInError = strings.passwordRequired);
      return;
    }
    setState(() {
      _isSigningIn = true;
      _signInError = null;
    });
    try {
      await ref
          .read(appRepositoryProvider)
          .signInWithIdentifierAndPassword(
            identifier: _signInIdentifierController.text,
            password: _signInPasswordController.text,
          );
      if (mounted) {
        context.go('/');
      }
    } catch (error) {
      setState(() => _signInError = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final strings = context.strings;
    if (_signInIdentifierController.text.trim().isEmpty) {
      setState(() => _signInError = strings.usernameOrEmailRequired);
      return;
    }
    setState(() {
      _isResettingPassword = true;
      _signInError = null;
    });
    try {
      await ref
          .read(appRepositoryProvider)
          .sendPasswordReset(_signInIdentifierController.text);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.passwordResetSent)));
      }
    } catch (error) {
      setState(() => _signInError = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isResettingPassword = false);
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is FirebaseException) {
      final message = error.message;
      if (message == null || message.isEmpty) {
        return '${error.plugin}/${error.code}';
      }
      return '${error.plugin}/${error.code}: $message';
    }
    return error.toString();
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm({required this.parent});

  final _OnboardingScreenState parent;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: parent._signInIdentifierController,
            decoration: InputDecoration(
              labelText: strings.usernameOrEmail,
              errorText: parent._signInError,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: parent._signInPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: strings.password,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => parent._signIn(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: parent._isSigningIn ? null : parent._signIn,
            child:
                parent._isSigningIn
                    ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(strings.signIn),
          ),
          TextButton(
            onPressed:
                parent._isResettingPassword ? null : parent._sendPasswordReset,
            child:
                parent._isResettingPassword
                    ? Text(strings.sendingPasswordReset)
                    : Text(strings.forgotPassword),
          ),
        ],
      ),
    );
  }
}

class _CreateForm extends StatelessWidget {
  const _CreateForm({required this.parent});

  final _OnboardingScreenState parent;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: parent._usernameController,
            decoration: InputDecoration(
              labelText: strings.username,
              helperText: strings.usernameHelp,
              errorText: parent._createError,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: parent._emailController,
            decoration: InputDecoration(
              labelText: strings.email,
              helperText: strings.emailOrPhoneHelp,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: parent._phoneController,
            decoration: InputDecoration(
              labelText: strings.phone,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: parent._createPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: strings.password,
              helperText: strings.passwordHelp,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => parent._createAccount(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: parent._isCreating ? null : parent._createAccount,
            child:
                parent._isCreating
                    ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(strings.createAccount),
          ),
        ],
      ),
    );
  }
}
