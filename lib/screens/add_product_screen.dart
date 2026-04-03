import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../services/share_service.dart';
import '../services/api_service.dart';
import '../services/scraping_service.dart';
import '../utils/debug_helper.dart';
import '../widgets/product_suggestions_widget.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();
  
  File? _imageFile;
  Uint8List? _sharedImageBytes;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isScrapingUrl = false;
  bool _showScrapingPreview = false;
  String? _selectedCategory;
  ScrapedProductData? _scrapedData;

  final List<String> _categories = [
    'Eletrônicos',
    'Moda',
    'Casa',
    'Beleza',
    'Esportes',
    'Livros',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _checkForSharedContent();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkForSharedContent() async {
    try {
      final sharedContent = await ShareService.instance.getSharedContent();
      
      if (sharedContent != null && mounted) {
        setState(() {
          if (sharedContent['text'] != null) {
            final text = sharedContent['text'] as String;
            if (text.trim().isNotEmpty) {
              _descriptionController.text = text;
            }
          }
          
          if (sharedContent['url'] != null) {
            final url = sharedContent['url'] as String;
            if (url.trim().isNotEmpty) {
              _urlController.text = url;
            }
          }
          
          if (sharedContent['imageBytes'] != null) {
            _sharedImageBytes = sharedContent['imageBytes'] as Uint8List;
          }
        });
        
        // Limpa o conteúdo compartilhado após usar
        await ShareService.instance.clearSharedContent();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conteúdo compartilhado carregado!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      DebugHelper.logError('Erro ao verificar conteúdo compartilhado', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar conteúdo compartilhado'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _sharedImageBytes = null; // Limpa imagem compartilhada se uma nova for selecionada
          _imageUrl = null; // Reset URL para forçar novo upload
        });
      }
    } catch (e) {
      DebugHelper.logError('Erro ao selecionar imagem', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null && _sharedImageBytes == null) return;

    if (!mounted) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null || userId.isEmpty) {
        throw Exception('Usuário não está logado');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'products/$userId/$timestamp.jpg';
      String url;
      
      if (_imageFile != null) {
        url = await FirebaseService().uploadImage(_imageFile!, path);
      } else if (_sharedImageBytes != null) {
        url = await FirebaseService().uploadImageFromBytes(_sharedImageBytes!, path);
      } else {
        throw Exception('Nenhuma imagem para fazer upload');
      }
      
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      DebugHelper.logError('Erro no upload da imagem', e);
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer upload da imagem: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    try {
      // Upload da imagem se necessário
      if ((_imageFile != null || _sharedImageBytes != null) && _imageUrl == null) {
        await _uploadImage();
        if (_imageUrl == null) return;
      }

      // Se não há imagem local mas há dados scraped com imagem, usa a imagem scraped
      if (_imageUrl == null) {
        final scrapedImageUrl = _scrapedData?.imageUrl;
        if (scrapedImageUrl != null && scrapedImageUrl.isNotEmpty) {
          _imageUrl = scrapedImageUrl;
        }
      }

      if (_imageUrl == null || _imageUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, adicione uma imagem ou use uma URL com imagem'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário não está logado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validação adicional dos campos
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final priceText = _priceController.text.trim();
      final url = _urlController.text.trim();

      if (name.isEmpty || description.isEmpty || priceText.isEmpty || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, preencha todos os campos'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final price = double.tryParse(priceText);
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, insira um preço válido'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.addProduct(
        name: name,
        description: description,
        price: price,
        imageUrl: _imageUrl!,
        url: url,
        userId: userId,
        category: _selectedCategory,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto adicionado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao adicionar produto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      DebugHelper.logError('Erro ao adicionar produto', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar produto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Faz scraping de dados da URL inserida
  Future<void> _scrapeUrlData() async {
    final url = _urlController.text.trim();
    
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira uma URL primeiro'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isScrapingUrl = true;
      _scrapedData = null;
      _showScrapingPreview = false;
    });

    try {
      DebugHelper.log('Starting URL scraping for: $url', 'ADD_PRODUCT');
      
      final apiService = ApiService();
      final scrapedData = await apiService.previewProductFromUrl(url);

      if (!mounted) return;

      if (scrapedData != null && scrapedData.hasValidData) {
        setState(() {
          _scrapedData = scrapedData;
          _showScrapingPreview = true;
          
          // Preenche campos automaticamente se estiverem vazios
          if (_nameController.text.trim().isEmpty && scrapedData.title != null) {
            _nameController.text = scrapedData.title!;
          }
          
          if (_descriptionController.text.trim().isEmpty && scrapedData.description != null) {
            _descriptionController.text = scrapedData.description!;
          }
          
          if (_priceController.text.trim().isEmpty && scrapedData.price != null) {
            _priceController.text = scrapedData.price!.toStringAsFixed(2);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados extraídos com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível extrair dados desta URL'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      DebugHelper.logError('URL scraping failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao extrair dados: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScrapingUrl = false;
        });
      }
    }
  }

  /// Aplica dados scraped aos campos do formulário
  void _applyScrapedData() {
    final scrapedData = _scrapedData;
    if (scrapedData == null) return;

    setState(() {
      final title = scrapedData.title;
      if (title != null && title.isNotEmpty) {
        _nameController.text = title;
      }
      
      final description = scrapedData.description;
      if (description != null && description.isNotEmpty) {
        _descriptionController.text = description;
      }
      
      final price = scrapedData.price;
      if (price != null && price > 0) {
        _priceController.text = price.toStringAsFixed(2);
      }
      
      // Limpa imagem local se houver uma imagem scraped
      final imageUrl = scrapedData.imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        _imageFile = null;
        _sharedImageBytes = null;
        _imageUrl = imageUrl;
      }
      
      _showScrapingPreview = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados aplicados ao formulário!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Descarta dados scraped
  void _discardScrapedData() {
    setState(() {
      _scrapedData = null;
      _showScrapingPreview = false;
    });
  }

  /// Aplica dados de produto sugerido aos campos
  void _applySuggestedProduct(Product product) {
    setState(() {
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toStringAsFixed(2);
      _urlController.text = product.url;
      _selectedCategory = product.category;
      
      // Se há imagem, usa ela
      if (product.imageUrl.isNotEmpty) {
        _imageFile = null;
        _sharedImageBytes = null;
        _imageUrl = product.imageUrl;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Produto "${product.name}" aplicado ao formulário!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Desfazer',
          textColor: Colors.white,
          onPressed: _clearForm,
        ),
      ),
    );
  }

  /// Limpa todos os campos do formulário
  void _clearForm() {
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _urlController.clear();
      _selectedCategory = null;
      _imageFile = null;
      _sharedImageBytes = null;
      _imageUrl = null;
      _scrapedData = null;
      _showScrapingPreview = false;
    });
  }

  DecorationImage? _getImageDecoration() {
    if (_imageFile != null) {
      return DecorationImage(
        image: FileImage(_imageFile!),
        fit: BoxFit.cover,
      );
    } else if (_sharedImageBytes != null) {
      return DecorationImage(
        image: MemoryImage(_sharedImageBytes!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adicionar Produto',
          style: TextStyle(color: Color(0xFF6B2C5C)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF6B2C5C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _getImageDecoration(),
                  ),
                  child: _imageFile == null && _sharedImageBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Adicionar Imagem', style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do produto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Preço',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o preço';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor, insira um preço válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL do Produto',
                        prefixIcon: Icon(Icons.link),
                        hintText: 'Cole aqui o link do produto',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a URL';
                        }
                        if (!value.startsWith('http')) {
                          return 'Por favor, insira uma URL válida';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Limpa preview quando URL muda
                        if (_showScrapingPreview) {
                          setState(() {
                            _showScrapingPreview = false;
                            _scrapedData = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isScrapingUrl ? null : _scrapeUrlData,
                    icon: _isScrapingUrl
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    tooltip: 'Extrair dados automaticamente',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Preview dos dados scraped
              if (_showScrapingPreview && _scrapedData != null) ...[
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dados extraídos automaticamente',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _discardScrapedData,
                              icon: const Icon(Icons.close),
                              iconSize: 20,
                              tooltip: 'Descartar',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_scrapedData?.title != null) ...[
                          Text(
                            'Nome: ${_scrapedData!.title}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (_scrapedData?.price != null) ...[
                          Text(
                            'Preço: R\$ ${_scrapedData!.price!.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (_scrapedData?.description != null) ...[
                          Text(
                            'Descrição: ${_scrapedData!.description!.length > 100 ? '${_scrapedData!.description!.substring(0, 100)}...' : _scrapedData!.description}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_scrapedData?.imageUrl != null && _scrapedData!.imageUrl!.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _scrapedData!.imageUrl!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  width: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _applyScrapedData,
                            icon: const Icon(Icons.check),
                            label: const Text('Usar estes dados'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Widget de sugestões
              if (_selectedCategory != null)
                ProductSuggestionsWidget(
                  category: _selectedCategory!,
                  onProductSelected: _applySuggestedProduct,
                ),
              
              const SizedBox(height: 32),
              Consumer<ProductProvider>(
                builder: (context, provider, _) {
                  return ElevatedButton(
                    onPressed: provider.isLoading || _isUploading
                        ? null
                        : _handleSubmit,
                    child: provider.isLoading || _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Adicionar Produto'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
