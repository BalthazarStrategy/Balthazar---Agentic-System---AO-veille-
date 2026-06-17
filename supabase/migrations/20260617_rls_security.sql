-- keyword_overrides : aucun RLS actuellement
ALTER TABLE public.keyword_overrides ENABLE ROW LEVEL SECURITY;
CREATE POLICY "keyword_overrides_service_role_only"
  ON public.keyword_overrides FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');

-- ao_feedback : statut RLS à vérifier, on force la protection
ALTER TABLE public.ao_feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ao_feedback_service_role_only"
  ON public.ao_feedback FOR ALL
  USING (((select auth.jwt()) ->> 'role') = 'service_role');
