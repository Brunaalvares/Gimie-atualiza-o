import '../models/product_model.dart';

/// Junta nomes de pastas sem produto ao mapa derivado das categorias dos produtos.
void mergeEmptyFolderNamesIntoProductsByCategory(
  Map<String, List<Product>> productsByCategory,
  List<String> emptyFolderNames,
) {
  for (final raw in emptyFolderNames) {
    final t = raw.trim();
    if (t.isEmpty) continue;
    productsByCategory.putIfAbsent(t, () => <Product>[]);
  }
}

/// Pastas com produto primeiro (mais recente primeiro); pastas vazias por ordem alfabética.
List<String> orderedFolderCategoryNames(
  Map<String, List<Product>> productsByCategory,
) {
  final keys = productsByCategory.keys.toList();
  keys.sort((a, b) {
    final la = productsByCategory[a]!;
    final lb = productsByCategory[b]!;
    final aEmpty = la.isEmpty;
    final bEmpty = lb.isEmpty;
    if (aEmpty != bEmpty) {
      return aEmpty ? 1 : -1;
    }
    if (aEmpty && bEmpty) {
      return a.toLowerCase().compareTo(b.toLowerCase());
    }
    final aLatest = la.map((p) => p.createdAt).reduce((x, y) => x.isAfter(y) ? x : y);
    final bLatest = lb.map((p) => p.createdAt).reduce((x, y) => x.isAfter(y) ? x : y);
    return bLatest.compareTo(aLatest);
  });
  return keys;
}
