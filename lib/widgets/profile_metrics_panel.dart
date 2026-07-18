import 'package:flutter/material.dart';

import '../services/firebase_service.dart';

class ProfileMetricsPanel extends StatefulWidget {
  final String userId;

  const ProfileMetricsPanel({super.key, required this.userId});

  @override
  State<ProfileMetricsPanel> createState() => _ProfileMetricsPanelState();
}

class _ProfileMetricsPanelState extends State<ProfileMetricsPanel> {
  final FirebaseService _firebase = FirebaseService();
  bool _loading = true;
  String? _error;
  int _followers = 0;
  List<Map<String, dynamic>> _topLiked = const [];
  List<Map<String, dynamic>> _topFolders = const [];
  List<Map<String, dynamic>> _topShopNow = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final followers = await _firebase.getFollowersCount(widget.userId);
      final products = await _firebase.getUserProducts(widget.userId);
      final topLiked = products..sort((a, b) => b.likes.compareTo(a.likes));
      final folders = await _firebase.getTopViewedFolders(widget.userId);
      final shopNow = await _firebase.getTopProductStats(widget.userId);
      if (!mounted) return;
      setState(() {
        _followers = followers;
        _topLiked = topLiked
            .take(3)
            .map((p) => {
                  'name': p.name,
                  'likes': p.likes,
                })
            .toList();
        _topFolders = folders.take(3).toList();
        _topShopNow = shopNow.take(20).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MetricCard(
            title: 'Seguidores',
            child: Text(
              _followers.toString(),
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                fontSize: 28,
                color: Color(0xFF6B2C5C),
              ),
            ),
          ),
          _MetricCard(
            title: 'Top 3 produtos mais curtidos',
            child: _topLiked.isEmpty
                ? const Text('Sem dados ainda')
                : Column(
                    children: _topLiked
                        .map(
                          (item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item['name']?.toString() ?? ''),
                            trailing: Text('${item['likes'] ?? 0} curtidas'),
                          ),
                        )
                        .toList(),
                  ),
          ),
          _MetricCard(
            title: 'Top 3 pastas mais visualizadas',
            child: _topFolders.isEmpty
                ? const Text('Sem visualizações ainda')
                : Column(
                    children: _topFolders
                        .map(
                          (item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item['folderName']?.toString() ?? ''),
                            trailing: Text('${item['viewCount'] ?? 0} views'),
                          ),
                        )
                        .toList(),
                  ),
          ),
          _MetricCard(
            title: 'Shop Now por produto salvo',
            child: _topShopNow.isEmpty
                ? const Text('Sem cliques ainda')
                : Column(
                    children: _topShopNow
                        .map(
                          (item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item['productName']?.toString() ?? ''),
                            trailing:
                                Text('${item['shopNowClicks'] ?? 0} cliques'),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _MetricCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
