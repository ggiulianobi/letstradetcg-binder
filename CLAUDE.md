# LetsTradeTCG Binder — contexto do projeto

Fale em **português do Brasil** com o usuário.

## O que é

Plataforma de "pastas digitais" (binders) de cartas Pokémon TCG. Qualquer
pessoa se cadastra, cria quantos binders quiser, sobe fotos das cartas com
estado/preço/troca-venda, e recebe um link público pra compartilhar em
grupos de venda no WhatsApp.

Este é o **V2**. Existe um MVP anterior no GitLab
(`gitlab.com/ggiuliano-group/pokemontcg`) que é uma página estática simples
com fotos fixas — **não mexer nele**, está em produção e serve de vitrine.

## Stack e restrições

- Site **100% estático** (HTML/CSS/JS puro, sem build step, sem framework).
- Hospedagem: **GitHub Pages** servindo a pasta `docs/`.
- Backend: **Supabase** (auth, Postgres, storage) chamado direto do navegador.
- Sem Node/npm no projeto — nada de bundler. Bibliotecas entram por CDN.

Manter essa simplicidade é intencional: o dono do projeto quer poder editar
arquivos soltos e dar push sem pipeline de build.

## Supabase

- Projeto: `letstradetcg_binder` / id `urxsxhamyrzswknfdlbe`
- URL: `https://urxsxhamyrzswknfdlbe.supabase.co`
- No frontend usa-se **apenas a publishable key** (já em `docs/assets/supabase-config.js`).
- **NUNCA** colocar a secret key em nenhum arquivo do repositório.
- Schema completo em `supabase/schema.sql` (roda uma vez no SQL Editor).
  Tabelas: `profiles`, `binders`, `cards` + função `increment_binder_views`
  + bucket `cards`. Todas com RLS: cada usuário só escreve no que é dele,
  leitura é pública.

Autenticação usa **OTP numérico** (não link mágico), tanto no cadastro
quanto no reset de senha. O comprimento do código é o que o Supabase gerar
(pode variar, não fixo em 6 — o campo no front aceita 4 a 10 dígitos). Isso
exige que os templates de e-mail (Authentication → Emails) usem
`{{ .Token }}` em vez do link, e que o **Custom SMTP** esteja configurado
(o Supabase bloqueia edição de template sem SMTP próprio). SMTP em uso:
**Resend**, domínio `letstradetcg.com.br` verificado lá.

## Estrutura

```
docs/                     <- publicado pelo GitHub Pages
├── index.html            Homepage: boas-vindas, login, carrossel, diretório completo, busca
├── register.html         Cadastro + OTP
├── reset-password.html   E-mail → OTP → nova senha
├── dashboard.html        Painel: binders, upload, "Criar folha"
├── binder.html?b=<id>    Binder público
└── assets/
    ├── holo.css          Todo o CSS do projeto (compartilhado)
    ├── supabase-config.js
    ├── states-br.js
    ├── image-utils.js    Compressão + conversão HEIC
    └── favicon.svg        Ícone genérico (2 cartas, gradiente holo) — sem mascote ainda
supabase/schema.sql
```

## Regras de produto já definidas

- **Senha:** mínimo 8 caracteres, com ao menos 1 maiúscula, 1 número e 1
  caractere especial. Validado no cadastro e no reset.
- **Cadastro:** nome (≤120), data de nascimento (calendário), e-mail (≤120),
  apelido único (≤30, usado na busca), estado (dropdown UF), WhatsApp.
- **Estado da carta:** dropdown fixo `M, NM, SP, MP, HP, DM`
  (constante `CONDITIONS` em `supabase-config.js`).
- **Preço** em BRL (campo texto livre) + checkbox de **Troca** e de **Venda**
  (independentes, pode marcar os dois).
- **Upload:** aceita JPG, PNG, AVIF, HEIC. A imagem é comprimida no
  navegador antes de subir: lado maior redimensionado pra ~2200px, JPEG 82%.
  O mínimo de 2000px é requisito do produto (o zoom precisa ficar nítido) —
  não reduzir abaixo disso.
- **Carrossel da home:** binders mais visitados, troca a cada 2 segundos,
  clicável.
- Textos da interface em português.

## Estilo visual

