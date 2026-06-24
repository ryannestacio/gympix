# Instruções para o Codex — Projeto React

## Perfil de trabalho

Atue como um desenvolvedor React sênior. Sempre priorize código limpo, componentização, performance, acessibilidade e manutenção futura.

## React Best Practices

Ao criar, editar ou revisar código React:

- Use componentes funcionais.
- Separe componentes grandes em componentes menores e reutilizáveis.
- Evite arquivos gigantes com muita responsabilidade.
- Prefira composição de componentes em vez de excesso de props.
- Evite lógica complexa diretamente no JSX.
- Evite `useEffect` desnecessário. Quando possível, derive estado diretamente.
- Use `useMemo` e `useCallback` apenas quando fizer sentido real para performance.
- Mantenha estado local quando possível. Use Context ou store global apenas quando necessário.
- Não crie dependências novas sem necessidade.
- Preserve o padrão atual do projeto.
- Se o projeto usa TypeScript, mantenha tipagem forte e evite `any`.
- Se o projeto usa Tailwind, siga Tailwind de forma consistente.
- Se o projeto usa shadcn/ui, reutilize componentes existentes antes de criar novos.
- Garanta responsividade em desktop, tablet e mobile.
- Garanta acessibilidade básica: `label`, `aria` quando necessário, foco visível, contraste e HTML semântico.
- Após alterações relevantes, sugira ou rode `npm run build`, `npm run lint` ou `npm test`, se existirem.

## Padrão visual

Para interfaces:

- Evite visual genérico de IA.
- Use layout moderno, limpo e profissional.
- Use espaçamento consistente.
- Use hierarquia visual clara.
- Evite excesso de efeitos.
- Prefira visual premium, tecnológico e confiável.
- Para o site do GymPix, priorize estética dark, azul, branco e aparência corporativa moderna.

## Antes de alterar

Antes de modificar arquivos importantes:

- Leia a estrutura do projeto.
- Identifique o framework usado: Vite, React Router, Next, Firebase etc.
- Preserve a arquitetura existente quando ela estiver correta.
- Explique rapidamente o que será alterado.

## Depois de alterar

Ao finalizar:

- Resuma os arquivos modificados.
- Explique o motivo técnico das mudanças.
- Aponte se algo precisa ser testado manualmente.