import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/trend_models.dart';
import '../services/trends_service.dart';
import 'admin_trends_screen.dart';

/// Feed público da aba **Trends** (pastas, mood board 1:1, cards com link).
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  Future<List<TrendBoardContent>>? _future;

  @override
  void initState() {
    super.initState();
    _future = TrendsService.instance.fetchAllTrendsContent();
  }

  Future<void> _reload() async {
    setState(() {
      _future = TrendsService.instance.fetchAllTrendsContent();
    });
    await _future;
  }

  Future<void> _openUrl(String raw) async {
    final t = raw.trim();
    if (t.isEmpty) return;
    final uri = Uri.tryParse(t) ?? Uri.tryParse('https://$t');
    if (uri == null) return;
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trends',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B2C5C),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          FutureBuilder<bool>(
            future: TrendsService.instance.isCurrentUserAdmin(),
            builder: (context, snap) {
              if (snap.data != true) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Editar Trends',
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF6B2C5C)),
                onPressed: () async {
                  final ok = await TrendsService.instance.isCurrentUserAdmin();
                  if (!context.mounted) return;
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sem permissão de admin Trends'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminTrendsHomeScreen(),
                    ),
                  );
                  _reload();
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<TrendBoardContent>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Não foi possível carregar Trends.\n${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              );
            }
            final data = snapshot.data ?? const <TrendBoardContent>[];
            if (data.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                children: const [
                  Center(
                    child: Text(
                      'Em breve: curadoria Gimie neste espaço.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: data.length,
              itemBuilder: (context, i) {
                final block = data[i];
                return _TrendBoardBlock(
                  content: block,
                  onOpenUrl: _openUrl,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TrendBoardBlock extends StatelessWidget {
  final TrendBoardContent content;
  final void Function(String url) onOpenUrl;

  const _TrendBoardBlock({
    required this.content,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final board = content.board;
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              board.title,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Color(0xFF6B2C5C),
              ),
            ),
            if (content.moods.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Mood',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF8B7FB8),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: MediaQuery.sizeOf(context).width * 0.72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: content.moods.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, j) {
                    final m = content.moods[j];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CachedNetworkImage(
                          imageUrl: m.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey.shade200),
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (content.products.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Produtos',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF8B7FB8),
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: content.products.length,
                itemBuilder: (context, k) {
                  final p = content.products[k];
                  final priceLine = (p.priceDisplay ?? '').trim();
                  return InkWell(
                    onTap: () => onOpenUrl(p.linkUrl),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: p.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: Colors.grey.shade200),
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (priceLine.isNotEmpty)
                          Text(
                            priceLine,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Color(0xFF6B2C5C),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
