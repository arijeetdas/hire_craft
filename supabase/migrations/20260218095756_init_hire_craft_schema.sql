create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  name text,
  onboarding_completed boolean not null default false,
  career_level text,
  target_role text,
  industry text,
  writing_style text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.resumes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'Untitled Resume',
  ats_score integer not null default 0,
  last_edited_at timestamptz not null default now(),
  content jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.resume_versions (
  id bigint generated always as identity primary key,
  resume_id uuid not null references public.resumes(id) on delete cascade,
  version integer not null,
  content jsonb not null default '{}'::jsonb,
  last_edited_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (resume_id, version)
);

create index if not exists resumes_user_id_idx on public.resumes(user_id);
create index if not exists resumes_last_edited_idx on public.resumes(last_edited_at desc);
create index if not exists resume_versions_resume_id_idx on public.resume_versions(resume_id);
create index if not exists resume_versions_version_idx on public.resume_versions(resume_id, version desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_resumes_updated_at on public.resumes;
create trigger trg_resumes_updated_at
before update on public.resumes
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.resumes enable row level security;
alter table public.resume_versions enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_delete_own" on public.profiles;

create policy "profiles_select_own"
on public.profiles for select to authenticated
using (auth.uid() = id);

create policy "profiles_insert_own"
on public.profiles for insert to authenticated
with check (auth.uid() = id);

create policy "profiles_update_own"
on public.profiles for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "profiles_delete_own"
on public.profiles for delete to authenticated
using (auth.uid() = id);

drop policy if exists "resumes_select_own" on public.resumes;
drop policy if exists "resumes_insert_own" on public.resumes;
drop policy if exists "resumes_update_own" on public.resumes;
drop policy if exists "resumes_delete_own" on public.resumes;

create policy "resumes_select_own"
on public.resumes for select to authenticated
using (auth.uid() = user_id);

create policy "resumes_insert_own"
on public.resumes for insert to authenticated
with check (auth.uid() = user_id);

create policy "resumes_update_own"
on public.resumes for update to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "resumes_delete_own"
on public.resumes for delete to authenticated
using (auth.uid() = user_id);

drop policy if exists "resume_versions_select_own" on public.resume_versions;
drop policy if exists "resume_versions_insert_own" on public.resume_versions;
drop policy if exists "resume_versions_update_own" on public.resume_versions;
drop policy if exists "resume_versions_delete_own" on public.resume_versions;

create policy "resume_versions_select_own"
on public.resume_versions for select to authenticated
using (
  exists (
    select 1 from public.resumes r
    where r.id = resume_versions.resume_id
      and r.user_id = auth.uid()
  )
);

create policy "resume_versions_insert_own"
on public.resume_versions for insert to authenticated
with check (
  exists (
    select 1 from public.resumes r
    where r.id = resume_versions.resume_id
      and r.user_id = auth.uid()
  )
);

create policy "resume_versions_update_own"
on public.resume_versions for update to authenticated
using (
  exists (
    select 1 from public.resumes r
    where r.id = resume_versions.resume_id
      and r.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.resumes r
    where r.id = resume_versions.resume_id
      and r.user_id = auth.uid()
  )
);

create policy "resume_versions_delete_own"
on public.resume_versions for delete to authenticated
using (
  exists (
    select 1 from public.resumes r
    where r.id = resume_versions.resume_id
      and r.user_id = auth.uid()
  )
);

insert into storage.buckets (id, name, public)
values ('resume-pdfs', 'resume-pdfs', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "resume_pdfs_read_public" on storage.objects;
drop policy if exists "resume_pdfs_insert_own" on storage.objects;
drop policy if exists "resume_pdfs_update_own" on storage.objects;
drop policy if exists "resume_pdfs_delete_own" on storage.objects;

create policy "resume_pdfs_read_public"
on storage.objects for select to public
using (bucket_id = 'resume-pdfs');

create policy "resume_pdfs_insert_own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'resume-pdfs'
  and (
    ((storage.foldername(name))[1] = 'resumes' and (storage.foldername(name))[2] = auth.uid()::text)
    or
    ((storage.foldername(name))[1] = 'generated' and (storage.foldername(name))[2] = auth.uid()::text)
  )
);

create policy "resume_pdfs_update_own"
on storage.objects for update to authenticated
using (
  bucket_id = 'resume-pdfs'
  and (
    ((storage.foldername(name))[1] = 'resumes' and (storage.foldername(name))[2] = auth.uid()::text)
    or
    ((storage.foldername(name))[1] = 'generated' and (storage.foldername(name))[2] = auth.uid()::text)
  )
)
with check (
  bucket_id = 'resume-pdfs'
  and (
    ((storage.foldername(name))[1] = 'resumes' and (storage.foldername(name))[2] = auth.uid()::text)
    or
    ((storage.foldername(name))[1] = 'generated' and (storage.foldername(name))[2] = auth.uid()::text)
  )
);

create policy "resume_pdfs_delete_own"
on storage.objects for delete to authenticated
using (
  bucket_id = 'resume-pdfs'
  and (
    ((storage.foldername(name))[1] = 'resumes' and (storage.foldername(name))[2] = auth.uid()::text)
    or
    ((storage.foldername(name))[1] = 'generated' and (storage.foldername(name))[2] = auth.uid()::text)
  )
);