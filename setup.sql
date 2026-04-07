-- =============================================
-- 🚀 БЫСТРЫЙ СТАРТ - ЧИТАЙ ЭТО СНАЧАЛА!
-- =============================================
--
-- 1. Откройте https://app.supabase.com
-- 2. Выберите ваш проект
-- 3. Перейдите в SQL Editor (левое меню)
-- 4. Скопируйте ВСЕ содержимое этого файла (Ctrl+A)
-- 5. Вставьте в SQL Editor (Ctrl+V)
-- 6. Нажмите RUN или Ctrl+Enter
-- 7. Дождитесь ✅ (обычно 5-10 секунд)
-- 8. Закройте SQL Editor
-- 9. Откройте index(2).html в браузере
-- 10. Зарегистрируйтесь и тестируйте!
--
-- ОСОБЕННОСТИ:
-- ✓ История по дням (вкладка 📅 История)
-- ✓ Время приёма лекарств (автоматически сохраняется)
-- ✓ Браузерные уведомления (разрешение запросит сам)
-- ✓ Напоминания в 8:00, 14:00, 20:00
-- ✓ Управление семьёй и участниками
-- =============================================

-- =============================================
-- MEDICINE APP - ЗАПУСТИ ЭТО В SUPABASE SQL EDITOR
-- =============================================

-- 1. Таблица профилей пользователей
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL DEFAULT '',
  created_at timestamptz DEFAULT now()
);

-- 2. Таблица семей
CREATE TABLE IF NOT EXISTS public.families (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  code text NOT NULL UNIQUE,
  admin_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- 3. Члены семьи
CREATE TABLE IF NOT EXISTS public.family_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid REFERENCES public.families(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(family_id, user_id)
);

-- 4. Лекарства
CREATE TABLE IF NOT EXISTS public.medications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid REFERENCES public.families(id) ON DELETE CASCADE,
  name text NOT NULL,
  dose text NOT NULL,
  times text[] NOT NULL DEFAULT '{}',
  frequency integer DEFAULT 1,
  start_date date,
  created_at timestamptz DEFAULT now()
);

-- 5. Журнал приёма лекарств
CREATE TABLE IF NOT EXISTS public.medication_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  medication_id uuid REFERENCES public.medications(id) ON DELETE CASCADE,
  family_id uuid REFERENCES public.families(id) ON DELETE CASCADE,
  given_by uuid REFERENCES public.profiles(id),
  given_by_name text,
  time_of_day text NOT NULL,
  log_date date NOT NULL DEFAULT CURRENT_DATE,
  given_at timestamptz DEFAULT now(),
  UNIQUE(medication_id, time_of_day, log_date)
);

-- 6. Уведомления
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid REFERENCES public.families(id) ON DELETE CASCADE,
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  message text NOT NULL,
  type text DEFAULT 'med_given',
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- =============================================
-- ROW LEVEL SECURITY
-- =============================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Profiles
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Families
DROP POLICY IF EXISTS "families_all" ON public.families;
CREATE POLICY "families_all" ON public.families FOR ALL USING (true) WITH CHECK (true);

-- Family members
DROP POLICY IF EXISTS "family_members_all" ON public.family_members;
CREATE POLICY "family_members_all" ON public.family_members FOR ALL USING (true) WITH CHECK (true);

-- Medications
DROP POLICY IF EXISTS "medications_all" ON public.medications;
CREATE POLICY "medications_all" ON public.medications FOR ALL USING (true) WITH CHECK (true);

-- Logs
DROP POLICY IF EXISTS "logs_all" ON public.medication_logs;
CREATE POLICY "logs_all" ON public.medication_logs FOR ALL USING (true) WITH CHECK (true);

-- Notifications
DROP POLICY IF EXISTS "notifications_all" ON public.notifications;
CREATE POLICY "notifications_all" ON public.notifications FOR ALL USING (true) WITH CHECK (true);

-- =============================================
-- ИНДЕКСЫ
-- =============================================

CREATE INDEX IF NOT EXISTS idx_medication_logs_family ON public.medication_logs(family_id);
CREATE INDEX IF NOT EXISTS idx_medication_logs_date ON public.medication_logs(log_date);
CREATE INDEX IF NOT EXISTS idx_medications_family ON public.medications(family_id);
CREATE INDEX IF NOT EXISTS idx_family_members_user ON public.family_members(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);

-- =============================================
-- АВТО-СОЗДАНИЕ ПРОФИЛЯ ПРИ РЕГИСТРАЦИИ
-- =============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, name)
  VALUES (new.id, COALESCE(new.raw_user_meta_data->>'name', ''))
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- ГОТОВО! Теперь открой index.html в браузере
-- =============================================
