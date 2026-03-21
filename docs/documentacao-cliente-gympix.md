# GymPix - Documentacao para Cliente

Versao: 1.0.0  
Data: 20/03/2026  
Publico: clientes, gestores e parceiros da academia

## 1. Visao Geral

O GymPix e um aplicativo mobile para gestao de alunos, controle de mensalidades e cobranca com Pix.
O objetivo principal e padronizar o processo financeiro da academia, reduzir atrasos e melhorar a previsibilidade de caixa.

Com o app, o gestor consegue:
- cadastrar e manter alunos ativos/inativos
- acompanhar pagamentos por competencia mensal
- enviar cobrancas com Pix de forma manual ou automatizada
- registrar historico de envios por aluno
- exportar relatorios em CSV e PDF

## 2. Problemas Que o App Resolve

Antes do GymPix, e comum encontrar:
- cobranca sem padrao (cada atendente envia de um jeito)
- falta de historico de quem foi cobrado e quando
- atraso para agir em inadimplencia
- dificuldade para fechar o mes e consolidar numeros

Com o GymPix:
- o processo fica padronizado
- os envios ficam rastreaveis
- o acompanhamento financeiro fica em um painel unico
- o fechamento mensal fica mais rapido

## 3. Principais Funcionalidades

### 3.1 Home Financeira

Painel com indicadores do mes:
- recebido
- previsto
- pendentes
- atrasados
- inadimplencia percentual
- vencimentos proximos

Tambem permite exportar relatorios mensais em CSV e PDF.

### 3.2 Gestao de Alunos

Cadastro completo do aluno com:
- nome
- telefone
- observacoes
- dia de vencimento
- valor da mensalidade

Acoes disponiveis:
- editar cadastro
- duplicar cadastro
- ativar/inativar aluno
- marcar pagamento ou desfazer pagamento
- ver historico mensal de pagamentos

### 3.3 Cobranca Manual com Pix

Para cada aluno, o app permite:
- gerar QR Code Pix
- copiar Pix copia e cola
- compartilhar cobranca (imagem + mensagem)
- abrir WhatsApp com atalho

### 3.4 Regua de Cobranca Automatizada

A regua permite configurar envios por dias relativos ao vencimento:
- D-3 (3 dias antes)
- D0 (no dia do vencimento)
- D+3 (3 dias apos vencimento, se ainda em aberto)

Configuracoes da regua:
- ativar/desativar automacao
- selecionar passos ativos (D-3, D0, D+3)
- template para status pendente
- template para status atrasado
- notificacao local no aparelho
- fila para push (integracao com backend)

### 3.5 Rastreabilidade por Aluno

Cada aluno possui um painel de cobranca com:
- passos da regua configurados
- historico de envios (manual e automatico)
- data/hora do envio
- canal utilizado
- status da cobranca no momento do envio

Isso facilita auditoria, acompanhamento de processo e treinamento da equipe.

### 3.6 Configuracoes de Negocio

A tela de configuracoes centraliza:
- chave Pix da empresa
- mensalidade padrao sugerida
- frase personalizada de cobranca
- configuracoes da regua automatizada

## 4. Como Funciona na Pratica (Fluxo Recomendado)

1. Configure a chave Pix em Configuracoes.
2. Defina valor padrao e templates da regua.
3. Cadastre os alunos com dia de vencimento e mensalidade.
4. Acompanhe indicadores na Home.
5. Use cobranca manual quando necessario.
6. Utilize a regua para padronizar os lembretes.
7. Consulte o painel de cobranca do aluno para rastrear envios.
8. Exporte relatorios no fechamento mensal.

## 5. Regua de Cobranca - Explicacao para Usuario Comum

Em termos simples, a regua e um lembrete automatico:
- antes do vencimento: o aluno recebe aviso antecipado
- no vencimento: recebe o lembrete principal
- apos vencimento: recebe cobranca de atraso

Voce escolhe os dias, o texto e os canais.
O app registra tudo para voce saber exatamente o que foi enviado.

## 6. Beneficios Esperados para o Cliente

- aumento da conversao de pagamento no prazo
- reducao da inadimplencia recorrente
- menor dependencia de cobranca manual
- padronizacao da comunicacao com alunos
- mais transparencia e controle de operacao
- fechamento mensal mais rapido e confiavel

## 7. Requisitos de Uso

- smartphone com Android/iOS compativel com Flutter
- conexao com internet para sincronizacao com Firestore
- Firebase configurado no projeto
- permissao de notificacao local (quando habilitada)

## 8. Dados e Seguranca

- os dados de alunos e cobrancas sao armazenados no Firestore
- o controle de acesso e regras de seguranca dependem da configuracao do Firebase
- recomendacao: manter rotina de revisao de regras e backup exportado (CSV/PDF)

## 9. Limites Atuais (Importante)

- notificacao push depende de processamento externo (fila + worker/backend)
- a automacao e executada pelo app durante o uso normal do sistema
- para push em escala e automacao 24/7, recomenda-se Cloud Functions/worker dedicado

## 10. FAQ Rapido

### O app envia cobranca sozinho?
Sim, com a regua ativa e passos configurados.

### Posso personalizar a mensagem?
Sim. Existem templates para pendente e atrasado com variaveis dinamicas.

### Consigo saber se uma cobranca foi enviada?
Sim. Cada aluno possui historico de envios no painel de cobranca.

### Posso continuar cobrando manualmente?
Sim. O fluxo manual continua disponivel e tambem fica registrado no historico.

## 11. Indicadores de Sucesso Sugeridos

Para medir resultado com cliente final:
- taxa de pagamento ate D0
- taxa de recuperacao entre D+1 e D+7
- percentual de alunos em atraso por mes
- tempo medio de fechamento mensal
- volume de cobrancas manuais vs automaticas

## 12. Proximos Passos Recomendados

- habilitar worker de push para disparo automatico em escala
- criar painel gerencial consolidado de performance da regua
- adicionar campanhas segmentadas por faixa de atraso
- incluir trilha de comunicacao multicanal (WhatsApp, push, email)

---

Se quiser, eu posso gerar uma segunda versao desta documentacao:
- formato executivo (1 pagina)
- formato comercial para proposta
- formato operacao (manual da equipe)
