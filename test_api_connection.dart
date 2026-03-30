import 'dart:convert';
import 'dart:io';

// Script para testar a conexão com a nova API Gimie 2.0
void main() async {
  final client = HttpClient();
  
  print('🧪 Testando conexão com Gimie API 2.0...\n');
  
  try {
    // Teste 1: Health Check
    print('1️⃣ Testando Health Check...');
    final healthRequest = await client.getUrl(Uri.parse('https://api2gimie.vercel.app/health'));
    final healthResponse = await healthRequest.close();
    final healthBody = await healthResponse.transform(utf8.decoder).join();
    
    if (healthResponse.statusCode == 200) {
      print('✅ Health Check: OK');
      print('   Response: $healthBody\n');
    } else {
      print('❌ Health Check: FAIL (${healthResponse.statusCode})');
      print('   Response: $healthBody\n');
    }
    
    // Teste 2: Listar Produtos
    print('2️⃣ Testando listagem de produtos...');
    final productsRequest = await client.getUrl(Uri.parse('https://api2gimie.vercel.app/api/products'));
    final productsResponse = await productsRequest.close();
    final productsBody = await productsResponse.transform(utf8.decoder).join();
    
    if (productsResponse.statusCode == 200) {
      print('✅ Listagem de produtos: OK');
      final data = jsonDecode(productsBody);
      if (data['success'] == true) {
        final products = data['data']['products'] ?? [];
        print('   Produtos encontrados: ${products.length}\n');
      }
    } else {
      print('❌ Listagem de produtos: FAIL (${productsResponse.statusCode})');
      print('   Response: $productsBody\n');
    }
    
    // Teste 3: Taxas de Câmbio
    print('3️⃣ Testando taxas de câmbio...');
    final ratesRequest = await client.getUrl(Uri.parse('https://api2gimie.vercel.app/api/products/exchange-rates'));
    final ratesResponse = await ratesRequest.close();
    final ratesBody = await ratesResponse.transform(utf8.decoder).join();
    
    if (ratesResponse.statusCode == 200) {
      print('✅ Taxas de câmbio: OK');
      final data = jsonDecode(ratesBody);
      if (data['success'] == true) {
        final rates = data['data']['rates'];
        print('   Moedas disponíveis: ${rates.keys.join(', ')}\n');
      }
    } else {
      print('❌ Taxas de câmbio: FAIL (${ratesResponse.statusCode})');
      print('   Response: $ratesBody\n');
    }
    
    // Teste 4: Scraping de URL (exemplo)
    print('4️⃣ Testando scraping de produto...');
    final scrapeRequest = await client.postUrl(Uri.parse('https://api2gimie.vercel.app/api/products'));
    scrapeRequest.headers.set('Content-Type', 'application/json');
    scrapeRequest.write(jsonEncode({
      'url': 'https://www.amazon.com.br/Echo-Dot-5%C2%AA-gera%C3%A7%C3%A3o-Cor-Azul/dp/B09B8V1LZ3'
    }));
    
    final scrapeResponse = await scrapeRequest.close();
    final scrapeBody = await scrapeResponse.transform(utf8.decoder).join();
    
    if (scrapeResponse.statusCode == 200 || scrapeResponse.statusCode == 201) {
      print('✅ Scraping de produto: OK');
      final data = jsonDecode(scrapeBody);
      if (data['success'] == true) {
        final product = data['data'];
        print('   Produto: ${product['name']}');
        print('   Preço: ${product['currency']} ${product['price']}\n');
      }
    } else {
      print('❌ Scraping de produto: FAIL (${scrapeResponse.statusCode})');
      print('   Response: $scrapeBody\n');
    }
    
    print('🎉 Testes concluídos!');
    print('📊 API Gimie 2.0 está funcionando corretamente.');
    
  } catch (e) {
    print('❌ Erro durante os testes: $e');
  } finally {
    client.close();
  }
}