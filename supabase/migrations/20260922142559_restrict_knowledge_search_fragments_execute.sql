revoke all on function public.knowledge_search_fragments(text, integer) from public, anon, authenticated;
-- Solo la Edge Function "knowledge" debe poder ejecutarla (usa SUPABASE_SERVICE_ROLE_KEY, que no depende de estos grants).
