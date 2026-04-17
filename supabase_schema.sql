-- ============================================
-- AI LIFE OS — SUPABASE DATABASE SCHEMA
-- Run this entire file in Supabase SQL Editor
-- ============================================

-- 1. PROFILES
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  name text not null,
  email text not null,
  avatar_url text,
  timezone text default 'Asia/Kolkata',
  created_at timestamptz default now()
);
alter table profiles enable row level security;
create policy "Users can view own profile" on profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);
create policy "Users can insert own profile" on profiles for insert with check (auth.uid() = id);

-- 2. TASKS
create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  title text not null,
  description text,
  is_completed boolean default false,
  priority text default 'medium' check (priority in ('low', 'medium', 'high')),
  due_date timestamptz,
  created_at timestamptz default now()
);
alter table tasks enable row level security;
create policy "Users can manage own tasks" on tasks for all using (auth.uid() = user_id);
create index tasks_user_id_idx on tasks(user_id);

-- 3. HABITS
create table if not exists habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  title text not null,
  emoji text default '⭐',
  frequency text default 'daily' check (frequency in ('daily', 'weekly')),
  streak_count integer default 0,
  completed_dates jsonb default '[]'::jsonb,
  created_at timestamptz default now()
);
alter table habits enable row level security;
create policy "Users can manage own habits" on habits for all using (auth.uid() = user_id);
create index habits_user_id_idx on habits(user_id);

-- 4. MOOD LOGS
create table if not exists mood_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  mood_value integer not null check (mood_value between 1 and 5),
  mood_label text not null,
  energy_level integer default 3 check (energy_level between 1 and 5),
  note text,
  created_at timestamptz default now()
);
alter table mood_logs enable row level security;
create policy "Users can manage own mood logs" on mood_logs for all using (auth.uid() = user_id);
create index mood_logs_user_id_idx on mood_logs(user_id);

-- 5. MENTOR MESSAGES
create table if not exists mentor_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz default now()
);
alter table mentor_messages enable row level security;
create policy "Users can manage own mentor messages" on mentor_messages for all using (auth.uid() = user_id);
create index mentor_messages_user_id_idx on mentor_messages(user_id);

-- 6. PERSONALITY SCORES
create table if not exists personality_scores (
  user_id uuid references auth.users on delete cascade primary key,
  discipline_score float default 50,
  focus_score float default 50,
  consistency_score float default 50,
  motivation_score float default 50,
  energy_score float default 50,
  motivation_type text default 'inspiration',
  energy_cycle text default 'flexible',
  mentor_tone text default 'supportive',
  updated_at timestamptz default now()
);
alter table personality_scores enable row level security;
create policy "Users can manage own personality" on personality_scores for all using (auth.uid() = user_id);

-- ============================================
-- AUTO-CREATE PROFILE ON SIGNUP
-- ============================================
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'User'),
    new.email
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();
