import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../utils/debug_helper.dart';

class ScrapingService {
  static final ScrapingService _instance = ScrapingService._internal();
  factory ScrapingService() => _instance;
  ScrapingService._internal();

  // URL da API Gimie 2.0 no Vercel
  static const String _scrapingApiUrl = 'https://api2gimie.vercel.app';
  
  // Endpoints da API Gimie 2.0
  static const String _scrapeEndpoint = '/api/products';
  static const String _extractEndpoint = '/api/products/extract';
  static const String _healthEndpoint = '/health';
  
  // Timeout para requisições
  static const Duration _timeout = Duration(seconds: 60);
  
  /// Headers padrão para requisições
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'Gimie-App/1.0',
  };

  /// Verifica se a API de scraping está funcionando
  Future<bool> checkHealth() async {
    try {
      DebugHelper.log('Checking scraping API health', 'SCRAPING');
      
      final response = await http.get(
        Uri.parse('$_scrapingApiUrl$_healthEndpoint'),
        headers: _headers,
      ).timeout(_timeout);

      final isHealthy = response.statusCode == 200;
      DebugHelper.log('API health status: $isHealthy', 'SCRAPING');
      
      return isHealthy;
    } catch (e) {
      DebugHelper.logError('Health check failed', e);
      return false;
    }
  }

  /// Faz scraping de dados de produto a partir de uma URL
  Future<ScrapedProductData?> scrapeProductFromUrl(String url) async {
    try {
      DebugHelper.log('Scraping product from URL: $url', 'SCRAPING');
      
      if (!_isValidUrl(url)) {
        throw Exception('URL inválida fornecida');
      }

      final response = await http.post(
        Uri.parse('$_scrapingApiUrl$_scrapeEndpoint'),
        headers: _headers,
        body: jsonEncode({
          'url': url,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // A nova API retorna um objeto com success e data
        if (responseData['success'] == true && responseData['data'] != null) {
          final productData = responseData['data'];
          final scrapedData = ScrapedProductData.fromGimieApi(productData);
          
          DebugHelper.log('Successfully scraped product: ${scrapedData.title}', 'SCRAPING');
          return scrapedData;
        } else {
          throw Exception('Resposta inválida da API: ${responseData['message'] ?? 'Dados não encontrados'}');
        }
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception('Erro de validação: ${error['message'] ?? 'URL inválida'}');
      } else if (response.statusCode == 404) {
        throw Exception('Produto não encontrado na URL fornecida');
      } else if (response.statusCode == 429) {
        throw Exception('Muitas requisições. Tente novamente em alguns minutos');
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Erro no servidor: ${error['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      DebugHelper.logError('Scraping failed for URL: $url', e);
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Timeout: A página demorou muito para responder');
      }
      rethrow;
    }
  }

  /// Extrai dados específicos de uma página web
  Future<Map<String, dynamic>?> extractDataFromUrl({
    required String url,
    List<String>? selectors,
    bool extractMetadata = true,
  }) async {
    try {
      DebugHelper.log('Extracting data from URL: $url', 'SCRAPING');

      final body = <String, dynamic>{
        'url': url,
        'extractMetadata': extractMetadata,
      };

      if (selectors != null && selectors.isNotEmpty) {
        body['selectors'] = selectors;
      }

      final response = await http.post(
        Uri.parse('$_scrapingApiUrl$_extractEndpoint'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        DebugHelper.log('Successfully extracted data', 'SCRAPING');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Erro na extração: ${error['message'] ?? 'Erro desconhecido'}');
      }
    } catch (e) {
      DebugHelper.logError('Data extraction failed for URL: $url', e);
      rethrow;
    }
  }

  /// Faz scraping em lote de múltiplas URLs
  Future<List<ScrapedProductData>> scrapeBatchUrls(List<String> urls) async {
    try {
      DebugHelper.log('Scraping batch of ${urls.length} URLs', 'SCRAPING');
      
      final results = <ScrapedProductData>[];
      
      // Processa URLs em lotes para evitar sobrecarga
      const batchSize = 5;
      for (int i = 0; i < urls.length; i += batchSize) {
        final batch = urls.skip(i).take(batchSize).toList();
        final batchResults = await Future.wait(
          batch.map((url) => scrapeProductFromUrl(url).catchError((e) {
            DebugHelper.logError('Failed to scrape URL in batch: $url', e);
            return null;
          })),
        );
        
        results.addAll(batchResults.where((result) => result != null).cast<ScrapedProductData>());
        
        // Pequena pausa entre lotes para não sobrecarregar o servidor
        if (i + batchSize < urls.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      DebugHelper.log('Batch scraping completed: ${results.length} successful', 'SCRAPING');
      return results;
    } catch (e) {
      DebugHelper.logError('Batch scraping failed', e);
      rethrow;
    }
  }

  /// Converte dados scraped para modelo de produto do app
  Product convertScrapedDataToProduct({
    required ScrapedProductData scrapedData,
    required String userId,
    String? category,
  }) {
    return Product(
      id: '', // Será gerado pelo Firebase
      name: scrapedData.title ?? 'Produto sem nome',
      description: scrapedData.description ?? 'Sem descrição',
      price: scrapedData.price ?? 0.0,
      imageUrl: scrapedData.imageUrl ?? '',
      url: scrapedData.sourceUrl,
      userId: userId,
      category: category ?? _inferCategoryFromData(scrapedData),
      likes: 0,
      likedBy: [],
      createdAt: DateTime.now(),
    );
  }

  /// Infere categoria baseada nos dados do produto
  String _inferCategoryFromData(ScrapedProductData data) {
    final title = data.title?.toLowerCase() ?? '';
    final description = data.description?.toLowerCase() ?? '';
    final content = '$title $description';

    if (content.contains('eletrônico') || content.contains('smartphone') || content.contains('laptop')) {
      return 'Eletrônicos';
    } else if (content.contains('roupa') || content.contains('camisa') || content.contains('calça')) {
      return 'Moda';
    } else if (content.contains('casa') || content.contains('decoração') || content.contains('móvel')) {
      return 'Casa';
    } else if (content.contains('beleza') || content.contains('cosmético') || content.contains('perfume')) {
      return 'Beleza';
    } else if (content.contains('esporte') || content.contains('fitness') || content.contains('academia')) {
      return 'Esportes';
    } else if (content.contains('livro') || content.contains('literatura') || content.contains('educação')) {
      return 'Livros';
    }
    
    return 'Outros';
  }

  /// Valida se uma URL é válida
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Obtém sugestões de produtos baseado em uma categoria
  Future<List<ScrapedProductData>> getProductSuggestions(String category) async {
    try {
      DebugHelper.log('Getting product suggestions for category: $category', 'SCRAPING');
      
      final response = await http.get(
        Uri.parse('$_scrapingApiUrl/api/suggestions?category=${Uri.encodeComponent(category)}'),
        headers: _headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> suggestions = data['suggestions'] ?? [];
        
        return suggestions
            .map((json) => ScrapedProductData.fromJson(json))
            .toList();
      } else {
        DebugHelper.log('No suggestions available for category: $category', 'SCRAPING');
        return [];
      }
    } catch (e) {
      DebugHelper.logError('Failed to get suggestions for category: $category', e);
      return [];
    }
  }

  /// Limpa cache do serviço de scraping
  Future<bool> clearCache() async {
    try {
      final response = await http.delete(
        Uri.parse('$_scrapingApiUrl/api/cache'),
        headers: _headers,
      ).timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      DebugHelper.logError('Failed to clear cache', e);
      return false;
    }
  }
}

/// Modelo para dados de produto extraídos via scraping
class ScrapedProductData {
  final String? title;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String sourceUrl;
  final List<String>? additionalImages;
  final Map<String, dynamic>? metadata;
  final DateTime scrapedAt;

  ScrapedProductData({
    this.title,
    this.description,
    this.price,
    this.imageUrl,
    required this.sourceUrl,
    this.additionalImages,
    this.metadata,
    required this.scrapedAt,
  });

  factory ScrapedProductData.fromJson(Map<String, dynamic> json) {
    return ScrapedProductData(
      title: json['title'] as String?,
      description: json['description'] as String?,
      price: _parsePrice(json['price']),
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      sourceUrl: json['sourceUrl'] as String? ?? json['url'] as String? ?? '',
      additionalImages: (json['additionalImages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      scrapedAt: DateTime.tryParse(json['scrapedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Factory constructor para dados da Gimie API 2.0
  factory ScrapedProductData.fromGimieApi(Map<String, dynamic> json) {
    return ScrapedProductData(
      title: json['name'] as String? ?? json['title'] as String?,
      description: json['description'] as String?,
      price: _parsePrice(json['price'] ?? json['originalPrice']),
      imageUrl: json['image'] as String? ?? json['imageUrl'] as String?,
      sourceUrl: json['url'] as String? ?? json['sourceUrl'] as String? ?? '',
      additionalImages: (json['images'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      metadata: {
        'currency': json['currency'],
        'originalPrice': json['originalPrice'],
        'convertedPrice': json['convertedPrice'],
        'domain': json['domain'],
        'site': json['site'],
        'id': json['id'],
        ...?json['metadata'] as Map<String, dynamic>?,
      },
      scrapedAt: DateTime.tryParse(json['createdAt'] as String? ?? json['scrapedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'sourceUrl': sourceUrl,
      'additionalImages': additionalImages,
      'metadata': metadata,
      'scrapedAt': scrapedAt.toIso8601String(),
    };
  }

  static double? _parsePrice(dynamic price) {
    if (price == null) return null;
    
    if (price is num) {
      return price.toDouble();
    }
    
    if (price is String) {
      // Remove símbolos de moeda e espaços
      final cleanPrice = price
          .replaceAll(RegExp(r'[^\d.,]'), '')
          .replaceAll(',', '.');
      
      return double.tryParse(cleanPrice);
    }
    
    return null;
  }

  bool get hasValidData {
    return title != null && title!.isNotEmpty && sourceUrl.isNotEmpty;
  }
}