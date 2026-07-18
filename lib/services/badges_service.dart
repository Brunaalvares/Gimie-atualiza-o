import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/badge_model.dart';
import 'firebase_service.dart';

class BadgesService {
  BadgesService._internal();
  static final BadgesService instance = BadgesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebase = FirebaseService();

  static const String trendsetterBadgeId = 'trendsetter';

  static const List<BadgeDefinition> catalog = [
    BadgeDefinition(
      id: 'first_wish',
      title: 'Primeiro Desejo',
      description: 'Salvou seu primeiro produto.',
      category: 'Primeiros Passos',
      tier: 'Onboarding',
      target: 1,
    ),
    BadgeDefinition(
      id: 'organized',
      title: 'Organizado',
      description: 'Criou sua primeira pasta.',
      category: 'Primeiros Passos',
      tier: 'Onboarding',
      target: 1,
    ),
    BadgeDefinition(
      id: 'profile_complete',
      title: 'Perfil Completo',
      description: 'Adicionou foto e biografia.',
      category: 'Primeiros Passos',
      tier: 'Onboarding',
      target: 1,
    ),
    BadgeDefinition(
      id: 'first_connection',
      title: 'Primeira Conexão',
      description: 'Seguiu sua primeira pessoa.',
      category: 'Primeiros Passos',
      tier: 'Onboarding',
      target: 1,
    ),
    BadgeDefinition(
      id: 'first_interaction',
      title: 'Primeira Interação',
      description: 'Curtiu um item de outro usuário.',
      category: 'Primeiros Passos',
      tier: 'Onboarding',
      target: 1,
    ),
    BadgeDefinition(
      id: 'collector_bronze',
      title: 'Caçador de Achados',
      description: 'Salvou 10 produtos.',
      category: 'Colecionador',
      tier: 'Bronze',
      target: 10,
    ),
    BadgeDefinition(
      id: 'collector_silver',
      title: 'Especialista em Achados',
      description: 'Salvou 50 produtos.',
      category: 'Colecionador',
      tier: 'Prata',
      target: 50,
    ),
    BadgeDefinition(
      id: 'collector_gold',
      title: 'Mestre das Descobertas',
      description: 'Salvou 200 produtos.',
      category: 'Colecionador',
      tier: 'Ouro',
      target: 200,
    ),
    BadgeDefinition(
      id: 'collector_diamond',
      title: 'Lenda das Compras',
      description: 'Salvou 1000 produtos.',
      category: 'Colecionador',
      tier: 'Diamante',
      target: 1000,
    ),
    BadgeDefinition(
      id: 'wishlist_full',
      title: 'Wishlist Lotada',
      description: 'Possui mais de 100 produtos salvos.',
      category: 'Colecionador',
      tier: 'Especial',
      target: 100,
    ),
    BadgeDefinition(
      id: 'social_10',
      title: 'Sociável',
      description: 'Seguiu 10 pessoas.',
      category: 'Social',
      tier: 'Social',
      target: 10,
    ),
    BadgeDefinition(
      id: 'explorer_20',
      title: 'Explorador',
      description: 'Visitou 20 perfis ou produtos.',
      category: 'Social',
      tier: 'Social',
      target: 20,
    ),
    BadgeDefinition(
      id: 'curious_30',
      title: 'Curioso',
      description: 'Pesquisou 30 produtos.',
      category: 'Social',
      tier: 'Social',
      target: 30,
    ),
    BadgeDefinition(
      id: 'streak_7',
      title: '7 Dias Seguidos',
      description: 'Consistência de acesso por uma semana.',
      category: 'Consistência',
      tier: 'Streak',
      target: 7,
    ),
    BadgeDefinition(
      id: 'streak_30',
      title: '30 Dias Seguidos',
      description: 'Consistência de acesso por um mês.',
      category: 'Consistência',
      tier: 'Streak',
      target: 30,
    ),
    BadgeDefinition(
      id: trendsetterBadgeId,
      title: 'Criador de Tendências',
      description: 'Uma pasta recebeu 100 visualizações.',
      category: 'Comunidade',
      tier: 'Impacto',
      target: 100,
    ),
    BadgeDefinition(
      id: 'ambassador_soon',
      title: 'Embaixador Gimie',
      description: 'Convidou amigos que se cadastraram.',
      category: 'Comunidade',
      tier: 'Em breve',
      target: 1,
      isComingSoon: true,
    ),
  ];

