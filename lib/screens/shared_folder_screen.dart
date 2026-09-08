import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/shared_folder_provider.dart';
import '../services/firebase_service.dart';
import '../services/shared_folder_link_service.dart';
import '../navigation/app_navigator.dart';
import '../widgets/download_app_modal.dart';
import '../widgets/product_network_image.dart';
import 'folder_products_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SharedFolderScreen extends StatefulWidget {
  final String userId;
  final String folderName;
  final bool clearPendingOnOpen;

  const SharedFolderScreen({
    super.key,
    required this.userId,
    required this.folderName,
    this.clearPendingOnOpen = false,
  });

  @override
  State<SharedFolderScreen> createState() => _SharedFolderScreenState();
}

class _SharedFolderScreenState extends State<SharedFolderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.clearPendingOnOpen) {
        await SharedFolderLinkService.instance.clearPending();
      }
      if (!mounted) return;
      context.read<SharedFolderProvider>().loadDebounced(
            userId: widget.userId,
            folderName: widget.folderName,
          );
    });
  }

  Future<void> _goToLogin() async {
    await SharedFolderLinkService.instance.savePending(
      SharedFolderParams(
        userId: widget.userId,
        folderName: widget.folderName,
      ),
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(redirectToPendingSharedFolder: true),
      ),
    );
  }

  Future<void> _openFolderAuthenticated() async {
    final provider = context.read<SharedFolderProvider>();
    List<Product> products = List<Product>.from(provider.products);

    if (products.isEmpty) {
      try {
        final all =
            await FirebaseService().getUserProducts(widget.userId);
        products = all
            .where(
              (p) =>
                  (p.category ?? '').trim().toLowerCase() ==
                  widget.folderName.trim().toLowerCase(),
            )
            .toList();
      } catch (_) {
        // keep empty; FolderProductsScreen handles empty state
      }
    }

    await SharedFolderLinkService.instance.clearPending();
    if (!mounted) return;

    final folderName = widget.folderName;
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    await nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
    await nav.push(
      MaterialPageRoute(
        builder: (_) => FolderProductsScreen(
          categoryName: folderName,
          products: products,
          allowDelete: false,
        ),
      ),
    );
  }

  Future<void> _onPrimaryAuthAction() async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated || auth.hasActiveFirebaseSession) {
      await _openFolderAuthenticated();
      return;
    }
    await _goToLogin();
  }

  String _initials(UserModel? user) {
    final name = (user?.name ?? '').trim();
    if (name.isEmpty) {
      final username = (user?.username ?? '').trim();
      if (username.isEmpty) return '?';
      return username.substring(0, 1).toUpperCase();
    }
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  int _columnCount(double width) {
    if (width > 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn =
        auth.isAuthenticated || auth.hasActiveFirebaseSession;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Consumer<SharedFolderProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.owner == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B7FB8),
                    ),
                  );
                }

                if (provider.errorMessage != null && provider.owner == null) {
                  return _ErrorState(
                    onRetry: () => provider.load(
                      userId: widget.userId,
                      folderName: widget.folderName,
                    ),
                  );
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _SharedHeader(
                        folderName: widget.folderName,
                        owner: provider.owner,
                        initials: _initials(provider.owner),
                        isLoggedIn: isLoggedIn,
                        onDownload: () => showDownloadAppModal(context),
                        onAuthAction: _onPrimaryAuthAction,
                      ),
                    ),
                    if (provider.isLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF8B7FB8),
                          ),
                        ),
                      )
                    else if (provider.products.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyFolderState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final columns =
                                _columnCount(constraints.crossAxisExtent);
                            return SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.75,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product = provider.products[index];
                                  return _SharedProductCard(
                                    product: product,
                                    onShopNow: () =>
                                        showDownloadAppModal(context),
                                  );
                                },
                                childCount: provider.products.length,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SharedHeader extends StatelessWidget {
  final String folderName;
  final UserModel? owner;
  final String initials;
  final bool isLoggedIn;
  final VoidCallback onDownload;
  final VoidCallback onAuthAction;

  const _SharedHeader({
    required this.folderName,
    required this.owner,
    required this.initials,
    required this.isLoggedIn,
    required this.onDownload,
    required this.onAuthAction,
  });

  @override
  Widget build(BuildContext context) {
    final username = (owner?.username ?? '').trim();
    final displayUsername =
        username.isEmpty ? '@usuario' : '@${username.replaceAll('@', '')}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 600;

        final photoUrl = owner?.photoUrl?.trim();
        final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
        final initialsChild = Center(
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Raleway',
            ),
          ),
        );
        final avatar = SizedBox(
          width: 60,
          height: 60,
          child: ClipOval(
            child: ColoredBox(
              color: const Color(0xFF8B7FB8),
              child: hasPhoto
                  ? Image.network(
                      ProductNetworkImage.normalizeUrl(photoUrl),
                      fit: BoxFit.cover,
                      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                      errorBuilder: (_, __, ___) => initialsChild,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return initialsChild;
                      },
                    )
                  : initialsChild,
            ),
          ),
        );

        final titleBlock = Column(
          crossAxisAlignment:
              narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              folderName,
              textAlign: narrow ? TextAlign.center : TextAlign.start,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF6B2C5C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayUsername,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF8B7FB8),
              ),
            ),
          ],
        );

        final downloadButton = SizedBox(
          width: narrow ? double.infinity : constraints.maxWidth * 0.60,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download, size: 20),
            label: const Text(
              'Baixar Gimie',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7FB8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

        final authButton = SizedBox(
          width: narrow ? double.infinity : constraints.maxWidth * 0.35,
          height: 48,
          child: OutlinedButton(
            onPressed: onAuthAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B7FB8),
              side: const BorderSide(color: Color(0xFF8B7FB8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isLoggedIn ? 'Ver pasta' : 'Entrar',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                color: Color(0xFF8B7FB8),
              ),
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Column(
            children: [
              if (narrow) ...[
                avatar,
                const SizedBox(height: 12),
                titleBlock,
              ] else
                Row(
                  children: [
                    avatar,
                    const SizedBox(width: 14),
                    Expanded(child: titleBlock),
                  ],
                ),
              const SizedBox(height: 16),
              if (narrow) ...[
                downloadButton,
                const SizedBox(height: 12),
                authButton,
              ] else
                Row(
                  children: [
                    Expanded(flex: 60, child: downloadButton),
                    const SizedBox(width: 12),
                    Expanded(flex: 35, child: authButton),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SharedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onShopNow;

  const _SharedProductCard({
    required this.product,
    required this.onShopNow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFEFEFEF),
                child: ProductNetworkImage(
                  imageUrl: product.imageUrl,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF191919),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFF8B7FB8),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onShopNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B7FB8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      child: const Text('Shop Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFF757575)),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar esta pasta',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B7FB8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFolderState extends StatelessWidget {
  const _EmptyFolderState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined, size: 56, color: Color(0xFF757575)),
            SizedBox(height: 12),
            Text(
              'Esta pasta ainda não tem produtos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
