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
├── index.html            Homepage: boas-vindas, login, carrossel, busca
├── register.html         Cadastro + OTP
├── reset-password.html   E-mail → OTP → nova senha
├── dashboard.html        Painel: binders, upload, "Criar folha"
├── binder.html?b=<id>    Binder público
└── assets/
    ├── holo.css          Todo o CSS do projeto (compartilhado)
    ├── supabase-config.js
    ├── states-br.js
    └── image-utils.js    Compressão + conversão HEIC
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

**MVP em produção, testado de ponta a ponta em 2026-08-02**: cadastro →
OTP por e-mail → criar binder → funcionando. Site publicado e domínio
próprio no ar.

Pendências conhecidas:

1. Ideias não implementadas: editar carta já criada, reordenar cartas,
   página de perfil público do usuário listando todos os binders dele.
2. Melhorias de UX/layout/imagens — usuário vai trazer uma lista na
   próxima sessão.

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
