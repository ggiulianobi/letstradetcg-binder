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

GitHub Pages: Settings → Pages → branch `main`, pasta `/docs`.
Depois de publicar, adicionar a URL do Pages em
Supabase → Authentication → URL Configuration (Site URL e Redirect URLs).

## Estado atual / próximos passos

O MVP está completo e não testado em produção ainda. Pendências conhecidas:

1. Rodar o `schema.sql` no Supabase.
2. Ajustar os templates de e-mail pra `{{ .Token }}`.
3. Primeiro deploy no GitHub Pages e teste do fluxo completo
   (cadastro → OTP → criar binder → upload → link público).
4. Ideias não implementadas: editar carta já criada, reordenar cartas,
   página de perfil público do usuário listando todos os binders dele.