  Stream<List<BadgeProgress>> watchBadges(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('badge_progress')
        .snapshots()
        .map((snap) {
      final byId = {
        for (final d in snap.docs)
          d.id: BadgeProgress.fromFirestore(d.id, d.data()),
      };
      return catalog.map((def) {
        return byId[def.id] ??
            BadgeProgress(
              badgeId: def.id,
              title: def.title,
              description: def.description,
              category: def.category,
              tier: def.tier,
              target: def.target,
              current: 0,
              earned: false,
              progressLabel: def.id == trendsetterBadgeId
                  ? 'Faltam ${def.target} visualizações para desbloquear'
                  : null,
              isComingSoon: def.isComingSoon,
            );
      }).toList();
    });
  }

  Future<void> evaluateAndSync(String userId) async {
    // Regras Firestore só permitem escrever badge_progress/metrics do próprio
    // utilizador; eventos de terceiros são avaliados quando o dono usa o app.
    if (_firebase.currentUser?.uid != userId) return;
    try {
      await _evaluateAndSyncOwn(userId);
    } catch (e) {
      debugPrint('Badges evaluateAndSync error: $e');
    }
  }

  Future<void> _evaluateAndSyncOwn(String userId) async {
    final user = await _firebase.getUserDocument(userId);
    if (user == null) return;
    final products = await _firebase.getUserProducts(userId);
    final metrics = await _firebase.getMetricsSummary(userId);
    final topFolders = await _firebase.getTopViewedFolders(userId, limit: 50);
    // Criador de Tendências: 100 views em UMA pasta (não soma de todas).
    final trendViews = topFolders.fold<int>(
      0,
      (best, entry) {
        final count = (entry['viewCount'] as num?)?.toInt() ?? 0;
        return count > best ? count : best;
      },
    );
    final folderCount = {
      ...products
          .map((p) => (p.category ?? '').trim())
          .where((c) => c.isNotEmpty)
          .toSet(),
      ...user.emptyFolders,
    }.length;

    final visitedCount = metrics.profileVisits + metrics.productVisits;
    final follows = user.followingIds.length;
    final savedProducts = products.length;

    final values = <String, int>{
      'first_wish': savedProducts > 0 ? 1 : 0,
      'organized': folderCount > 0 ? 1 : 0,
      'profile_complete': ((user.photoUrl?.trim().isNotEmpty == true) &&
              (user.bio?.trim().isNotEmpty == true))
          ? 1
          : 0,
      'first_connection': follows > 0 ? 1 : 0,
      'first_interaction': metrics.likesGiven > 0 ? 1 : 0,
      'collector_bronze': savedProducts,
      'collector_silver': savedProducts,
      'collector_gold': savedProducts,
      'collector_diamond': savedProducts,
      'wishlist_full': savedProducts,
      'social_10': follows,
      'explorer_20': visitedCount,
      'curious_30': metrics.searchCount,
      'streak_7': metrics.streakDays,
      'streak_30': metrics.streakDays,
      trendsetterBadgeId: trendViews,
      'ambassador_soon': 0,
    };

    final col =
        _firestore.collection('users').doc(userId).collection('badge_progress');
    final previous = await col.get();
    final prevEarned = <String, bool>{
      for (final d in previous.docs) d.id: d.data()['earned'] == true,
    };

    for (final badge in catalog) {
      final current = values[badge.id] ?? 0;
      final earned = !badge.isComingSoon && current >= badge.target;
      final wasEarned = prevEarned[badge.id] == true;
      final missing = (badge.target - current).clamp(0, badge.target);
      final progressLabel = badge.id == trendsetterBadgeId && !earned
          ? 'Faltam $missing visualizações para desbloquear'
          : null;

      final payload = <String, dynamic>{
        'badgeId': badge.id,
        'title': badge.title,
        'description': badge.description,
        'category': badge.category,
        'tier': badge.tier,
        'target': badge.target,
        'current': current,
        'earned': earned,
        'updatedAt': FieldValue.serverTimestamp(),
        'progressLabel': progressLabel,
        'isComingSoon': badge.isComingSoon,
      };
      if (!wasEarned && earned) {
        payload['earnedAt'] = FieldValue.serverTimestamp();
      }

      await col.doc(badge.id).set(payload, SetOptions(merge: true));

      if (!wasEarned && earned) {
        await _firebase.createInternalNotification(
          recipientId: userId,
          actorId: userId,
          type: 'badge_earned',
          badgeId: badge.id,
          badgeName: badge.title,
        );
      }
    }
  }
}
