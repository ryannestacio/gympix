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

## Análise estática

```bash
flutter analyze
```

"# gympix" 
