insert into storage.buckets (id, name, public)
values ('payment-slips', 'payment-slips', true)
on conflict (id) do update set public = excluded.public;

create policy "Public payment slip reads"
on storage.objects for select
using (bucket_id = 'payment-slips');

create policy "Anon payment slip uploads"
on storage.objects for insert
to anon
with check (bucket_id = 'payment-slips');
