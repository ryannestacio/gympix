# Modelo Firestore Multi-tenant (v1)

Este app usa isolamento de dados por tenant.

## Estrutura canonica

- `user_tenants/{uid}`
- `tenants/{tenantId}`
- `tenants/{tenantId}/alunos/{alunoId}`
- `tenants/{tenantId}/config/{docId}`
- `tenants/{tenantId}/fechamentos_mensais/{id}`

## Documentos padrao em `config`

- `tenants/{tenantId}/config/app`
- `tenants/{tenantId}/config/pix`

## Campos obrigatorios (v1)

### user_tenants/{uid}

- `tenantId`: `String`
- `role`: `String` (`owner|admin|staff`)
- `ativo`: `bool` (ou `status: String` para compatibilidade)
- `status`: `String` (`ativo|inativo`) opcional
- `createdAt`: `Timestamp` recomendado
- `updatedAt`: `Timestamp` recomendado

### tenants/{tenantId}

- `status`: `String` (`ativo|inativo`) ou `ativo: bool`
- `nome`: `String` recomendado
- `createdAt`: `Timestamp` recomendado
- `updatedAt`: `Timestamp` recomendado

### tenants/{tenantId}/alunos/{alunoId}

- `tenantId`: `String`
- `docType`: `String` (`aluno`)
- `nome`: `String`
- `telefone`: `String`
- `observacao`: `String`
- `diaVencimento`: `num` (inteiro 1-31)
- `mensalidade`: `num` (double)
- `ativo`: `bool`
- `status`: `String` (`ativo|arquivado`)
- `createdAt`: `Timestamp`
- `updatedAt`: `Timestamp`
- `pagamentos`: `Map<String, Map>` (subcampos com `status`, `valor`, `diaVencimento`, `pagoEm`)

### tenants/{tenantId}/config/{docId}

- `tenantId`: `String`
- `docType`: `String` (`app_config|pix_config`)
- `ativo`: `bool`
- `status`: `String` (`ativo`)
- `createdAt`: `Timestamp`
- `updatedAt`: `Timestamp`
- Campos funcionais variam por doc:
- `pix`: `pixCode: String`
- `app`: `defaultMensalidade: num`, `cobrancaRegua: Map`, `inadimplencia: Map`

### tenants/{tenantId}/fechamentos_mensais/{id}

- `tenantId`: `String`
- `docType`: `String` (`fechamento_mensal`)
- `competencia`: `String` (`yyyy-MM`)
- `status`: `String` (`aberto|fechado`)
- `schemaVersion`: `num` (inteiro)
- `totais`: `Map`
- `alunosSnapshot`: `List<Map>`
- `fechadoEm`: `Timestamp|null`
- `createdAt`: `Timestamp`
- `updatedAt`: `Timestamp`

## Observacoes

- Todo modulo de dominio deve ler/escrever via `tenantId` da sessao autenticada.
- Paths foram centralizados em `lib/core/constants/firestore_paths.dart`.
- Campos obrigatorios/metadata foram centralizados em `lib/core/constants/firestore_fields.dart`.
- Evite strings hardcoded de colecao em novos repositorios.

## Regras de seguranca

- Arquivo: `firestore.rules`
- Estrategia: `deny by default`
- Somente usuarios autenticados (`request.auth != null`) com vinculo em `user_tenants/{uid}` podem acessar dados.
- Acesso permitido apenas quando `membership.tenantId == tenantId` da rota.
- Validacao de tenant/membership ativos via `ativo`/`status`.

## Seed inicial (v1)

- Implementado em `AuthRepository.resolveSession(...)`.
- Fluxo: antes de resolver sessao, o app executa `_seedInitialTenantIfMissing(user)`.

### O que e criado para novo usuario

- `tenants/{uid}`
- `user_tenants/{uid}` com:
- `tenantId = uid`
- `role = owner`
- `status = ativo`
- `ativo = true`
- `createdAt/updatedAt`
- `tenants/{uid}/config/app`
- `tenants/{uid}/config/pix`

### Regras do seed

- O seed so roda se `user_tenants/{uid}` ainda nao existir.
- Escritas em `tenants/{uid}` e `config/{app|pix}` so acontecem se os docs nao existirem.
- Objetivo: garantir onboarding com dados minimos sem sobrescrever dados ja existentes.

## Integracao CRUD no app (v1)

- Todos os repositorios de dominio recebem `tenantId` da sessao autenticada (`authSessionProvider`).
- Nenhum modulo acessa colecoes raiz sem escopo de tenant.

### Modulos integrados

