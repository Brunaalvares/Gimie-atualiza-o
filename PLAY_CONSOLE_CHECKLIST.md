# Google Play Console - Checklist Final (Gimie)

Este checklist considera o projeto atual com pacote `com.gimie.app`.

## 1) Preparar assinatura (obrigatorio)

- [ ] Gerar upload keystore (uma vez):
  - `keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- [ ] Editar `android/key.properties`:
  - `storePassword`
  - `keyPassword`
  - `keyAlias=upload` (ou seu alias real)
  - `storeFile=../upload-keystore.jks` (ou caminho real do `.jks`)
- [ ] Confirmar que `android/upload-keystore.jks` existe no caminho informado.

## 2) Versionamento (versionCode/versionName)

No projeto, o Android usa:
- `versionCode` <- `flutter.versionCode`
- `versionName` <- `flutter.versionName`

Ou seja, basta atualizar no `pubspec.yaml`:
- [ ] `version: X.Y.Z+N`
  - `X.Y.Z` = versionName (ex: `1.0.1`)
  - `N` = versionCode (inteiro, sempre maior que o anterior)

Exemplo:
- `version: 1.0.1+2`

## 3) Build do AAB assinado

- [ ] Rodar:
  - `flutter clean`
  - `flutter pub get`
  - `flutter build appbundle --release`
- [ ] Confirmar artefato gerado:
  - `build/app/outputs/bundle/release/app-release.aab`

## 4) Verificacoes tecnicas antes do upload

- [ ] `flutter analyze` sem erros.
- [ ] `flutter test` passando.
- [ ] App abre em dispositivo/emulador sem crash.
- [ ] Login/cadastro funcionando.
- [ ] Fluxo principal de produtos funcionando (listar/criar/buscar).
- [ ] Endpoint de backend estavel para producao.

## 5) Play Console - primeiro envio

- [ ] Entrar em [Google Play Console](https://play.google.com/console)
- [ ] Criar app:
  - Nome: `Gimie`
  - Idioma padrao: `Portuguese (Brazil)`
  - Tipo: App
  - Categoria: (definir)
- [ ] Completar "App content":
  - Publico-alvo
  - Classificacao de conteudo
  - Politica de privacidade (URL publica)
  - Declaracoes de dados e seguranca (Data safety)
- [ ] Completar "Store listing":
  - Descricao curta
  - Descricao completa
  - Icone 512x512
  - Feature graphic 1024x500
  - Screenshots

## 6) Envio da release (producao)

- [ ] Ir em `Production` -> `Create new release`
- [ ] Upload do `app-release.aab`
- [ ] Inserir notas da versao (o que mudou)
- [ ] Salvar e revisar warnings
- [ ] `Review release` -> `Start rollout to Production`

## 7) Pos-publicacao

- [ ] Monitorar "Android vitals" (ANR/crash)
- [ ] Monitorar reviews e rating
- [ ] Para cada nova release:
  - aumentar `versionCode`
  - ajustar `versionName`
  - gerar novo `.aab`
