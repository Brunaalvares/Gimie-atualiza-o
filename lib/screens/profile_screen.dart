import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../services/firebase_service.dart';
import '../utils/profile_folder_layout.dart';
import 'follow_users_screen.dart';
import 'follow_list_screen.dart';
import 'folder_products_screen.dart';
import 'login_screen.dart';
import '../providers/badges_provider.dart';
import '../widgets/badges_panel.dart';
import '../widgets/profile_metrics_panel.dart';
import '../widgets/profile_notifications_panel.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _bioController = TextEditingController();
  final FocusNode _bioFocusNode = FocusNode();
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isLoadingFollowStats = true;
  bool _isUploadingPhoto = false;
  bool _isSavingBio = false;
  bool _isEditingBio = false;
  String? _loadedProductsForUserId;
  String? _loadedFollowStatsForUserId;
  String? _badgesBoundForUserId;
  String _lastSyncedBio = '';
  StreamSubscription<int>? _followersSub;
  StreamSubscription<int>? _followingSub;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadUserProductsIfNeeded();
      _loadFollowStatsIfNeeded();
    });
  }

  @override
  void dispose() {
    _followersSub?.cancel();
    _followingSub?.cancel();
    _bioController.dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }

  void _loadUserProductsIfNeeded() {
    final userId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).resolvedUserId;
    if (userId != null) {
      if (_loadedProductsForUserId == userId) return;
      _loadedProductsForUserId = userId;
      Provider.of<ProductProvider>(context, listen: false)
          .loadUserProducts(userId);
    }
  }

  void _loadFollowStatsIfNeeded() {
    final userId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).resolvedUserId;
    if (userId == null || _loadedFollowStatsForUserId == userId) return;
    _loadedFollowStatsForUserId = userId;
    _listenFollowStats(userId);
    _loadFollowStats();
  }

  void _listenFollowStats(String userId) {
    _followersSub?.cancel();
    _followingSub?.cancel();

    _followersSub =
        _firebaseService.getFollowersCountStream(userId).listen((value) {
      if (!mounted) return;
      setState(() {
        _followersCount = value;
        _isLoadingFollowStats = false;
      });
    });

    _followingSub =
        _firebaseService.getFollowingCountStream(userId).listen((value) {
      if (!mounted) return;
      setState(() {
        _followingCount = value;
        _isLoadingFollowStats = false;
      });
    });
  }

  Future<void> _loadFollowStats() async {
    final userId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).resolvedUserId;
    if (userId == null) return;

    setState(() {
      _isLoadingFollowStats = true;
    });

    try {
      final followers = await _firebaseService.getFollowersCount(userId);
      final following = await _firebaseService.getFollowingCount(userId);

      if (!mounted) return;
      setState(() {
        _followersCount = followers;
        _followingCount = following;
        _isLoadingFollowStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingFollowStats = false;
      });
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final path =
          'profiles/${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await picked.readAsBytes();
      final photoUrl = await _firebaseService.uploadImageFromBytes(bytes, path);
      await authProvider.updateProfile(photoUrl: photoUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil atualizada!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar a foto'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _saveBio() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bio = _bioController.text.trim();
    if (_isSavingBio) return;
    if (bio == (authProvider.currentUser?.bio?.trim() ?? '')) {
      setState(() {
        _isEditingBio = false;
      });
      return;
    }

    setState(() {
      _isSavingBio = true;
    });

    try {
      final success = await authProvider.updateProfile(bio: bio);
      if (!success) {
        throw Exception(
            authProvider.errorMessage ?? 'Não foi possível salvar a biografia');
      }
      _lastSyncedBio = bio;
      if (!mounted) return;
      setState(() {
        _isEditingBio = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biografia atualizada!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a biografia'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingBio = false;
        });
      }
    }
  }

  void _startEditingBio(String currentBio) {
    setState(() {
      _bioController.text = currentBio;
      _isEditingBio = true;
    });
    _bioFocusNode.requestFocus();
  }

  void _cancelEditingBio(String currentBio) {
    setState(() {
      _bioController.text = currentBio;
      _isEditingBio = false;
    });
    _bioFocusNode.unfocus();
  }

  Future<void> _openFollowList({required bool showFollowers}) async {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).resolvedUserId;
    if (userId == null || userId.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowListScreen(
          userId: userId,
          showFollowers: showFollowers,
        ),
      ),
    );
    if (!mounted) return;
    _loadFollowStats();
  }

  Future<void> _editProfileIdentity({
    required String currentName,
    required String currentUsername,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditProfileDialog(
        authProvider: authProvider,
        currentName: currentName,
        currentUsername: currentUsername,
      ),
    );

    if (saved != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil atualizado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showCreateFolderDialog({
    required Set<String> occupiedNamesLower,
  }) async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Nova pasta'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nome da pasta',
              hintText: 'ex: Casamento, Viagem…',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );

    final rawName = controller.text.trim();
    controller.dispose();

    if (created != true || !mounted) return;
    if (rawName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um nome para a pasta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final key = rawName.toLowerCase();
    if (key == 'outros') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolha outro nome ("Outros" é reservado)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (occupiedNamesLower.contains(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Já existe uma pasta com esse nome'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser!;
    final next = [...user.emptyFolders, rawName];
    final ok = await authProvider.updateEmptyFolders(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Pasta criada!'
              : (authProvider.errorMessage ?? 'Não foi possível criar a pasta'),
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _renameFolder({
    required String currentName,
    required List<Product> categoryProducts,
    required Set<String> occupiedNamesLower,
  }) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renomear pasta'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Novo nome da pasta',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (newName == null || newName.isEmpty || newName == currentName) return;

    final newKey = newName.trim().toLowerCase();
    final currentKey = currentName.trim().toLowerCase();
    if (newKey == 'outros') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolha outro nome ("Outros" é reservado)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (occupiedNamesLower.contains(newKey) && newKey != currentKey) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Já existe uma pasta com esse nome'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    final bool success;
    if (categoryProducts.isEmpty) {
      final u = authProvider.currentUser!;
      final folders = List<String>.from(u.emptyFolders);
      final idx = folders.indexWhere(
        (f) => f.trim().toLowerCase() == currentKey,
      );
      if (idx < 0) return;
      folders[idx] = newName.trim();
      success = await authProvider.updateEmptyFolders(folders);
    } else {
      success = await productProvider.renameFolder(
        productsInFolder: categoryProducts,
        newCategory: newName,
      );
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pasta renomeada com sucesso!'
              : 'Não foi possível renomear a pasta',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _deleteFolder({
    required String categoryName,
    required List<Product> categoryProducts,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final isEmptyFolder = categoryProducts.isEmpty;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar pasta'),
        content: Text(
          isEmptyFolder
              ? 'Deseja apagar a pasta vazia "$categoryName"?'
              : 'Deseja apagar a pasta "$categoryName" e ${categoryProducts.length} produto(s) dentro dela?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final bool success;
    if (isEmptyFolder) {
      final u = authProvider.currentUser!;
      final folders = u.emptyFolders
          .where((f) =>
              f.trim().toLowerCase() != categoryName.trim().toLowerCase())
          .toList();
      success = await authProvider.updateEmptyFolders(folders);
    } else {
      success = await productProvider.deleteFolder(
          productsInFolder: categoryProducts);
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pasta apagada com sucesso'
              : 'Não foi possível apagar a pasta',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    UserModel user,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rootContext = context;
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var busy = false;
    String? inlineError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Apagar conta',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sua conta (@${user.username}), produtos, pastas, notificações e fotos de perfil serão removidos de forma permanente. Esta ação não pode ser desfeita.',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: 'Senha atual',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Digite sua senha para confirmar'
                            : null,
                      ),
                      if (inlineError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          inlineError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setDialogState(() {
                            busy = true;
                            inlineError = null;
                          });
                          final err = await authProvider.deleteAccount(
                            password: passwordController.text.trim(),
                          );
                          if (!ctx.mounted) return;
                          if (err != null) {
                            setDialogState(() {
                              busy = false;
                              inlineError = err;
                            });
                            return;
                          }
                          Navigator.of(ctx).pop();
                          if (!rootContext.mounted) return;
                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            const SnackBar(
                              content: Text('Conta removida'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.of(rootContext).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Apagar definitivamente'),
                ),
              ],
            );
          },
        );
      },
    );
    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const profileAppBarTitle = Text(
      'Perfil',
      style: TextStyle(
        fontFamily: 'Raleway',
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B2C5C),
      ),
    );

    return Consumer2<AuthProvider, ProductProvider>(
      builder: (context, authProvider, productProvider, _) {
        final user = authProvider.currentUser;
        final resolvedUserId = authProvider.resolvedUserId;

        if (user == null || resolvedUserId == null) {
          return Scaffold(
            appBar: AppBar(
              title: profileAppBarTitle,
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFF6B2C5C)),
                  onPressed: _handleLogout,
                ),
              ],
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_loadedProductsForUserId != resolvedUserId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _loadedProductsForUserId = null;
            _loadUserProductsIfNeeded();
          });
        }
        if (_loadedFollowStatsForUserId != resolvedUserId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _loadedFollowStatsForUserId = null;
            _loadFollowStatsIfNeeded();
          });
        }
        if (_badgesBoundForUserId != resolvedUserId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _badgesBoundForUserId = resolvedUserId;
            final badges = Provider.of<BadgesProvider>(context, listen: false);
            unawaited(badges.bindUser(resolvedUserId));
            unawaited(badges.refresh(resolvedUserId));
          });
        }

        final currentBio = user.bio?.trim() ?? '';
        if (!_bioFocusNode.hasFocus && _lastSyncedBio != currentBio) {
          _bioController.text = currentBio;
          _lastSyncedBio = currentBio;
        }

        final mergedUserProductsById = <String, Product>{};
        for (final product in productProvider.products) {
          if (product.userId == resolvedUserId) {
            mergedUserProductsById[product.id] = product;
          }
        }
        for (final product in productProvider.userProducts) {
          mergedUserProductsById[product.id] = product;
        }
        final visibleUserProducts = mergedUserProductsById.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final productsByCategory = <String, List<Product>>{};
        for (final product in visibleUserProducts) {
          final category =
              (product.category == null || product.category!.trim().isEmpty)
                  ? 'Outros'
                  : product.category!.trim();
          productsByCategory
              .putIfAbsent(category, () => <Product>[])
              .add(product);
        }
        mergeEmptyFolderNamesIntoProductsByCategory(
          productsByCategory,
          user.emptyFolders,
        );
        final orderedCategories =
            orderedFolderCategoryNames(productsByCategory);
        final occupiedFolderNamesLower =
            productsByCategory.keys.map((k) => k.trim().toLowerCase()).toSet();

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: profileAppBarTitle,
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              _buildMenuDrawerButton(resolvedUserId),
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFF6B2C5C)),
                onPressed: _handleLogout,
              ),
            ],
          ),
          endDrawer: _ProfileMenuDrawer(userId: resolvedUserId),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                const SizedBox(height: 22),
                Stack(
                  children: [
                    GestureDetector(
                      onTap:
                          _isUploadingPhoto ? null : _pickAndUploadProfilePhoto,
                      child: UserAvatar(
                        name: user.name,
                        photoUrl: user.photoUrl,
                        radius: 54,
                        textStyle: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B2C5C),
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Toque para atualizar foto',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Biografia',
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B2C5C),
                              ),
                            ),
                          ),
                          if (!_isEditingBio)
                            TextButton.icon(
                              onPressed: () => _startEditingBio(currentBio),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Editar'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF6B2C5C),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isEditingBio) ...[
                        TextField(
                          controller: _bioController,
                          focusNode: _bioFocusNode,
                          minLines: 2,
                          maxLines: 4,
                          maxLength: 180,
                          decoration: const InputDecoration(
                            hintText: 'Escreva sua biografia...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isSavingBio
                                  ? null
                                  : () => _cancelEditingBio(currentBio),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isSavingBio ? null : _saveBio,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B2C5C),
                                foregroundColor: Colors.white,
                              ),
                              child: _isSavingBio
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Salvar'),
                            ),
                          ],
                        ),
                      ] else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.withValues(alpha: 0.12),
                          ),
                          child: Text(
                            currentBio.isEmpty
                                ? 'Adicione uma bio para as pessoas te conhecerem melhor.'
                                : currentBio,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: currentBio.isEmpty
                                  ? Colors.grey.shade700
                                  : const Color(0xFF191919),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProfileStatItem(
                        label: 'Seguidores',
                        value: _isLoadingFollowStats
                            ? '-'
                            : _followersCount.toString(),
                        onTap: _isLoadingFollowStats
                            ? null
                            : () => _openFollowList(showFollowers: true),
                      ),
                      _ProfileStatItem(
                        label: 'Seguindo',
                        value: _isLoadingFollowStats
                            ? '-'
                            : _followingCount.toString(),
                        onTap: _isLoadingFollowStats
                            ? null
                            : () => _openFollowList(showFollowers: false),
                      ),
                      _ProfileStatItem(
                        label: 'Pastas',
                        value: productsByCategory.length.toString(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _editProfileIdentity(
                        currentName: user.name,
                        currentUsername: user.username,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar perfil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B2C5C),
                        side: const BorderSide(color: Color(0xFF6B2C5C)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const FollowUsersScreen()),
                        );
                        if (!mounted) return;
                        _loadFollowStats();
                      },
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text('Gerenciar seguidores'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B2C5C),
                        side: const BorderSide(color: Color(0xFF6B2C5C)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          'Pastas',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B2C5C),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: productProvider.isLoading
                            ? null
                            : () => _showCreateFolderDialog(
                                  occupiedNamesLower: occupiedFolderNamesLower,
                                ),
                        icon: const Icon(Icons.create_new_folder_outlined,
                            size: 20),
                        label: const Text('Nova pasta'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6B2C5C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (productProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )
                else if (orderedCategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Você ainda não possui pastas',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orderedCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final category = orderedCategories[index];
                      final categoryProducts = productsByCategory[category]!;
                      final coverImage = categoryProducts.isNotEmpty
                          ? categoryProducts.first.imageUrl
                          : '';

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            final provider = Provider.of<ProductProvider>(
                              context,
                              listen: false,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FolderProductsScreen(
                                  categoryName: category,
                                  products: categoryProducts,
                                  allowDelete: true,
                                  onDeleteProduct: (product) async {
                                    return provider.deleteProduct(product.id);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 46,
                                    height: 46,
                                    color: const Color(0xFF8B7FB8)
                                        .withValues(alpha: 0.15),
                                    child: coverImage.isEmpty
                                        ? const Icon(
                                            Icons.folder_outlined,
                                            color: Color(0xFF6B2C5C),
                                          )
                                        : Image.network(
                                            coverImage,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.folder_outlined,
                                                color: Color(0xFF6B2C5C),
                                              );
                                            },
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category,
                                        style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        categoryProducts.isEmpty
                                            ? 'Pasta vazia — adicione produtos quando quiser'
                                            : '${categoryProducts.length} produtos salvos',
                                        style: const TextStyle(
                                          fontFamily: 'Roboto',
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'rename') {
                                      _renameFolder(
                                        currentName: category,
                                        categoryProducts: categoryProducts,
                                        occupiedNamesLower:
                                            occupiedFolderNamesLower,
                                      );
                                    } else if (value == 'delete') {
                                      _deleteFolder(
                                        categoryName: category,
                                        categoryProducts: categoryProducts,
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem<String>(
                                      value: 'rename',
                                      child: Text('Renomear pasta'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('Apagar pasta'),
                                    ),
                                  ],
                                  icon: const Icon(Icons.more_vert),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () =>
                            _showDeleteAccountDialog(context, user),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                        ),
                        child: const Text('Apagar minha conta'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuDrawerButton(String userId) {
    return StreamBuilder<int>(
      stream: _firebaseService.getUnreadNotificationsCountStream(userId),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        final hasUnread = unread > 0;
        return IconButton(
          tooltip: 'Menu do perfil',
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_outlined,
                color: Color(0xFF6B2C5C),
              ),
              if (hasUnread)
                const Positioned(
                  right: -1,
                  top: -1,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: Color(0xFF2D8CFF),
                  ),
                ),
              const Positioned(
                right: -12,
                top: 2,
                child: Icon(
                  Icons.menu_open,
                  size: 12,
                  color: Color(0xFF6B2C5C),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileMenuDrawer extends StatefulWidget {
  final String userId;

  const _ProfileMenuDrawer({required this.userId});

  @override
  State<_ProfileMenuDrawer> createState() => _ProfileMenuDrawerState();
}

class _ProfileMenuDrawerState extends State<_ProfileMenuDrawer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.index == 1 && !_tabController.indexIsChanging) {
      unawaited(_firebaseService.markAllNotificationsAsRead(widget.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.9,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Menu do Perfil',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF6B2C5C),
                  ),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6B2C5C),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF6B2C5C),
              tabs: const [
                Tab(text: 'Badges'),
                Tab(text: 'Notificações'),
                Tab(text: 'Métricas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Consumer<BadgesProvider>(
                    builder: (context, provider, _) {
                      return BadgesPanel(
                        badges: provider.badges,
                        isLoading: provider.isLoading,
                        errorMessage: provider.errorMessage,
                      );
                    },
                  ),
                  ProfileNotificationsPanel(
                    userId: widget.userId,
                    markAsReadOnInit: false,
                  ),
                  ProfileMetricsPanel(userId: widget.userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final AuthProvider authProvider;
  final String currentName;
  final String currentUsername;

  const _EditProfileDialog({
    required this.authProvider,
    required this.currentName,
    required this.currentUsername,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  bool _isSaving = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _usernameController = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  String _normalizeUsername(String value) {
    return value
        .trim()
        .replaceAll('@', '')
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newName = _nameController.text.trim();
    final newUsername = _normalizeUsername(_usernameController.text);
    if (newName == widget.currentName &&
        newUsername == widget.currentUsername) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    final success = await widget.authProvider.updateProfile(
      name: newName,
      username: newUsername,
    );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSaving = false;
      _inlineError = widget.authProvider.errorMessage ??
          'Não foi possível atualizar o perfil';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar perfil'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: 'Nome no perfil',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe seu nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              enabled: !_isSaving,
              decoration: const InputDecoration(
                labelText: '@ no app',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (value) {
                final normalized = _normalizeUsername(value ?? '');
                if (normalized.isEmpty) {
                  return 'Informe seu @';
                }
                if (normalized.length < 3) {
                  return 'Seu @ deve ter pelo menos 3 caracteres';
                }
                if (!RegExp(r'^[a-z0-9._]+$').hasMatch(normalized)) {
                  return 'Use apenas letras, números, ponto ou underscore';
                }
                return null;
              },
            ),
            if (_inlineError != null) ...[
              const SizedBox(height: 12),
              Text(
                _inlineError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ProfileStatItem({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF6B2C5C),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: content,
      ),
    );
  }
}
