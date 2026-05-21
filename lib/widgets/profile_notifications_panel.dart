import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/user_notification_model.dart';
import '../screens/user_profile_screen.dart';
import '../services/firebase_service.dart';

class ProfileNotificationsPanel extends StatefulWidget {
  final String userId;

  const ProfileNotificationsPanel({super.key, required this.userId});

  @override
  State<ProfileNotificationsPanel> createState() =>
      _ProfileNotificationsPanelState();
}

class _ProfileNotificationsPanelState extends State<ProfileNotificationsPanel> {
  final FirebaseService _firebase = FirebaseService();
  bool _isClearing = false;

  static String _formatAge(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} d';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  Future<void> _openActorProfile(BuildContext context, String actorId) async {
    final user = await _firebase.getUserDocument(actorId);
    if (!context.mounted) return;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o perfil'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UserProfileScreen(user: user),
      ),
    );
  }

  Future<void> _confirmAndClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Limpar notificações',
          style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Todas as notificações serão apagadas. Deseja continuar?',
          style: TextStyle(fontFamily: 'Roboto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF6B2C5C)),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isClearing = true);
    try {
      await _firebase.clearAllUserNotifications(widget.userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificações removidas'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível limpar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserNotification>>(
      stream: _firebase.getUserNotificationsStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Não foi possível carregar as notificações.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sem notificações ainda',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quando alguém seguir você ou curtir um dos seus produtos, aparecerá aqui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      _isClearing ? null : () => _confirmAndClear(context),
                  icon: _isClearing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline, size: 20),
                  label: Text(_isClearing ? 'Limpando…' : 'Limpar todas'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B2C5C),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final n = items[index];
                  final icon = n.type == 'like'
                      ? Icons.favorite_outline
                      : Icons.person_add_alt_1_outlined;
                  return Card(
                    elevation: 0,
                    color: const Color(0xFFF8F6FB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFF6B2C5C).withValues(alpha: 0.12),
                        child: Icon(icon,
                            color: const Color(0xFF6B2C5C), size: 22),
                      ),
                      title: Text(
                        n.displayTitle,
                        style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF6B2C5C),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          n.displaySubtitle,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ),
                      trailing: Text(
                        _formatAge(n.createdAt),
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      onTap: n.actorId.isEmpty
                          ? null
                          : () => _openActorProfile(context, n.actorId),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
