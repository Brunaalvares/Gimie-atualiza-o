# Mapeamento de Rotas x API 2.0

Checagem manual realizada em `2026-04-25` contra `https://api2gimie.vercel.app`.

## Rotas chamadas pelo app

- `GET /health` -> disponivel (`200`)
- `GET /api/products` -> instavel/timeout (`000` ou `504 FUNCTION_INVOCATION_TIMEOUT`)
- `POST /api/products` -> disponivel (`400` para payload invalido, rota existe)
- `GET /api/products/exchange-rates` -> disponivel (`200`)
- `GET /api/products/convert/:currency` -> instavel/timeout (`000`)
- `POST /api/auth/login` -> nao publicada (`500` com `"Not Found - /api/auth/login"`)
- `POST /api/auth/register` -> nao publicada (`500` com `"Not Found - /api/auth/register"`)
- `GET/PUT /api/users/:id` -> nao publicada (`500` com `"Not Found - /api/users/:id"`)
- `GET /api/products/search` -> nao publicada/indisponivel no deploy atual
- `GET /api/products/:id/like` (ou `POST`) -> nao publicada/indisponivel no deploy atual
- `GET /api/suggestions` -> nao publicada (`500` com `"Not Found - /api/suggestions..."`)
- `DELETE /api/cache` -> nao publicada (`500` com `"Not Found - /api/cache"`)

## Ajustes aplicados no app

- Auth e Users via API foram marcados como indisponiveis na API 2.0 atual (nao bloqueiam fluxo Firebase).
- Busca de produtos foi ajustada para fallback local (filtra lista carregada) quando endpoint remoto nao existe.
- Sugestoes no `ScrapingService` agora usam `GET /api/products/suggestions` (rota alinhada ao contrato da API 2.0).
- Chamadas para limpar cache remoto foram protegidas para nao chamar endpoint inexistente.
