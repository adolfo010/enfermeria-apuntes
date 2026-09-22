create policy "knowledge_figures_admin_delete" on public.knowledge_figures for delete to authenticated using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'ADMIN'));