Tema escuro com efeito "holo/foil" (gradientes animados roxo → ciano →
rosa → amarelo), fontes Space Grotesk (títulos) e Inter (texto). Todo o CSS
vive em `docs/assets/holo.css` usando as variáveis CSS do `:root` — usar
essas variáveis em vez de cores soltas.

## Deploy

- Repositório: **github.com/ggiulianobi/letstradetcg-binder** (público).
- GitHub Pages: branch `main`, pasta `/docs`, ativado via API (`gh api`).
- Domínio: **letstradetcg.com.br** (registrado na GoDaddy). DNS: 4 registros
  `A` em `@` pros IPs do GitHub Pages (185.199.108/109/110/111.153) +
  `CNAME www` → `ggiulianobi.github.io`. Arquivo `docs/CNAME` no repo
  guarda o domínio pro GitHub Pages reconhecer.
- Certificado HTTPS do domínio custom é emitido automaticamente pelo
  GitHub (Let's Encrypt) depois que o DNS verifica — não precisa fazer
  nada, só esperar propagar.
- Supabase → Authentication → URL Configuration: Site URL e Redirect URLs
  já apontando pra `https://letstradetcg.com.br`.
- E-mail transacional: **Resend** (domínio `letstradetcg.com.br` verificado
  lá) configurado como Custom SMTP em Supabase → Authentication → Emails →
  SMTP Settings. Isso é **obrigatório**: o Supabase bloqueia a edição do
  conteúdo dos templates de e-mail (botão "Source") até ter um SMTP
  próprio configurado — não dá pra só trocar pra `{{ .Token }}` sem isso.

## Estado atual / próximos passos

**MVP em produção desde 2026-08-02**: cadastro → OTP por e-mail → criar
binder → funcionando. Site publicado e domínio próprio no ar.

Rodada de 9 melhorias de design/UX levantadas pelo dono, sendo entregues
**fase por fase** (ele testa no site entre cada fase antes de eu seguir
pra próxima). Progresso:

- ✅ **Fase 0** (schema): tabelas `card_items` e `trade_requests` +
  função `complete_trade_request` adicionadas em `supabase/schema.sql`
  (bloco no fim do arquivo, idempotente). **Ainda precisa ser rodado
  manualmente no SQL Editor do Supabase** — só esse bloco novo, não o
  arquivo inteiro (as tabelas antigas já existem e têm dado real).
- ✅ **Fase 1** (ajustes rápidos): botão de apagar carta não sobrepõe
  mais o preço (`holo.css`); removido o redirect forçado da home pra
  quem já está logado (agora mostra um atalho "Ir para meu painel" em
  vez de chutar o usuário pra `dashboard.html` — isso também resolvia a
  reclamação de "não consigo sair do dashboard"); marca "LetsTradeTCG
  Binder" virou link clicável em `.navbar`, presente em todas as
  páginas incluindo `binder.html` (que antes não tinha nenhum header de
  marca); home ganhou um diretório completo de binders (grid abaixo do
  carrossel/busca, não só top 10); favicon genérico criado
  (`assets/favicon.svg`, 2 cartas com gradiente holo — **não é a
  mascote "Leya"**, isso ficou de fora por não ter ferramenta de geração
  de imagem nesse ambiente; trocar por arte de verdade é troca de 1
  linha de `<link>` quando tiver a arte pronta).
- ⏳ **Fase 2** (pendente): classificação dinâmica por foto — uma foto
  pode conter várias cartas, cada uma com sua própria linha de
  condição/preço/troca-venda/observação (usa `card_items`). Grid mostra
  contador `N×` quando tem mais de 1 item; lightbox ganha painel de
  texto com o detalhe de cada linha.
- ⏳ **Fase 3** (pendente): botão "Let's Trade!" no binder público
  (visitante logado manda pedido de interesse pro dono, com link do
  próprio binder dele); painel de notificações no dashboard; checkbox
  "troca feita" (RPC `complete_trade_request`, fecha no primeiro clique
  de qualquer um dos lados).
- ⏳ **Fase 4** (pendente): link amigável `letstradetcg.com.br/<apelido>`
  via `docs/404.html` (GitHub Pages serve esse arquivo pra path
  desconhecido sem mudar a URL) — vira a página de perfil público
  listando os binders do usuário + contador de trocas concluídas;
  bloquear apelidos reservados (`index, register, reset-password,
  dashboard, binder, 404, cname, favicon`) no cadastro.

Plano detalhado (schema exato, decisões de RLS, UX do grid multi-item
etc.) está documentado nesta sessão — se uma sessão futura for continuar
a partir daqui e quiser o raciocínio completo por trás de cada fase, é
só perguntar, mas os pontos essenciais já estão resumidos acima.

## Histórico de sessões

> Convenção: a cada sessão de trabalho relevante, adicionar uma entrada
> aqui (data + resumo do que foi feito/decidido/aprendido). É assim que
> o contexto passa de uma janela de conversa pra outra.

**2026-08-02 — Deploy inicial e primeiro cadastro funcionando**
- Pasta do projeto estava com ACL do Windows travada pra escrita (só
  Administradores); corrigido com `icacls ... /grant usuario:(OI)(CI)F`
  rodado em PowerShell elevado. Se voltar a acontecer, é isso.
- `gh` CLI instalado via winget (não vinha no ambiente) e autenticado via
  `gh auth login --web` (device code flow).
- Repo git criado do zero, primeiro commit, push pra
  `ggiulianobi/letstradetcg-binder`, GitHub Pages ativado via `gh api`.
- Domínio `letstradetcg.com.br` comprado na GoDaddy; DNS configurado
  (A records + CNAME www) apontando pro GitHub Pages.
- Descoberto que o Supabase **não deixa editar templates de e-mail sem
  Custom SMTP configurado** (trava o botão "Source"). Resolvido
  configurando Resend como SMTP.
- Armadilha: `signUp()` do Supabase não reenvia e-mail nem dá erro se o
  e-mail já existe no sistema (evita enumeration attack) — durante os
  testes isso pareceu "e-mail não enviado" quando na verdade era reuso
  do mesmo e-mail de teste anterior. Usar e-mail novo (ou apagar o
  usuário em Authentication → Users) pra re-testar cadastro do zero.
- O comprimento do código OTP gerado pelo Supabase **não é fixo em 6**
  (veio 8 no teste real) — front-end ajustado pra aceitar 4-10 dígitos
  em vez de travar em 6.
- A tabela `profiles` real no banco estava com um schema antigo/quebrado
  (colunas `username`/`display_name` em vez de `full_name`/`nickname`,
  `birthdate` sem tipo — erro de sintaxe, faltava tabela `binders`
  inteira). Dropado e recriado do zero com o `schema.sql` correto do
  repo — pendente antigo do projeto que nunca tinha sido de fato
  aplicado no banco.

**2026-08-02 — Rodada de melhorias de design/UX, Fase 1 de 5**
- Dono levantou 9 pedidos testando o site de verdade (favicon/mascote,
  bug visual do botão de apagar em cima do preço, classificação
  dinâmica multi-carta por foto, header/navegação consistente, feature
  "Let's Trade!" de notificação de interesse em troca, link amigável
  por apelido, metadados no lightbox, contador de trocas concluídas,
  bug de não conseguir sair do dashboard). Planejado em fases
  (Fase 0 = schema, Fases 1-4 = features), entrega com pausa pro dono
  testar entre cada fase — plano completo ficou salvo localmente em
  `C:\Users\giuli\.claude\plans\lazy-skipping-moler.md` na máquina do
  dono (fora do repo).
- Decisão de design pro pedido de troca: **um clique fecha a troca pros
  dois lados** (não exige confirmação mútua) — e a conclusão passa por
  uma função `security definer` (`complete_trade_request`), não por uma
  policy de UPDATE direta, porque RLS não consegue restringir só uma
  coluna por linha (mesmo padrão já usado em `increment_binder_views`).
- Decisão pro link amigável: usar `docs/404.html` como truque padrão de
  roteamento em GitHub Pages estático — GH Pages serve esse arquivo (URL
  não muda) pra qualquer path sem arquivo real correspondente, então ele
  vira a implementação da página de perfil público por apelido.
- Mascote "Leya" ficou de fora dessa rodada (sem ferramenta de geração
  de imagem no ambiente) — o dono topou seguir só com favicon genérico
  por enquanto.
- Fase 1 implementada e no ar: ver resumo em "Estado atual" acima.
