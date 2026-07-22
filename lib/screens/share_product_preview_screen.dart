import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';
import '../services/scraping_service.dart';
import '../services/share_service.dart';
import '../utils/debug_helper.dart';

/// Pré-visualização dedicada ao fluxo "Compartilhar com a Gimie".
/// Ao escolher a pasta, salva automaticamente, fecha e devolve o usuário
/// à tela anterior.
class ShareProductPreviewScreen extends StatefulWidget {
  final String? initialUrl;

  const ShareProductPreviewScreen({
    super.key,
    this.initialUrl,
  });

  @override
  State<ShareProductPreviewScreen> createState() =>
      _ShareProductPreviewScreenState();
}

class _ShareProductPreviewScreenState extends State<ShareProductPreviewScreen> {
  final _newCategoryController = TextEditingController();

  bool _isLoadingContent = true;
  bool _isScrapingUrl = false;
  bool _isSaving = false;
  String? _productUrl;
  String? _selectedCategory;
  ScrapedProductData? _scrapedData;
  final List<String> _categories = [];

  static const String _fallbackImageUrl =
      'https://via.placeholder.com/600x600.png?text=Gimie';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bootstrap();
      }
    });
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _loadSharedContent(),
      _loadFolders(),
    ]);
    if (!mounted) return;
    setState(() => _isLoadingContent = false);
  }

  Future<void> _loadSharedContent() async {
    try {
      String? url = widget.initialUrl?.trim();

      // Se já recebeu URL via initialUrl, não precisa buscar novamente
      if (url == null || url.isEmpty) {
        final sharedContent = await ShareService.instance.getSharedContent();
        if (sharedContent != null) {
          url = (sharedContent['url'] as String?)?.trim();
          final text = (sharedContent['text'] as String?)?.trim();

          if ((url == null || url.isEmpty) && text != null && text.isNotEmpty) {
            final match = RegExp(
              r'https?:\/\/[^\s]+',
              caseSensitive: false,
            ).firstMatch(text);
            url = match?.group(0);
          }
          // Limpa apenas se leu do shared content (não via initialUrl)
          await ShareService.instance.clearSharedContent();
        }
      }

      if (url == null || url.isEmpty || !mounted) return;

      final normalizedUrl = _normalizeProductUrl(url);
      setState(() {
        _productUrl = normalizedUrl;
        _scrapedData = ScrapedProductData(
          title: _buildFallbackNameFromUrl(normalizedUrl),
          description: 'Produto adicionado via link.',
          price: null,
          priceDisplay: 'Preço indisponível',
          imageUrl: _fallbackImageUrl,
          sourceUrl: normalizedUrl,
          scrapedAt: DateTime.now(),
        );
      });

      await _scrapeUrlData(normalizedUrl);
    } catch (e) {
      DebugHelper.logError('Erro ao carregar conteúdo compartilhado', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar conteúdo compartilhado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadFolders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final userId = authProvider.resolvedUserId;
    if (userId == null || userId.isEmpty) return;

    await productProvider.loadUserProducts(userId);
    if (!mounted) return;

    final fromProducts = productProvider.userProducts
        .map((p) => (p.category ?? '').trim())
        .where((c) => c.isNotEmpty)
        .toSet();

    final fromEmpty = authProvider.currentUser?.emptyFolders
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet() ??
        <String>{};

    final categories = {...fromProducts, ...fromEmpty}.toList()..sort();

    setState(() {
      _categories
        ..clear()
        ..addAll(categories);
    });
  }

  Future<void> _scrapeUrlData(String url) async {
    if (!mounted) return;
    setState(() => _isScrapingUrl = true);

    try {
      final scrapedData = await ApiService().previewProductFromUrl(url);
      if (!mounted || scrapedData == null) return;

      setState(() {
        _scrapedData = _sanitizeScrapedData(scrapedData, url);
      });
    } catch (e) {
      DebugHelper.logError('URL scraping failed on share preview', e);
    } finally {
      if (mounted) {
        setState(() => _isScrapingUrl = false);
      }
    }
  }

  void _addCategory() {
    final category = _newCategoryController.text.trim();
    if (category.isEmpty) return;
    _newCategoryController.clear();
    unawaited(_selectFolderAndClose(category));
  }

  void _onFolderSelected(String? value) {
    if (value == null || value.trim().isEmpty) return;
    unawaited(_selectFolderAndClose(value.trim()));
  }

  /// Escolhe a pasta, salva o produto e fecha a pré-visualização.
  Future<void> _selectFolderAndClose(String category) async {
    if (_isSaving) return;

    final folder = category.trim();
    if (folder.isEmpty) return;

    setState(() {
      if (!_categories.any((c) => c.toLowerCase() == folder.toLowerCase())) {
        _categories.insert(0, folder);
      }
      _selectedCategory = folder;
      _isSaving = true;
    });

    try {
      final success = await _persistProduct(folder);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seu produto foi salvo'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Fecha a pré-visualização assim que a pasta foi escolhida e o save concluiu.
        Navigator.of(context, rootNavigator: true).pop(true);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Provider.of<ProductProvider>(context, listen: false).errorMessage ??
                'Erro ao adicionar produto',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      DebugHelper.logError('Erro ao salvar produto compartilhado', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar produto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _persistProduct(String category) async {
    final url = _productUrl?.trim() ?? '';
    if (url.isEmpty) return false;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.resolvedUserId;
    if (userId == null || userId.isEmpty) return false;

    final scraped = _scrapedData;
    final finalName = (scraped?.title?.trim().isNotEmpty ?? false)
        ? scraped!.title!.trim()
        : _buildFallbackNameFromUrl(url);
    final finalPrice = scraped?.price ?? 0.0;
    var finalPriceDisplay = scraped?.priceDisplay?.trim();
    final finalImage = (scraped?.imageUrl?.trim().isNotEmpty ?? false)
        ? scraped!.imageUrl!.trim()
        : _fallbackImageUrl;
    final safeDescription = (scraped?.description?.trim().isNotEmpty == true)
        ? scraped!.description!.trim()
        : 'Produto adicionado via link.';

    if (finalPrice <= 0 &&
        (finalPriceDisplay == null || finalPriceDisplay.isEmpty)) {
      finalPriceDisplay = 'Preço indisponível';
    }

    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    return productProvider.addProduct(
      name: finalName,
      description: safeDescription,
      price: finalPrice,
      priceDisplay: finalPriceDisplay,
      imageUrl: finalImage,
      url: url,
      userId: userId,
      category: category,
    );
  }

  Future<void> _saveProduct() async {
    final typedCategory = _newCategoryController.text.trim();
    final folder = typedCategory.isNotEmpty
        ? typedCategory
        : (_selectedCategory?.trim() ?? '');

    if (folder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crie ou selecione uma pasta para salvar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _newCategoryController.clear();
    await _selectFolderAndClose(folder);
  }

  Future<void> _openProductLink() async {
    final targetUrl = _scrapedData?.sourceUrl.trim().isNotEmpty == true
        ? _scrapedData!.sourceUrl
        : (_productUrl ?? '');
    final uri = _buildProductUri(targetUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link do produto indisponível')),
      );
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return;
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir este link')),
        );
      }
    }
  }

  void _closePreview() {
    Navigator.of(context).pop(false);
  }

  Uri? _buildProductUri(String rawUrl) {
    final raw = rawUrl.trim();
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAll(' ', '%20');
    final parsed = Uri.tryParse(normalized);
    if (parsed != null && parsed.hasScheme) return parsed;
    return Uri.tryParse('https://$normalized');
  }

  String _normalizeProductUrl(String rawUrl) {
    var normalized = rawUrl.trim();
    if (normalized.isEmpty) return normalized;
    if (!normalized.startsWith(RegExp(r'https?://', caseSensitive: false))) {
      normalized = 'https://$normalized';
    }
    normalized = normalized.replaceAll('+', '%20');
    try {
      final decoded = Uri.decodeFull(normalized);
      return Uri.encodeFull(decoded).replaceAll('+', '%20');
    } catch (_) {
      return normalized.replaceAll(' ', '%20');
    }
  }

  ScrapedProductData _sanitizeScrapedData(
    ScrapedProductData data,
    String normalizedUrl,
  ) {
    final cleanedTitle =
        _isLikelyGenericTitle(data.title) ? null : data.title?.trim();
    final cleanedImage =
        _isValidHttpUrl(data.imageUrl) ? data.imageUrl?.trim() : null;
    final cleanedPrice =
        (data.price != null && data.price! > 0) ? data.price : null;
    final cleanedPriceDisplay =
        (data.priceDisplay != null && data.priceDisplay!.trim().isNotEmpty)
            ? data.priceDisplay!.trim()
            : null;

    return ScrapedProductData(
      title: cleanedTitle ?? _buildFallbackNameFromUrl(normalizedUrl),
      description: data.description?.trim(),
      price: cleanedPrice,
      priceDisplay: cleanedPriceDisplay,
      imageUrl: cleanedImage ?? _fallbackImageUrl,
      sourceUrl: normalizedUrl,
      additionalImages: data.additionalImages,
      metadata: data.metadata,
      scrapedAt: data.scrapedAt,
    );
  }

  bool _isLikelyGenericTitle(String? title) {
    final value = title?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return true;
    const genericMarkers = [
      'resultado da busca',
      'resultados da busca',
      'search result',
      'search results',
      'buscar',
      'pesquisa',
      'catálogo',
      'catalogo',
      'coleção',
      'colecao',
      'home',
      'início',
      'inicio',
    ];
    if (value.contains('%20') || value.contains('%2520')) return true;
    return genericMarkers.any(value.contains);
  }

  bool _isValidHttpUrl(String? value) {
    var raw = value?.trim();
    if (raw == null || raw.isEmpty) return false;
    if (raw.startsWith('//')) raw = 'https:$raw';
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  String _buildFallbackNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final slug = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      final cleaned = slug
          .replaceAll(RegExp(r'\.html?$'), '')
          .replaceAll(RegExp(r'[-_]+'), ' ')
          .replaceAll(RegExp(r'%20'), ' ')
          .trim();
      if (cleaned.isNotEmpty) {
        final words = cleaned
            .split(' ')
            .where((word) => word.trim().isNotEmpty)
            .map(
              (word) => word.length > 1
                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                  : word.toUpperCase(),
            )
            .toList();
        if (words.isNotEmpty) return words.join(' ');
      }
      return uri.host.replaceFirst('www.', '').trim();
    } catch (_) {
      return 'Produto sem nome';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F8),
      appBar: AppBar(
        title: const Text(
          'Pré-visualização',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B2C5C),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF6B2C5C)),
          onPressed: _isSaving ? null : _closePreview,
        ),
      ),
      body: _isLoadingContent
          ? const Center(child: CircularProgressIndicator())
          : (_productUrl == null
              ? _buildEmptyState()
              : _buildPreviewBody()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Nenhum link compartilhado encontrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF6B2C5C),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _closePreview,
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewBody() {
    final scraped = _scrapedData;
    final title = scraped?.title?.trim().isNotEmpty == true
        ? scraped!.title!.trim()
        : 'Produto sem nome';
    final priceLabel = (scraped?.priceDisplay?.trim().isNotEmpty ?? false)
        ? scraped!.priceDisplay!.trim()
        : (scraped?.price != null
            ? 'R\$ ${scraped!.price!.toStringAsFixed(2)}'
            : 'Preço indisponível');
    final imageUrl = scraped?.imageUrl?.trim().isNotEmpty == true
        ? scraped!.imageUrl!.trim()
        : _fallbackImageUrl;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Confira o produto antes de salvar na sua pasta.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isScrapingUrl)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF191919),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              priceLabel,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                color: Color(0xFF8B7FB8),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openProductLink,
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: const Text('Shop Now'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6B2C5C),
                                  side: const BorderSide(
                                    color: Color(0xFF8B7FB8),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Salvar em',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF6B2C5C),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ao escolher ou criar uma pasta, o produto é salvo e esta tela fecha.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newCategoryController,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    labelText: 'Nova pasta',
                    prefixIcon: const Icon(Icons.create_new_folder_outlined),
                    hintText: 'Ex: Looks de verão',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      tooltip: 'Criar e salvar',
                      onPressed: _isSaving ? null : _addCategory,
                      icon: const Icon(Icons.check),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCategory(),
                ),
                const SizedBox(height: 12),
                IgnorePointer(
                  ignoring: _isSaving,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('folder-${_categories.length}-$_selectedCategory'),
                    initialValue: _categories.contains(_selectedCategory)
                        ? _selectedCategory
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Pasta existente',
                      prefixIcon: Icon(Icons.folder_outlined),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    hint: Text(
                      _categories.isEmpty
                          ? 'Crie sua primeira pasta'
                          : 'Selecione uma pasta',
                    ),
                    onChanged: _onFolderSelected,
                  ),
                ),
                if (_isSaving) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Salvando e fechando…',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _closePreview,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B2C5C),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B2C5C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Salvar produto',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
