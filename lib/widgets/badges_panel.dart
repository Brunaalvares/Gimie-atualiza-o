import 'package:flutter/material.dart';

import '../models/badge_model.dart';

class BadgesPanel extends StatelessWidget {
  final List<BadgeProgress> badges;
  final bool isLoading;
  final String? errorMessage;

  const BadgesPanel({
    super.key,
    required this.badges,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    if (badges.isEmpty) {
      return const Center(child: Text('Nenhum badge disponível.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: badges.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final badge = badges[index];
        final progress = badge.target <= 0
            ? 0.0
            : (badge.current / badge.target).clamp(0.0, 1.0);
        final color = badge.earned
            ? const Color(0xFF6B2C5C)
            : badge.isComingSoon
                ? Colors.grey
                : const Color(0xFF8B7FB8);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      badge.earned
                          ? Icons.workspace_premium
                          : Icons.workspace_premium_outlined,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        badge.title,
                        style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (badge.isComingSoon)
                      const Chip(label: Text('Em breve'))
                    else if (badge.earned)
                      const Chip(label: Text('Conquistado')),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  badge.description,
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
                ),
                if (!badge.isComingSoon) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 4),
                  Text(
                    badge.progressLabel ?? '${badge.current}/${badge.target}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
