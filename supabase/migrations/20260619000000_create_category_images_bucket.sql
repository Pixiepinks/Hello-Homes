-- Create the public Supabase Storage bucket used by category management.
insert into storage.buckets (id, name, public)
values ('category-images', 'category-images', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Public read access for category images" on storage.objects;
create policy "Public read access for category images"
on storage.objects for select
using (bucket_id = 'category-images');

drop policy if exists "Public category image uploads" on storage.objects;
create policy "Public category image uploads"
on storage.objects for insert
with check (bucket_id = 'category-images');
