/* Projeto: letstradetcg_binder — já preenchido com suas credenciais públicas.
   NUNCA coloque a "secret key" aqui — só a publishable/anon key, que é
   segura pra ficar exposta no navegador (as regras de segurança do banco
   é que protegem os dados, não o segredo desta chave). */
const SUPABASE_URL = "https://urxsxhamyrzswknfdlbe.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_0_-FbNzTlaNiplkA5B3VMg_03aULwZJ";

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
const BUCKET = "cards";
const CONDITIONS = ["M", "NM", "SP", "MP", "HP", "DM"];
