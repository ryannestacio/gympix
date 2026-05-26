# Passo a Passo Manual - Novo Usuario (Firebase)

Objetivo: criar um login novo e liberar acesso ao app sem depender do seed automatico.

Projeto Firebase deste app: `gympixapp`

## 1. Criar usuario no Authentication

1. Abra Firebase Console.
2. Selecione o projeto `gympixapp`.
3. Va em `Authentication` > `Users`.
4. Clique em `Add user`.
5. Informe email e senha do cliente.
6. Salve.

## 2. Copiar o UID do usuario

1. Ainda em `Authentication` > `Users`, abra o usuario criado.
2. Copie o `UID`.
3. Guarde tambem o email.

Neste guia vamos chamar esse valor de `<UID>`.

## 3. Criar documentos no Firestore (manual)

Abra `Firestore Database` > `Data` e crie os documentos abaixo.

### 3.1 Documento `user_tenants/<UID>`

Caminho:
- `user_tenants` (collection)
- `<UID>` (document id)

Campos:
- `tenantId` (string): `<UID>`
- `role` (string): `owner`
- `status` (string): `ativo`
- `ativo` (boolean): `true`
- `email` (string): email do cliente em minusculo
- `nome` (string): nome do cliente
- `createdAt` (timestamp): server timestamp
- `updatedAt` (timestamp): server timestamp

### 3.2 Documento `tenants/<UID>`

Caminho:
- `tenants` (collection)
- `<UID>` (document id)

Campos:
- `tenantId` (string): `<UID>`
- `nome` (string): ex. `Academia Cliente`
- `status` (string): `ativo`
- `ativo` (boolean): `true`
- `createdAt` (timestamp): server timestamp
- `updatedAt` (timestamp): server timestamp

### 3.3 Documento `tenants/<UID>/config/app`

Caminho:
- `tenants/<UID>/config` (subcollection)
- `app` (document id)

Campos:
- `tenantId` (string): `<UID>`
- `docType` (string): `app_config`
- `status` (string): `ativo`
- `ativo` (boolean): `true`
- `createdAt` (timestamp): server timestamp
- `updatedAt` (timestamp): server timestamp

### 3.4 Documento `tenants/<UID>/config/pix`

Caminho:
- `tenants/<UID>/config` (subcollection)
- `pix` (document id)

Campos:
- `tenantId` (string): `<UID>`
- `docType` (string): `pix_config`
- `status` (string): `ativo`
- `ativo` (boolean): `true`
- `createdAt` (timestamp): server timestamp
- `updatedAt` (timestamp): server timestamp

## 4. Teste final no celular do cliente

1. No app, toque em `Sair da conta`.
2. Entre novamente com email/senha do cliente.
3. O app deve abrir sem a tela `Acesso negado`.

## 5. Se ainda aparecer "Acesso negado"

Checklist rapido:

1. Confirmar que o app esta no projeto `gympixapp` (nao `demo-gympix`).
2. Confirmar que os 4 documentos acima existem exatamente com os ids corretos.
3. Confirmar que `tenantId` e igual ao `<UID>` em todos os documentos.
4. Confirmar `ativo=true` e `status=ativo` em `user_tenants/<UID>` e `tenants/<UID>`.
5. Confirmar que as regras atuais de `firestore.rules` estao publicadas no projeto `gympixapp`.

## 6. Observacao importante

Este fluxo cria um tenant novo (base separada) para esse usuario.
Se voce quiser que ele entre na MESMA base de outro tenant, o `tenantId` precisa apontar para o tenant compartilhado e o documento `user_tenants/<UID>` deve ser montado para esse tenant.

## 7. Criar usuarios "funcionarios" (mesmo tenant da academia)

Use esta secao quando o novo usuario deve acessar a MESMA base de dados do dono da academia.

### 7.1 Descobrir o tenant principal (UID do dono)

1. Abra `user_tenants`.
2. Encontre o documento do dono da academia.
3. Copie o valor de `tenantId` desse dono (geralmente e o UID do dono).

Neste guia vamos chamar esse valor de `<TENANT_PRINCIPAL>`.

### 7.2 Criar login do funcionario no Authentication

1. Abra `Authentication` > `Users`.
2. Clique em `Add user`.
3. Crie email/senha do funcionario.
4. Copie o UID desse funcionario.

Neste guia vamos chamar esse valor de `<UID_FUNCIONARIO>`.

### 7.3 Criar documento do funcionario em `user_tenants`

Caminho:
- `user_tenants/<UID_FUNCIONARIO>`

Campos:
- `tenantId` (string): `<TENANT_PRINCIPAL>`
- `role` (string): `staff` (ou `admin` se quiser permissao de gestao)
- `status` (string): `ativo`
- `ativo` (boolean): `true`
- `email` (string): email do funcionario em minusculo
- `nome` (string): nome do funcionario
- `createdAt` (timestamp): server timestamp
- `updatedAt` (timestamp): server timestamp

## 8. O que NAO criar para funcionario

Para funcionario, nao crie:

1. `tenants/<UID_FUNCIONARIO>`
2. `tenants/<UID_FUNCIONARIO>/config/app`
3. `tenants/<UID_FUNCIONARIO>/config/pix`

Esses documentos sao so para quem tera tenant proprio.
Funcionario deve apontar para o tenant existente em `tenantId`.

## 9. Teste do funcionario

1. No app do funcionario: entrar com email/senha dele.
2. Validar se abre a mesma base da academia (mesmos alunos/config do tenant principal).
3. Se aparecer `Acesso negado`, revisar:
4. O `tenantId` do funcionario esta exatamente igual a `<TENANT_PRINCIPAL>`.
5. O documento `tenants/<TENANT_PRINCIPAL>` existe e esta ativo.
6. `status=ativo` e `ativo=true` no `user_tenants/<UID_FUNCIONARIO>`.

## 10. Bloquear ou reativar funcionario

Para bloquear sem apagar usuario do Auth:

1. Abra `user_tenants/<UID_FUNCIONARIO>`.
2. Troque `ativo` para `false`.
3. Troque `status` para `inativo`.

Para reativar:

1. Volte `ativo` para `true`.
2. Volte `status` para `ativo`.
