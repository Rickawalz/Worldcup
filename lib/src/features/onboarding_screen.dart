import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _controller = TextEditingController();
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
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
                  strings.createFreeProfile,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(strings.onboardingIntro),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: strings.username,
                    helperText: strings.usernameHelp,
                    errorText: _error,
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child:
                      _isSaving
                          ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(strings.createProfile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final validationError = UsernameValidator.validate(_controller.text);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref
          .read(appRepositoryProvider)
          .createUsernameProfile(_controller.text);
      if (mounted) {
        context.go('/');
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
