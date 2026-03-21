# GymPix - Documentacao Completa para ChatGPT

## 1) Resumo do produto

GymPix e um app Flutter para gestao financeira de academia.
O foco e reduzir inadimplencia com cobranca padronizada (manual + automatizada), registrar historico por aluno e facilitar fechamento mensal.

## 2) Stack tecnica

- Flutter 3.41
- Dart 3.11
- State management: Riverpod 3 + riverpod_annotation
- Backend: Firebase Firestore
- Navegacao: go_router
- Compartilhamento: share_plus
- WhatsApp deep link: url_launcher
- QR Pix: qr_flutter
- Relatorios: pdf + CSV
- Notificacao local: flutter_local_notifications
- Internacionalizacao: intl

## 3) Estrutura geral de arquitetura

Padrao predominante por feature com separacao em camadas:
- `ui/`: telas e widgets
- `controllers/`: orquestracao de acoes
- `usecases/`: regras de negocio reutilizaveis
- `services/`: integracoes e logica especializada
- `repository/`: persistencia Firestore
- `providers/`: injeccao e estado (Riverpod)

Features principais:
- `features/home`: dashboard financeiro
- `features/alunos`: cadastro, status, pagamentos, acoes
- `features/cobranca`: Pix, templates, regua, automacao, rastreabilidade
- `features/configuracoes`: parametros do negocio
- `features/relatorios`: fechamento mensal e exportacoes

## 4) Rotas da aplicacao

Arquivo: `lib/core/router/app_router.dart`

- `/` -> HomePage
- `/alunos` -> AlunosPage
- `/config` -> ConfigPage
- `/cobranca?nome=...&pix=...&valor=...` -> CobrancaPage

## 5) Entidades de dominio (resumo)

### Aluno

Arquivo: `lib/features/alunos/models/aluno.dart`

Campos principais:
- `id`, `nome`, `telefone`, `observacao`
- `diaVencimento`, `mensalidade`
- `ativo`, `arquivadoEm`
- `pagamentos: Map<competencia, PagamentoMensal>`
- `pagoLegado` (compatibilidade)

Regras chave:
- `pagamentoDoMes()` gera status dinamico (pendente/atrasado/pago)
- vencimento e ajustado para ultimo dia valido do mes
- status atrasado so apos a data de vencimento efetiva

### PagamentoMensal

Campos:
- `competencia`, `valor`, `status`, `diaVencimento`
- `pagoEm`, `comprovanteUrl`, `observacao`

## 6) Firestore - modelo de dados

### 6.1 Colecao `alunos`

Documento por aluno com:
- dados cadastrais
- flags de ativo/arquivado
- `pagamentos.{YYYY-MM}` com snapshot mensal

Subcolecao por aluno:
- `alunos/{alunoId}/cobranca_envios`
- historico de envios manual/automatico

### 6.2 Colecao `config`

Documentos usados:
- `config/pix` -> `pixCode`
- `config/app` -> `defaultMensalidade`, `customCobrancaMessage`, `cobrancaRegua`

### 6.3 Colecao `fechamentos_mensais`

- documento por competencia (`YYYY-MM`)
- snapshot fechado do mes (totais + alunos)

### 6.4 Colecao `cobranca_push_queue`

- fila de eventos de envio automatico quando push estiver ativo
- uso esperado por worker/backend externo

## 7) Regua de cobranca (implementacao atual)

Arquivos:
- `lib/features/cobranca/models/cobranca_regua.dart`
- `lib/features/cobranca/services/cobranca_regua_planner.dart`
- `lib/features/cobranca/services/cobranca_regua_automation_service.dart`
- `lib/features/cobranca/repository/cobranca_regua_repository.dart`
- `lib/features/cobranca/providers/cobranca_regua_providers.dart`

Configuracao atual:
- passos relativos: D-3, D0, D+3
- templates por status:
  - pendente
  - atrasado
- flags:
  - automacao ativa
  - notificacao local ativa
  - notificacao push ativa (fila)

Variaveis suportadas no template:
- `{nome}`
- `{telefone}`
- `{competencia}`
- `{valor}`
- `{vencimento}`
- `{status}`
- `{dias_label}`
- `{pix}`
- `{link}`

Logica da automacao:
1. carrega configuracao da regua
2. seleciona alunos ativos com pagamento em aberto
3. calcula `diasRelativos = hoje - vencimento`
4. verifica se passo esta ativo
5. evita duplicidade por documento idempotente:
   - `auto_{competencia}_{offset}_{status}`
6. registra envio em `cobranca_envios`
7. dispara notificacao local (opcional)
8. enfileira push em `cobranca_push_queue` (opcional)

## 8) Cobranca manual e rastreabilidade

Arquivo: `lib/features/alunos/ui/widgets/aluno_card.dart`

Acoes manuais de cobranca:
- copiar mensagem
- compartilhar QR + mensagem
- WhatsApp deep link

Rastreabilidade implementada:
- copia manual registrada em `cobranca_envios`
- compartilhamento manual registrado em `cobranca_envios`
- painel por aluno com historico de envios

Painel por aluno:
- `lib/features/alunos/ui/widgets/aluno_cobranca_panel_sheet.dart`
- mostra:
  - status atual
  - passos da regua e datas
  - historico de envios com data/canal/status

## 9) Configuracoes de negocio

Arquivo: `lib/features/configuracoes/ui/config_page.dart`

