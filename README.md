# GymPix

Aplicativo Flutter para gestão de alunos, cobranças via Pix e acompanhamento financeiro mensal.

## Principais recursos

- Cadastro e edição de alunos.
- Cobrança com link e QR Code Pix.
- Histórico mensal de pagamentos por aluno.
- Registro de pagamento com comprovante e observações.
- Dashboard com recebido, previsto, inadimplência e ticket médio.
- Exportação de relatório mensal em CSV e PDF.

## Configuração

1. Instale dependências:
   ```bash
   flutter pub get
   ```
2. Configure Firebase para as plataformas desejadas.
3. Defina a URL base de cobrança no build:
   ```bash
   flutter run --dart-define=COBRANCA_BASE_URL=https://seu-dominio.com
   ```

## Testes

```bash
flutter test
```

## Firestore Emulator Suite (regras e permissoes)

1. Instale dependencias Node para testes de regras:
   ```bash
   npm install
   ```
2. Rode os testes contra o Firestore Emulator (sem risco no banco real):
   ```bash
   npm run emulator:test:firestore
   ```
3. (Opcional) Suba somente o emulador Firestore e UI local:
   ```bash
   npm run emulator:start:firestore
   ```
4. Se o comando reclamar de `java` no Windows, aponte para o JBR do Android Studio:
   ```powershell
   $env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
   $env:Path="$env:JAVA_HOME\bin;$env:Path"
   npm run emulator:test:firestore
   ```

Cobertura de testes de regras:
- bootstrap (`tenants/{uid}`, `user_tenants/{uid}`, `config/{app|pix}`)
- leitura/escrita permitidas no proprio tenant
- bloqueios cross-tenant
- bloqueios de `delete` e `list` onde necessario
- cenarios de permissao por status ativo/inativo

## Deploy controlado de regras e indices

Checklist completo:
- `docs/firestore-deploy-checklist.md`

Fluxo rapido:

1. Validar localmente sem publicar:
   ```bash
   npm run deploy:firestore:validate -- -ProjectId <seu-project-id>
   ```
2. Publicar regras + indices com versionamento:
   ```bash
   npm run deploy:firestore -- -ProjectId <seu-project-id>
   ```
3. Artefatos versionados do release:
   - `docs/deployments/firestore/<releaseVersion>/firestore.rules`
   - `docs/deployments/firestore/<releaseVersion>/firestore.indexes.json`
   - `docs/deployments/firestore/<releaseVersion>/manifest.json`
   - `docs/deployments/firestore/<releaseVersion>/validation-checklist.md`

## Análise estática

```bash
flutter analyze
```
