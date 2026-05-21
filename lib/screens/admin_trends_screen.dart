import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/trend_models.dart';
import '../services/trends_service.dart';

/// Lista de pastas Trends (só utilizadores com `admins/{uid}.active`).
class AdminTrendsHomeScreen extends StatefulWidget {
  const AdminTrendsHomeScreen({super.key});

  @override
  State<AdminTrendsHomeScreen> createState() => _AdminTrendsHomeScreenState();
}

class _AdminTrendsHomeScreenState extends State<AdminTrendsHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await TrendsService.instance.isCurrentUserAdmin();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sem permissão de admin Trends'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends — admin'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6B2C5C),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
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
          try {
            final id = await TrendsService.instance.createBoard();
            if (!context.mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TrendBoardAdminScreen(boardId: id),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
            );
          }
        },
        backgroundColor: const Color(0xFF6B2C5C),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Nova pasta'),
      ),
      body: StreamBuilder<List<TrendBoard>>(
        stream: TrendsService.instance.watchBoards(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final boards = snap.data!;
          if (boards.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma pasta. Use “Nova pasta”.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: boards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = boards[i];
              return Card(
                child: ListTile(
                  title: Text(
                    b.title,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text('Ordem: ${b.sortOrder}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TrendBoardAdminScreen(boardId: b.id),
                      ),
                    );
                  },
                  onLongPress: () async {
                    final del = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Apagar pasta'),
                        content: Text('Apagar “${b.title}” e todo o conteúdo?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Apagar'),
                          ),
                        ],
                      ),
                    );
                    if (del != true || !context.mounted) return;
                    try {
                      await TrendsService.instance.deleteBoard(b.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pasta apagada')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Edição de uma pasta: título, mood 1080×1080, cards de produto com link.
class TrendBoardAdminScreen extends StatefulWidget {
  final String boardId;

  const TrendBoardAdminScreen({super.key, required this.boardId});

  @override
  State<TrendBoardAdminScreen> createState() => _TrendBoardAdminScreenState();
}

class _TrendBoardAdminScreenState extends State<TrendBoardAdminScreen> {
  final _titleCtrl = TextEditingController();
  final _sortCtrl = TextEditingController();
  Future<TrendBoardContent>? _future;
  bool _busy = false;
  bool _seededFields = false;

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await TrendsService.instance.isCurrentUserAdmin();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sem permissão de admin Trends'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = TrendsService.instance.fetchBoardContent(widget.boardId);
    });
  }

  Future<void> _saveTitle(TrendBoard board) async {
    final t = _titleCtrl.text.trim();
    final so = int.tryParse(_sortCtrl.text.trim());
    setState(() => _busy = true);
    try {
      await TrendsService.instance.updateBoardMeta(
        widget.boardId,
        title: t.isEmpty ? board.title : t,
        sortOrder: so,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado')),
        );
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addMood() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final raw = await picked.readAsBytes();
      final jpeg = TrendsService.instance.prepareSquareJpeg(raw, size: 1080);
      final url = await TrendsService.instance.uploadMoodImage(widget.boardId, jpeg);
      await TrendsService.instance.addMoodImage(widget.boardId, url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem mood adicionada (1080×1080)')),
        );
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editProduct(TrendManualProduct? existing) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final priceCtrl = TextEditingController(text: existing?.priceDisplay ?? '');
    final linkCtrl = TextEditingController(text: existing?.linkUrl ?? '');
    String? imageUrl = existing?.imageUrl;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(existing == null ? 'Novo produto' : 'Editar produto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Preço (texto livre)',
                      hintText: 'ex: R\$ 199',
                    ),
                  ),
                  TextField(
                    controller: linkCtrl,
                    decoration: const InputDecoration(labelText: 'Link do produto'),
                  ),
                  const SizedBox(height: 12),
                  if ((imageUrl ?? '').isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(imageUrl!, height: 100, fit: BoxFit.cover),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 90,
                      );
                      if (picked == null) return;
                      setLocal(() {});
                      try {
                        final bytes = await picked.readAsBytes();
                        final jpeg =
                            TrendsService.instance.prepareSquareJpeg(bytes, size: 1080);
                        imageUrl = await TrendsService.instance
                            .uploadProductCardImage(widget.boardId, jpeg);
                        setLocal(() {});
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.photo_outlined),
                    label: Text((imageUrl ?? '').isEmpty
                        ? 'Carregar imagem'
                        : 'Trocar imagem'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );

    void disposeCtrls() {
      titleCtrl.dispose();
      priceCtrl.dispose();
      linkCtrl.dispose();
    }

    if (ok != true || !mounted) {
      disposeCtrls();
      return;
    }
    final urlFinal = imageUrl?.trim() ?? '';
    if (urlFinal.isEmpty) {
      disposeCtrls();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adicione uma imagem ao card')),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await TrendsService.instance.addOrUpdateProduct(
        boardId: widget.boardId,
        productId: existing?.id,
        title: titleCtrl.text,
        priceDisplay: priceCtrl.text,
        imageUrl: urlFinal,
        linkUrl: linkCtrl.text,
      );
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      disposeCtrls();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar pasta Trends'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6B2C5C),
        elevation: 0,
      ),
      body: Stack(
        children: [
          FutureBuilder<TrendBoardContent>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final c = snap.data!;
              if (!_seededFields) {
                _titleCtrl.text = c.board.title;
                _sortCtrl.text = '${c.board.sortOrder}';
                _seededFields = true;
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome da pasta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sortCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ordem (número)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _saveTitle(c.board),
                    child: const Text('Guardar pasta'),
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mood board (1080×1080)',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xFF6B2C5C),
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _busy ? null : _addMood,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (c.moods.isEmpty)
                    const Text(
                      'Sem imagens. Toque em + para enviar (recortadas a quadrado 1080 px).',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: c.moods.map((m) {
                        return Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: m.imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      await TrendsService.instance
                                          .deleteMoodImage(widget.boardId, m.id);
                                      _reload();
                                    },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Cards de produto',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Color(0xFF6B2C5C),
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _busy ? null : () => _editProduct(null),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  ...c.products.map((p) {
                    return Card(
                      child: ListTile(
                        leading: CachedNetworkImage(
                          imageUrl: p.imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                        title: Text(p.title),
                        subtitle: Text(p.linkUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: _busy ? null : () => _editProduct(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Apagar card'),
                                          content: Text('Remover “${p.title}”?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              child: const Text('Apagar'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok != true) return;
                                      await TrendsService.instance
                                          .deleteProduct(widget.boardId, p.id);
                                      _reload();
                                    },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          if (_busy)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
