# Plano de Implementação - Portal do Aluno (Matrícula & Senha)

Este plano detalha a arquitetura e as modificações necessárias para criar o **Portal do Aluno** na web (`gympix.web.app/portal`) e no aplicativo móvel. O aluno poderá efetuar login usando sua **Matrícula** e uma **Senha** cadastrada, tendo acesso a um painel simples e dinâmico contendo seu status de pagamento atual, histórico de mensalidades e atalho de pagamento Pix (Copia e Cola + QR Code) para quitar as pendências.

---

## User Review Required

> [!IMPORTANT]
> **Definição da Senha do Aluno**: No formulário de cadastro de aluno, adicionaremos um campo "Senha do Aluno". Para simplificar para o dono da academia, se ele deixar em branco ao criar um novo aluno, o sistema definirá automaticamente uma senha padrão inicial (por exemplo, os **4 primeiros dígitos do telefone** ou a própria **matrícula**).

---

## Open Questions

> [!NOTE]
> 1. **Senha Padrão Inicial**: Você prefere que a senha inicial gerada automaticamente (caso o dono não digite nenhuma) seja a própria **Matrícula** do aluno, ou os **4 primeiros dígitos do telefone**?
> 2. **Nome da Rota**: O endereço `/portal` é adequado para a URL de acesso do aluno? (Ficaria: `gympix.web.app/portal`).

---

## Proposed Changes

### [Novo Recurso] Portal do Aluno

---

#### [MODIFY] [aluno.dart](file:///c:/Users/Ryan%20Estacio/Projetos/Flutter/gympix/lib/features/alunos/models/aluno.dart)
* Adicionar o campo `String? senha` no modelo `Aluno`.
* Atualizar o mapeamento `fromMap` e `toMap` para serializar e desserializar a senha no Firestore.

#### [MODIFY] [aluno_form_sheet.dart](file:///c:/Users/Ryan%20Estacio/Projetos/Flutter/gympix/lib/features/alunos/ui/aluno_form_sheet.dart)
* Adicionar um campo de entrada de texto para a "Senha de Acesso" no formulário de criação/edição de alunos.
* Adicionar a lógica de geração de senha padrão caso o campo seja deixado vazio na criação.

#### [MODIFY] [app_router.dart](file:///c:/Users/Ryan%20Estacio/Projetos/Flutter/gympix/lib/core/router/app_router.dart)
* Classificar as rotas que começam com `/portal` como **públicas** para contornar o Session Gate administrativo do dono da academia.
* Adicionar as rotas:
  - `/portal` (Tela de Login do Aluno)
  - `/portal/painel` (Painel Exclusivo do Aluno)

#### [NEW] [portal_auth_provider.dart](file:///c:/Users/Ryan%20Estacio/Projetos/Flutter/gympix/lib/features/portal_aluno/providers/portal_auth_provider.dart)
* Criar um Riverpod StateNotifier para gerenciar a sessão ativa do aluno logado (verificando matrícula e senha no Firestore e mantendo o estado de autenticação em memória ou SharedPreferences).

#### [NEW] [portal_login_page.dart](file:///c:/Users/Ryan%20Estacio/Projetos/Flutter/gympix/lib/features/portal_aluno/ui/portal_login_page.dart)
* Criar a tela de login exclusiva do aluno com visual corporativo moderno (estética dark/azul).
* Permitir preenchimento automático de matrícula através de parâmetros de URL (ex: `gympix.web.app/portal?matricula=1005`).

#### [NEW] [portal_painel_page.dart](file:///c:/Users/Ryan%20Estacio/Projetos/Flutter/gympix/lib/features/portal_aluno/ui/portal_painel_page.dart)
* Criar o painel simplificado do aluno logado:
  - Exibir status da mensalidade atual (Pago, Pendente, Atrasado).
  - Listagem do histórico de pagamentos passados com data de quitação.
  - Se houver pendência/atraso, exibir bloco de pagamento contendo:
    * Chave Pix da academia.
    * QR Code dinâmico do valor correspondente.
    * Botão de cópia rápida para o código "Copia e Cola" Pix.
  - Botão de logout (sair do portal).

---

## Verification Plan

### Automated Tests
- Criar casos de testes unitários para a rotina de validação e login do aluno no `PortalAuthProvider`.
- Testar a serialização/desserialização do campo de senha no `Aluno` modelo.

### Manual Verification
1. Abrir a rota `/portal` no navegador e tentar logar com uma matrícula inexistente (deve exibir erro).
2. Logar com matrícula válida e senha incorreta (deve exibir erro).
3. Logar com matrícula e senha corretas (deve redirecionar para a tela de painel do aluno).
4. No painel, verificar se apenas as informações daquele aluno específico são exibidas.
5. Copiar o Pix e testar a leitura do QR Code na tela.
6. Clicar em "Sair" e confirmar que o aluno foi deslogado e não consegue acessar `/portal/painel` diretamente sem efetuar o login novamente.
