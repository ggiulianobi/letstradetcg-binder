# LetsTradeTCG Binder — V2

Plataforma de pastas digitais (binders) de cartas Pokémon TCG. Qualquer
pessoa se cadastra, cria quantos binders quiser, sobe as fotos das cartas
com estado/preço/troca-venda, e ganha um link público pra mandar nos grupos
de WhatsApp.

Site 100% estático (GitHub Pages) + Supabase (login, banco e imagens).

## Estrutura

```
letstradetcg-binder/
├── docs/                      <- pasta publicada pelo GitHub Pages
│   ├── index.html             Homepage: boas-vindas, login, carrossel, busca
│   ├── register.html          Cadastro + código de 6 dígitos por e-mail
│   ├── reset-password.html    Recuperação de senha (código + nova senha)
│   ├── dashboard.html         Painel: binders, upload, "Criar folha"
│   ├── binder.html?b=<id>     Binder público (link de compartilhamento)
│   └── assets/
│       ├── holo.css           Visual holo/foil compartilhado
│       ├── supabase-config.js Credenciais (já preenchidas)
│       ├── states-br.js       Lista de estados do Brasil
│       └── image-utils.js     Compressão + conversão HEIC
├── supabase/schema.sql        Rodar 1x no SQL Editor do Supabase
└── README.md
```

## Setup — 3 passos

### 1) Banco de dados
No Supabase (projeto `letstradetcg_binder`) → **SQL Editor → New query** →
cole todo o conteúdo de `supabase/schema.sql` → **Run**.

Cria: `profiles`, `binders`, `cards`, contador de visitas, bucket `cards`
e todas as regras de segurança (cada usuário só mexe no que é dele).

### 2) Ativar código de 6 dígitos (OTP) no lugar de link
Supabase → **Authentication → Emails** → nos templates **Confirm signup** e
**Reset password**, troque o link por `{{ .Token }}`. Exemplo:

```
Seu código de verificação é: {{ .Token }}
```

Sem isso o e-mail chega com link em vez de código.

### 3) Subir pro GitHub e ligar o Pages

```bash
cd C:\Users\github
git clone https://github.com/letstradetcgbinder/<nome-do-repo>.git
# copie o conteúdo deste projeto para dentro da pasta clonada
cd <nome-do-repo>
git add .
git commit -m "MVP V2: cadastro, login, binders e upload"
git push origin main
```

No GitHub: **Settings → Pages → Source: Deploy from a branch →
Branch: main / pasta: /docs → Save**.

Em ~1 minuto o site fica em:
`https://letstradetcgbinder.github.io/<nome-do-repo>/`

### 4) Autorizar o domínio no Supabase
Supabase → **Authentication → URL Configuration** → adicione a URL do
GitHub Pages em **Site URL** e em **Redirect URLs**.

## Como funciona

- **Homepage** — texto de boas-vindas, login, links de "esqueci a senha" e
  "sou novo aqui", carrossel dos binders mais visitados (troca a cada 2s,
  clicável) e busca por nome de binder.
- **Registro** — nome (120), data de nascimento (calendário), e-mail (120),
  apelido (30, único), estado (dropdown UF), WhatsApp e senha
  (mín. 8 caracteres com maiúscula, número e especial). Confirmação por
  código de 6 dígitos enviado no e-mail.
- **Reset de senha** — e-mail → código de 6 dígitos → nova senha (mesmas
  regras) → "Sucesso, sua senha foi trocada! Tente logar novamente."
- **Dashboard** — nome do usuário no topo à direita, sidebar com
  **+ Add new Binder** (pede o nome da pasta). Dentro do binder: botão **+**
  pra upload (JPG, PNG, AVIF, HEIC — do celular ou do computador). Cada foto
  vira um formulário com Estado (M, NM, SP, MP, HP, DM), Preço em BRL,
  checkbox de Troca e de Venda, e o botão **Criar folha**.
- **Binder público** — grid com as cartas, zoom, e botão flutuante do
  WhatsApp puxando o número cadastrado no registro.

## Compressão das imagens

Antes do upload, a imagem é redimensionada no próprio navegador pro lado
maior ter ~2200px (acima dos 2000px que você pediu, então o zoom continua
nítido) e salva em JPEG 82%. Fotos HEIC de iPhone são convertidas
automaticamente. Isso costuma reduzir de ~4MB pra ~400KB por carta,
economizando bastante o espaço gratuito do Supabase.

## Sobre a chave secreta

Só a **publishable key** está no código — ela é feita pra ficar pública.
A `secret key` **nunca** deve entrar em arquivo do frontend. Se ela já foi
exposta em algum lugar, rotacione em Project Settings → API.
