# Arquivo de Regiões Geográficas - supported_regions.geojson

Este arquivo define as regiões geográficas onde o app Gimie está disponível.

## 📍 Regiões Incluídas

### América do Sul (13 países)
- 🇦🇷 Argentina
- 🇧🇴 Bolívia  
- 🇧🇷 Brasil
- 🇨🇱 Chile
- 🇨🇴 Colômbia
- 🇪🇨 Equador
- 🇬🇾 Guiana
- 🇬🇫 Guiana Francesa
- 🇵🇾 Paraguai
- 🇵🇪 Peru
- 🇸🇷 Suriname
- 🇺🇾 Uruguai
- 🇻🇪 Venezuela

### América Central (7 países)
- 🇧🇿 Belize
- 🇨🇷 Costa Rica
- 🇸🇻 El Salvador
- 🇬🇹 Guatemala
- 🇭🇳 Honduras
- 🇳🇮 Nicarágua
- 🇵🇦 Panamá

### América do Norte (3 países)
- 🇨🇦 Canadá
- 🇺🇸 Estados Unidos
- 🇲🇽 México

### Caribe (13 países)
- 🇦🇬 Antígua e Barbuda
- 🇧🇸 Bahamas
- 🇧🇧 Barbados
- 🇨🇺 Cuba
- 🇩🇲 Dominica
- 🇩🇴 República Dominicana
- 🇬🇩 Granada
- 🇭🇹 Haiti
- 🇯🇲 Jamaica
- 🇱🇨 Santa Lúcia
- 🇰🇳 São Cristóvão e Nevis
- 🇻🇨 São Vicente e Granadinas
- 🇹🇹 Trinidad e Tobago

### Europa (3 países)
- 🇪🇸 Espanha
- 🇮🇪 Irlanda
- 🇵🇹 Portugal

### África (Países Lusófonos - 5 países)
- 🇦🇴 Angola
- 🇨🇻 Cabo Verde
- 🇬🇶 Guiné Equatorial
- 🇬🇼 Guiné-Bissau
- 🇲🇿 Moçambique
- 🇸🇹 São Tomé e Príncipe

### Ásia/Oceania (Países Lusófonos - 2 países/regiões)
- 🇲🇴 Macau
- 🇹🇱 Timor-Leste

## 📊 Total
**47 países/regiões** cobertos

## 📁 Formato do Arquivo

- **Tipo**: GeoJSON
- **Estrutura**: FeatureCollection com um único Feature
- **Geometria**: MultiPolygon (único elemento, conforme requisito da Apple)
- **Coordenadas**: Polígonos simplificados representando as fronteiras de cada país

## 🚀 Como Usar no App Store Connect

### Passo 1: Acesse App Store Connect
1. Vá em [App Store Connect](https://appstoreconnect.apple.com/)
2. Selecione seu app (Gimie)

### Passo 2: Configure a Disponibilidade
1. Na seção **"Preços e Disponibilidade"** ou **"Pricing and Availability"**
2. Procure por **"Availability"** ou **"Disponibilidade"**
3. Clique em **"Edit"** ou **"Editar"**

### Passo 3: Upload do Arquivo
1. Procure a opção **"Geographic Availability"** ou **"Disponibilidade Geográfica"**
2. Clique em **"Upload Custom GeoJSON"** ou similar
3. Selecione o arquivo `supported_regions.geojson`
4. Aguarde a validação

### Passo 4: Validação
A Apple irá validar se:
- ✅ O arquivo está em formato .geojson válido
- ✅ Contém apenas um elemento MultiPolygon
- ✅ As coordenadas são válidas
- ✅ Não há sobreposição inválida

### Passo 5: Salvar
1. Revise as regiões selecionadas
2. Clique em **"Save"** ou **"Salvar"**

## 🔍 Validação Local

Para validar o arquivo localmente antes de fazer upload:

### Usando geojson.io:
1. Acesse https://geojson.io/
2. Arraste o arquivo `supported_regions.geojson` para a página
3. Verifique se o mapa mostra as regiões corretamente

### Usando Validador Online:
1. Acesse https://geojsonlint.com/
2. Cole o conteúdo do arquivo
3. Verifique se não há erros

## 📝 Notas Importantes

1. **Idiomas**: Considere adicionar traduções para português (Brasil e Portugal), espanhol e inglês
2. **Moedas**: O app já suporta conversão de moedas, o que é perfeito para essa distribuição multi-regional
3. **Compliance**: Certifique-se de que suas políticas de privacidade estão em conformidade com:
   - LGPD (Brasil)
   - GDPR (União Europeia - Espanha, Portugal, Irlanda)
   - Leis locais de cada país

## 🌍 Estratégia de Lançamento

### Fase 1 - Mercados Prioritários:
- Brasil (mercado principal)
- Portugal
- Estados Unidos
- Espanha

### Fase 2 - Expansão América Latina:
- Argentina
- México
- Colômbia
- Chile

### Fase 3 - Demais Regiões:
- Restante da América do Sul
- América Central
- Países lusófonos da África

## 🔄 Atualizações Futuras

Para adicionar ou remover países:
1. Edite o arquivo `supported_regions.geojson`
2. Adicione/remova as coordenadas do polígono do país
3. Atualize a lista de países nas propriedades
4. Faça novo upload no App Store Connect

## 📞 Suporte

Para mais informações sobre disponibilidade geográfica:
- [App Store Connect Help - Geographic Availability](https://developer.apple.com/help/app-store-connect/manage-app-availability/set-geographic-availability)
- [GeoJSON Specification](https://geojson.org/)

---

**Arquivo criado em**: 2026-05-17  
**Última atualização**: 2026-05-17  
**Versão**: 1.0
