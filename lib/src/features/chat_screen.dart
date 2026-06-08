import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/providers.dart';
import '../domain/models.dart';
import '../localization/app_strings.dart';
import '../widgets/dashboard.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  String? _error;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final user = ref.watch(currentUserProvider);
    final messages = ref.watch(globalChatMessagesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: DashboardHeader(
            title: strings.globalChat,
            subtitle: strings.chatExplainer,
            icon: Icons.chat_bubble_outline,
            stats: [
              DashboardStat(
                label: 'live room',
                value: 'Fans',
                icon: Icons.forum_outlined,
              ),
            ],
          ),
        ),
        Expanded(
          child: messages.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(child: Text(strings.noChatMessages));
              }
              return ListView.separated(
                reverse: true,
                padding: const EdgeInsets.all(24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final message = items[index];
                  final currentUser = user.valueOrNull;
                  return _MessageCard(
                    message: message,
                    currentUserId: currentUser?.id,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Chat error: $error')),
          ),
        ),
        user.when(
          data: (value) {
            if (value == null) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: ListTile(
                      title: Text(strings.createProfileToChat),
                      trailing: FilledButton(
                        onPressed: () => context.go('/onboarding'),
                        child: Text(strings.createUsername),
                      ),
                    ),
                  ),
                ),
              );
            }
            return _Composer(
              controller: _messageController,
              error: _error,
              isSending: _isSending,
              onSend: _send,
            );
          },
          loading: () => const LinearProgressIndicator(),
          error:
              (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Profile error: $error'),
              ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final strings = context.strings;
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = strings.messageRequired);
      return;
    }
    if (text.length > ChatMessage.maxTextLength) {
      setState(() => _error = strings.messageTooLong);
      return;
    }
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await ref.read(appRepositoryProvider).sendChatMessage(text);
      _messageController.clear();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.error,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final String? error;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: ChatMessage.maxTextLength,
                decoration: InputDecoration(
                  labelText: strings.message,
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: isSending ? null : onSend,
              icon: const Icon(Icons.send_outlined),
              label: Text(strings.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends ConsumerStatefulWidget {
  const _MessageCard({required this.message, required this.currentUserId});

  final ChatMessage message;
  final String? currentUserId;

  @override
  ConsumerState<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends ConsumerState<_MessageCard> {
  late final TextEditingController _editController;
  bool _isEditing = false;
  String? _editError;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.text);
  }

  @override
  void didUpdateWidget(covariant _MessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.message.text != widget.message.text) {
      _editController.text = widget.message.text;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final message = widget.message;
    final isMine = message.userId == widget.currentUserId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(_initial(message.username))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.username,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        DateFormat.yMMMd(
                          Localizations.localeOf(context).toLanguageTag(),
                        ).add_jm().format(message.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (message.isEdited && !message.isDeleted)
                  Text(
                    strings.edited,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (isMine && !message.isDeleted)
                  PopupMenuButton<_MessageAction>(
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: _MessageAction.edit,
                            child: Text(strings.edit),
                          ),
                          PopupMenuItem(
                            value: _MessageAction.delete,
                            child: Text(strings.delete),
                          ),
                        ],
                    onSelected: (action) {
                      switch (action) {
                        case _MessageAction.edit:
                          setState(() => _isEditing = true);
                        case _MessageAction.delete:
                          ref
                              .read(appRepositoryProvider)
                              .deleteChatMessage(message.id);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (message.isDeleted)
              Text(
                strings.deletedMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              )
            else if (_isEditing)
              _EditMessageForm(
                controller: _editController,
                error: _editError,
                onCancel: () {
                  setState(() {
                    _isEditing = false;
                    _editError = null;
                    _editController.text = message.text;
                  });
                },
                onSave: _saveEdit,
              )
            else
              Text(message.text),
            if (!message.isDeleted) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final entry in message.reactions.entries)
                    ActionChip(
                      label: Text('${entry.key} ${entry.value}'),
                      onPressed: () => _react(entry.key),
                    ),
                  for (final emoji in const ['⚽', '🔥', '👏', '🏆'])
                    ActionChip(
                      tooltip: strings.addReaction,
                      label: Text(emoji),
                      onPressed: () => _react(emoji),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveEdit() async {
    final strings = context.strings;
    final text = _editController.text.trim();
    if (text.isEmpty) {
      setState(() => _editError = strings.messageRequired);
      return;
    }
    if (text.length > ChatMessage.maxTextLength) {
      setState(() => _editError = strings.messageTooLong);
      return;
    }
    await ref
        .read(appRepositoryProvider)
        .editChatMessage(messageId: widget.message.id, text: text);
    setState(() {
      _isEditing = false;
      _editError = null;
    });
  }

  Future<void> _react(String emoji) {
    return ref
        .read(appRepositoryProvider)
        .reactToChatMessage(messageId: widget.message.id, emoji: emoji);
  }

  String _initial(String username) {
    return username.isEmpty ? '?' : username.characters.first.toUpperCase();
  }
}

class _EditMessageForm extends StatelessWidget {
  const _EditMessageForm({
    required this.controller,
    required this.error,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          minLines: 1,
          maxLines: 4,
          maxLength: ChatMessage.maxTextLength,
          decoration: InputDecoration(
            labelText: strings.message,
            errorText: error,
            border: const OutlineInputBorder(),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(onPressed: onCancel, child: Text(strings.cancel)),
            FilledButton(onPressed: onSave, child: Text(strings.save)),
          ],
        ),
      ],
    );
  }
}

enum _MessageAction { edit, delete }
