-- Create the public Supabase Storage bucket used by discount promotion banners.
insert into storage.buckets (id, name, public)
values ('promotion-banners', 'promotion-banners', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Public read access for promotion banners" on storage.objects;
create policy "Public read access for promotion banners"
on storage.objects for select
using (bucket_id = 'promotion-banners');

drop policy if exists "Public promotion banner uploads" on storage.objects;
create policy "Public promotion banner uploads"
on storage.objects for insert
with check (
  bucket_id = 'promotion-banners'
  and (
    lower(right(name, 4)) in ('.jpg', '.png', 'webp')
    or lower(right(name, 5)) = '.jpeg'
  )
);
