import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product_model.dart';
import '../models/trend_models.dart';
import '../services/firebase_service.dart';
import '../services/trends_service.dart';
import 'admin_trends_screen.dart';

/// Feed público da aba **Trends** (pastas, mood board 1:1, cards com link).
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Future<_TrendsPageData>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPageData();
  }

  Future<_TrendsPageData> _loadPageData() async {
    try {
      debugPrint('=== TRENDS: Starting data load ===');
      
      final results = await Future.wait<dynamic>([
        TrendsService.instance.fetchAllTrendsContent(),
        _firebaseService.getProducts(limit: 100),
      ]);
      
      final boards = results[0] as List<TrendBoardContent>;
      final currentUserId = _firebaseService.currentUser?.uid;
      final allProducts = results[1] as List<Product>;
      
      debugPrint('TRENDS: Boards loaded: ${boards.length}');
      debugPrint('TRENDS: All products fetched: ${allProducts.length}');
      debugPrint('TRENDS: Current user ID: $currentUserId');
      
      // Debug: contar produtos por filtro
      int withUserId = 0;
      int notCurrentUser = 0;
      int withImage = 0;
      
      for (final product in allProducts) {
        if (product.userId.isNotEmpty) withUserId++;
        if (product.userId != currentUserId) notCurrentUser++;
        if (product.imageUrl.isNotEmpty && product.imageUrl.trim().isNotEmpty) {
          withImage++;
        }
      }
      
      debugPrint('TRENDS: Products with userId: $withUserId');
      debugPrint('TRENDS: Products from other users: $notCurrentUser');
      debugPrint('TRENDS: Products with image: $withImage');
      
      final products = allProducts
          .where(
            (product) =>
                product.userId.isNotEmpty &&
                product.userId != currentUserId &&
                (product.imageUrl.isNotEmpty && 
                 product.imageUrl.trim().isNotEmpty),
          )
          .toList();
      
      debugPrint('TRENDS: Filtered products: ${products.length}');
      
      if (products.isNotEmpty) {
        products.sort((a, b) {
          final byLikes = b.likes.compareTo(a.likes);
          if (byLikes != 0) return byLikes;
          return b.createdAt.compareTo(a.createdAt);
        });
        
        debugPrint('TRENDS: Top product likes: ${products.first.likes}');
      }

      final popularProducts = products.take(12).toList();
      debugPrint('TRENDS: Popular products to display: ${popularProducts.length}');

      return _TrendsPageData(
        boards: boards,
        popularProducts: popularProducts,
      );
    } catch (e, stackTrace) {
      debugPrint('ERROR loading trends data: $e');
      debugPrint('Stack trace: $stackTrace');
      return const _TrendsPageData();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadPageData();
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
        child: FutureBuilder<_TrendsPageData>(
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
            final data = snapshot.data ?? const _TrendsPageData();
            if (data.boards.isEmpty && data.popularProducts.isEmpty) {
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
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (data.popularProducts.isNotEmpty)
                  _PopularProductsSection(
                    products: data.popularProducts,
                    onOpenUrl: _openUrl,
                  ),
                ...data.boards.map(
                  (block) => _TrendBoardBlock(
                    content: block,
                    onOpenUrl: _openUrl,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TrendsPageData {
  final List<TrendBoardContent> boards;
  final List<Product> popularProducts;

  const _TrendsPageData({
    this.boards = const [],
    this.popularProducts = const [],
  });
}

class _PopularProductsSection extends StatelessWidget {
  final List<Product> products;
  final void Function(String url) onOpenUrl;

  const _PopularProductsSection({
    required this.products,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mais desejados pela comunidade',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF6B2C5C),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Produtos salvos por outros usuários, ordenados pelos mais curtidos.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return SizedBox(
                    width: 150,
                    child: InkWell(
                      onTap: () => onOpenUrl(product.url),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: Colors.grey.shade200),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey.shade100,
                                  child:
                                      const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 15,
                                color: Color(0xFF6B2C5C),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${product.likes} curtida${product.likes == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: Color(0xFF6B2C5C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