- Alunos: `AlunosRepository` em `tenants/{tenantId}/alunos/{alunoId}`.
- Config: `ConfigRepository` em `tenants/{tenantId}/config/{docId}`.
- Cobranca: `CobrancaReguaRepository` em:
- `tenants/{tenantId}/config/app`
- `tenants/{tenantId}/alunos/{alunoId}/cobranca_envios/{envioId}`
- `tenants/{tenantId}/cobranca_push_queue/{jobId}`
- Relatorios: `CompetenciaFechamentoRepository` em `tenants/{tenantId}/fechamentos_mensais/{id}`.

## Integridade de escrita (v1)

- Operacoes que escrevem em mais de um documento usam atomicidade (`Transaction`).
- Fluxo critico implementado:
- Automacao de cobranca grava `cobranca_envios` e `cobranca_push_queue` na mesma transacao.
- Se o envio automatico ja existir, a transacao nao regrava nem duplica fila.
- Idempotencia da fila push via `jobId` deterministico (`buildPushQueueJobId`).

## Offline e resiliencia (v1)

- Cache/offline habilitado no bootstrap do app:
- `FirebaseFirestore.settings = Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)`
- Auth resiliente: seed inicial nao bloqueia sessao quando a rede cai (transacao offline), e leituras de sessao tentam fallback em cache.
- Escritas de Config (`pix` e `mensalidade`) agora avaliam sincronizacao:
- se `waitForPendingWrites` confirma envio ao servidor: mensagem de sucesso sincronizado.
- se houver timeout/rede: mensagem de salvo localmente com sincronizacao pendente.
- Erros de Firestore/rede padronizados em `formatFirestoreError(...)`, incluindo cenarios de sincronizacao (`failed-precondition`, `unimplemented`).

## Testes com Emulator Suite (v1)

- Arquivo de suite: `emulator-tests/firestore.rules.test.mjs`
- Runner: `@firebase/rules-unit-testing` + `node --test`
- Execucao segura (sem banco real):
- `npm run emulator:test:firestore`

### Cobertura de cenarios

- Regras de bootstrap:
- `user_tenants/{uid}` create somente para o proprio `uid`.
- `tenants/{uid}` create somente para o proprio `uid`.
- `config/{app|pix}` liberado no bootstrap.
- Permissao multi-tenant:
- leitura/escrita permitidas apenas no `tenantId` do vinculo.
- bloqueio de acesso cross-tenant.
- Integridade de path/tenant:
- bloqueio de escrita com `tenantId` divergente da rota.
- Restricoes estruturais:
- bloqueio de `delete` onde regra exige.
- bloqueio de `list` em `user_tenants`.
- Status de acesso:
- usuario com vinculo inativo perde leitura/escrita.

## Indices (v1)

- Arquivo: `firestore.indexes.json`
- Estado atual: sem indices compostos (`indexes: []`)

### Queries reais analisadas

- `tenants/{tenantId}/alunos`: `orderBy(diaVencimento).orderBy(__name__).limit(...)`
- `tenants/{tenantId}/alunos/{alunoId}/cobranca_envios`: `orderBy(enviadoEm desc).limit(...)`
- `tenants/{tenantId}/fechamentos_mensais/{id}`: acesso direto por `doc(id)`
- `tenants/{tenantId}/config/{docId}`: acesso direto por `doc(id)`

### Resultado

- Nenhuma query composta com `where + orderBy` em campos diferentes foi encontrada.
- Portanto, nao ha indice composto obrigatorio neste momento.
- O arquivo foi versionado para evitar drift e permitir evolucao segura quando surgirem novas consultas.

## Deploy controlado (v1)

- Script oficial: `scripts/firestore_deploy_controlled.ps1`
- Checklist oficial: `docs/firestore-deploy-checklist.md`
- Artefatos versionados em: `docs/deployments/firestore/<releaseVersion>/`

### O que o deploy controlado garante

- Snapshot versionado de `firestore.rules` e `firestore.indexes.json` a cada release.
- Registro de hash SHA256, projeto alvo, commit e status de validacao em `manifest.json`.
- Validacao obrigatoria (por padrao): `flutter test`.
- Validacao obrigatoria (por padrao): `npm run emulator:test:firestore`.
- Publicacao controlada com `firebase deploy --only firestore:rules,firestore:indexes`.

### Comandos base

- Validar sem publicar: `powershell -ExecutionPolicy Bypass -File scripts/firestore_deploy_controlled.ps1 -ProjectId <projectId> -SkipDeploy`
- Publicar: `powershell -ExecutionPolicy Bypass -File scripts/firestore_deploy_controlled.ps1 -ProjectId <projectId>`
