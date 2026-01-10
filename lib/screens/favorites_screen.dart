import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favoritos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B2C5C),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer2<AuthProvider, ProductProvider>(
        builder: (context, auth, products, _) {
          final userId = auth.currentUser?.id;
          if (userId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final favs = products.products
              .where((p) => p.likedBy.contains(userId))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (favs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum favorito ainda',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final Product product = favs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text(product.formattedPrice),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Color(0xFF8B7FB8)),
                    onPressed: () {
                      products.toggleLike(product.id, userId);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

