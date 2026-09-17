create extension if not exists pgcrypto;

create table if not exists public.people (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  birthday date,
  address text default '',
  phone text default '',
  email text default '',
  favourite_flower text default '',
  favourite_treat text default '',
  favourite_drink text default '',
  hobbies text default '',
  likes text default '',
  dislikes text default '',
  edit_token uuid not null default gen_random_uuid(),
  updated_at timestamptz not null default now()
);

alter table public.people enable row level security;

-- No direct table access for anonymous visitors.
revoke all on public.people from anon, authenticated;

-- Private read-by-token function.
create or replace function public.get_person_by_token(p_token uuid)
returns table (
  name text,
  birthday date,
  address text,
  phone text,
  email text,
  favourite_flower text,
  favourite_treat text,
  favourite_drink text,
  hobbies text,
  likes text,
  dislikes text
)
language sql
security definer
set search_path = public
as $$
  select
    p.name, p.birthday, p.address, p.phone, p.email,
    p.favourite_flower, p.favourite_treat, p.favourite_drink,
    p.hobbies, p.likes, p.dislikes
  from public.people p
  where p.edit_token = p_token
  limit 1;
$$;

-- Private update-by-token function.
create or replace function public.update_person_by_token(
  p_token uuid,
  p_address text,
  p_phone text,
  p_email text,
  p_favourite_flower text,
  p_favourite_treat text,
  p_favourite_drink text,
  p_hobbies text,
  p_likes text,
  p_dislikes text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  changed integer;
begin
  update public.people
  set
    address = coalesce(p_address,''),
    phone = coalesce(p_phone,''),
    email = coalesce(p_email,''),
    favourite_flower = coalesce(p_favourite_flower,''),
    favourite_treat = coalesce(p_favourite_treat,''),
    favourite_drink = coalesce(p_favourite_drink,''),
    hobbies = coalesce(p_hobbies,''),
    likes = coalesce(p_likes,''),
    dislikes = coalesce(p_dislikes,''),
    updated_at = now()
  where edit_token = p_token;

  get diagnostics changed = row_count;
  return changed = 1;
end;
$$;

grant execute on function public.get_person_by_token(uuid) to anon;
grant execute on function public.update_person_by_token(
  uuid,text,text,text,text,text,text,text,text,text
) to anon;

-- Seed the current address book only if the table is empty.
insert into public.people (name, birthday, address)
select v.name, v.birthday::date, v.address
from (values
('Amy','1985-01-07',''),
('PJ','1988-01-14','72 Vineyard Road, Newport, TF10 7RU'),
('Callum','2025-01-15',''),
('Kathryn','1988-01-20','3 Orchard Close, Rugeley, WS15 2HD'),
('Becky','1990-01-22','140 Lewis Crescent, Wellington, Telford, Shropshire, TF1 2FR'),
('Jay','1988-02-02','38 Lancaster Road, Formby, Liverpool, L37 6AT'),
('Scout','2015-02-05','1 The Green, Limekiln Lane, Lilleshall, TF10 9HA'),
('Nanny','1935-02-17',''),
('Mike.C','1989-02-23','72 Vineyard Road, Newport, TF10 7RU'),
('Rhys','2019-02-28','28 Coppice View Road, Sutton Coldfield, West Midlands, B73 6UE'),
('Dad','1954-03-08','5 Mulberry Close, Church Aston, Newport, Shropshire, TF10 9LX'),
('Martha','2025-03-17','3 Orchard Close, Rugeley, WS15 2HD'),
('Tyler','2019-03-25','72 Vineyard Road, Newport, TF10 7RU'),
('Matt','1988-03-27','Gl. Århusvej 163, Viborg, 8800, DANMARK'),
('Mike','1987-04-07','3 Orchard Close, Rugeley, WS15 2HD'),
('Lolly','1986-04-08','1 The Green, Limekiln Lane, Lilleshall, TF10 9HA'),
('Jack','2025-04-28','Creamore Mill, Creamore, Wem, SY4 5QU'),
('Wren','2022-05-02','1 The Green, Limekiln Lane, Lilleshall, TF10 9HA'),
('Olly','1988-05-12','Creamore Mill, Creamore, Wem, SY4 5QU'),
('Finn','2023-05-14','72 Vineyard Road, Newport, TF10 7RU'),
('Gin','1992-05-31','Creamore Mill, Creamore, Wem, SY4 5QU'),
('Nina','2025-06-10','140 Lewis Crescent, Wellington, Telford, Shropshire, TF1 2FR'),
('Connor','2002-07-07',''),
('William','2020-08-28','92 Wharf Road, Gnosall, Staffordshire, ST20 0DA'),
('Toby','2015-09-09',''),
('Mum','1955-09-28','5 Mulberry Close, Church Aston, Newport, Shropshire, TF10 9LX'),
('Ceri','1986-09-29','28 Coppice View Road, Sutton Coldfield, West Midlands, B73 6UE'),
('Lou','1983-10-22','66 Orchid Close, Hereford, HR4 7FJ'),
('Helen','1987-10-23','92 Wharf Road, Gnosall, Staffordshire, ST20 0DA'),
('Alisha','2007-11-19',''),
('Elisa','1989-11-29','Gl. Århusvej 163, Viborg, 8800, DANMARK'),
('Satinder','1988-12-03','140 Lewis Crescent, Wellington, Telford, Shropshire, TF1 2FR'),
('Al','1982-12-11','1 The Green, Limekiln Lane, Lilleshall, TF10 9HA'),
('Joe','1957-12-18','9 Heathwood Road, Newport, Shropshire, TF10 7QB'),
('Sue','1958-12-20','9 Heathwood Road, Newport, Shropshire, TF10 7QB'),
('Dan','1987-12-29','92 Wharf Road, Gnosall, Staffordshire, ST20 0DA')
) as v(name,birthday,address)
where not exists (select 1 from public.people);

-- Run this query in Supabase SQL Editor after deployment to generate the links you send out:
-- select name,
--   'https://YOUR-GITHUB-USERNAME.github.io/YOUR-REPO/edit.html?token=' || edit_token as private_edit_link
-- from public.people
-- order by extract(month from birthday), extract(day from birthday);

-- V2: single-use invitations for new profiles
create table if not exists public.invitations(id uuid primary key default gen_random_uuid(),invite_token uuid not null unique default gen_random_uuid(),created_at timestamptz not null default now(),used_at timestamptz);
alter table public.invitations enable row level security;
revoke all on public.invitations from anon, authenticated;
create or replace function public.check_invitation(p_token uuid) returns boolean language sql security definer set search_path=public as $$ select exists(select 1 from public.invitations where invite_token=p_token and used_at is null); $$;
grant execute on function public.check_invitation(uuid) to anon;
create or replace function public.create_person_from_invite(p_invite uuid,p_name text,p_birthday date,p_address text,p_phone text,p_email text,p_favourite_flower text,p_favourite_treat text,p_favourite_drink text,p_hobbies text,p_likes text,p_dislikes text) returns uuid language plpgsql security definer set search_path=public as $$ declare nt uuid; iid uuid; begin select id into iid from public.invitations where invite_token=p_invite and used_at is null for update; if iid is null then return null; end if; insert into public.people(name,birthday,address,phone,email,favourite_flower,favourite_treat,favourite_drink,hobbies,likes,dislikes) values(p_name,p_birthday,coalesce(p_address,''),coalesce(p_phone,''),coalesce(p_email,''),coalesce(p_favourite_flower,''),coalesce(p_favourite_treat,''),coalesce(p_favourite_drink,''),coalesce(p_hobbies,''),coalesce(p_likes,''),coalesce(p_dislikes,'')) returning edit_token into nt; update public.invitations set used_at=now() where id=iid; return nt; end; $$;
grant execute on function public.create_person_from_invite(uuid,text,date,text,text,text,text,text,text,text,text,text) to anon;