O usuario configura:
- chave Pix
- mensalidade padrao
- frase personalizada de cobranca
- regua de cobranca (toggle + passos + templates + notificacoes)

## 10) Controle de concorrencia e confiabilidade

### Lock de operacoes criticas

Arquivos:
- `lib/core/utils/operation_lock.dart`
- `lib/features/alunos/controllers/alunos_actions_controller.dart`

Uso:
- operacoes criticas usam `operationId` para evitar execucao duplicada em paralelo

### UX de sincronizacao

- timeout otimista removido de writes criticas
- UI fica bloqueada ate conclusao real
- feedback de "sincronizando" quando operacao demora

## 11) Qualidade e testes

Comando:
- `flutter analyze` -> sem issues
- `flutter test` -> suite passando

Cobertura de testes inclui:
- regras de aluno/pagamento
- use cases de cobranca/pix
- lock de operacao
- planner da regua de cobranca
- widget test de inicializacao

## 12) Limitacoes atuais (importante)

1. Push nao e enviado diretamente do app:
   - hoje o app enfileira em `cobranca_push_queue`
   - precisa de worker/Cloud Function para enviar push real

2. Automacao depende do app estar em uso:
   - runner roda pelo provider observado na Home
   - para 24/7 em escala, mover agendamento para backend

3. Registro manual no historico:
   - copy/share ja registrados
   - se necessario, ampliar logs para todos os canais e resultados

## 13) Roadmap tecnico recomendado

1. Backend de push:
- Cloud Function consumindo `cobranca_push_queue`
- retry com backoff e DLQ

2. Agendamento 24/7:
- job diario server-side para processar regua
- app apenas exibe historico/estado

3. Analytics de conversao:
- taxa de pagamento por passo da regua
- tempo medio ate pagamento apos envio
- cohort por faixa de atraso

4. Auditoria e governanca:
- trilha completa de eventos
- regras de seguranca Firestore por perfil

## 14) Mapa de arquivos chave

- Core
  - `lib/main.dart`
  - `lib/core/router/app_router.dart`
  - `lib/core/providers/firebase_providers.dart`
  - `lib/core/utils/operation_lock.dart`

- Alunos
  - `lib/features/alunos/models/aluno.dart`
  - `lib/features/alunos/repository/alunos_repository.dart`
  - `lib/features/alunos/controllers/alunos_actions_controller.dart`
  - `lib/features/alunos/ui/alunos_page.dart`
  - `lib/features/alunos/ui/widgets/aluno_card.dart`
  - `lib/features/alunos/ui/widgets/aluno_cobranca_panel_sheet.dart`

- Cobranca
  - `lib/features/cobranca/models/cobranca_regua.dart`
  - `lib/features/cobranca/models/cobranca_envio.dart`
  - `lib/features/cobranca/repository/cobranca_regua_repository.dart`
  - `lib/features/cobranca/services/cobranca_regua_planner.dart`
  - `lib/features/cobranca/services/cobranca_regua_automation_service.dart`
  - `lib/features/cobranca/services/cobranca_notification_service.dart`
  - `lib/features/cobranca/services/cobranca_template_service.dart`
  - `lib/features/cobranca/services/pix_payload_service.dart`
  - `lib/features/cobranca/providers/cobranca_regua_providers.dart`

- Configuracoes
  - `lib/features/configuracoes/repository/config_repository.dart`
  - `lib/features/configuracoes/providers/config_providers.dart`
  - `lib/features/configuracoes/ui/config_page.dart`

- Relatorios
  - `lib/features/relatorios/models/competencia_report.dart`
  - `lib/features/relatorios/services/report_export_service.dart`
  - `lib/features/relatorios/repository/competencia_fechamento_repository.dart`
  - `lib/features/relatorios/services/competencia_fechamento_service.dart`

- Testes
  - `test/alunos_usecases_test.dart`
  - `test/aluno_pagamento_sync_test.dart`
  - `test/aluno_vencimento_test.dart`
  - `test/cobranca_regua_planner_test.dart`
  - `test/operation_lock_test.dart`
  - `test/widget_test.dart`

## 15) Prompt pronto para usar no ChatGPT

Copie e cole o texto abaixo no ChatGPT:

```text
Voce vai atuar como arquiteto e engenheiro Flutter senior no projeto GymPix.

Contexto:
- App Flutter para gestao de alunos e cobranca Pix.
- Stack: Flutter 3.41, Dart 3.11, Riverpod 3, Firestore, go_router, share_plus.
- Possui regua de cobranca automatizada (D-3, D0, D+3), templates por status e historico de envios por aluno.
- Push atualmente e enfileirado em Firestore (cobranca_push_queue), sem worker de envio implementado.
- Automacao hoje roda no app (Home) via provider.

Objetivos da sua resposta:
1) Revisar arquitetura atual e apontar riscos tecnicos e de escala.
2) Propor evolucao para automacao 24/7 server-side.
3) Propor desenho de Cloud Functions para processar cobranca_push_queue.
4) Definir estrategia de idempotencia, retries e monitoramento.
5) Sugerir indicadores de negocio para medir conversao de cobranca.
6) Entregar plano de implementacao em fases (rapida, intermediaria, robusta).

Requisitos:
- Responda em portugues.
- Inclua exemplos de estrutura de colecoes Firestore e payload.
- Inclua exemplos de regras de seguranca e observabilidade.
- Priorize impacto real em reducao de inadimplencia.
```

