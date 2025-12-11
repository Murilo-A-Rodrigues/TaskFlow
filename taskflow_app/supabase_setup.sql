-- ========================================
-- 📊 SCRIPT SQL PARA SUPABASE - TASKFLOW
-- ========================================
-- Execute este script no SQL Editor do Supabase
-- Baseado na arquitetura Entity/DTO/Mapper implementada

-- ========================================
-- � TABELA DE USUÁRIOS
-- ========================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL CHECK (length(trim(name)) >= 2),
  email TEXT NOT NULL UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  phone TEXT NULL,
  avatar_url TEXT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMPTZ NULL
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_updated_at ON public.users(updated_at DESC);

-- ========================================
-- 📋 TABELA DE PROJETOS
-- ========================================
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL CHECK (length(trim(name)) >= 2 AND length(trim(name)) <= 100),
  description TEXT NULL,
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'planning' CHECK (status IN ('planning', 'active', 'on_hold', 'completed', 'cancelled')),
  start_date TIMESTAMPTZ NULL,
  end_date TIMESTAMPTZ NULL,
  deadline TIMESTAMPTZ NULL,
  color TEXT NULL,
  is_archived BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Constraints de domínio
  CONSTRAINT valid_date_range CHECK (start_date IS NULL OR end_date IS NULL OR start_date <= end_date)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON public.projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON public.projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_updated_at ON public.projects(updated_at DESC);

-- ========================================
-- 🏷️ TABELA DE CATEGORIAS
-- ========================================
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL CHECK (length(trim(name)) >= 2 AND length(trim(name)) <= 50),
  description TEXT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  parent_id UUID NULL REFERENCES public.categories(id) ON DELETE SET NULL,
  color TEXT NOT NULL DEFAULT '#2196F3' CHECK (color ~* '^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$'),
  icon TEXT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Constraints de domínio
  CONSTRAINT no_self_parent CHECK (parent_id != id),
  CONSTRAINT unique_name_per_user UNIQUE (user_id, name)
);

-- Índices para performance e hierarquia
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON public.categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON public.categories(sort_order);
CREATE INDEX IF NOT EXISTS idx_categories_is_deleted ON public.categories(is_deleted);
CREATE INDEX IF NOT EXISTS idx_categories_updated_at ON public.categories(updated_at DESC);

-- ========================================
-- 📝 TABELA DE TAREFAS (ATUALIZADA)
-- ========================================
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL CHECK (length(trim(title)) >= 1),
  description TEXT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  due_date TIMESTAMPTZ NULL,
  priority INTEGER NOT NULL DEFAULT 2 CHECK (priority IN (1, 2, 3)), -- 1=baixa, 2=média, 3=alta
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  deleted_at TIMESTAMPTZ NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Relacionamento obrigatório com usuário (dono da tarefa)
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  
  -- Relacionamentos opcionais
  project_id UUID NULL REFERENCES public.projects(id) ON DELETE SET NULL,
  category_id UUID NULL REFERENCES public.categories(id) ON DELETE SET NULL,
  assigned_to UUID NULL REFERENCES public.users(id) ON DELETE SET NULL
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON public.tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_category_id ON public.tasks(category_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON public.tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_is_deleted ON public.tasks(is_deleted);
CREATE INDEX IF NOT EXISTS idx_tasks_updated_at ON public.tasks(updated_at DESC);

-- ========================================
-- ⏰ TABELA DE LEMBRETES
-- ========================================
CREATE TABLE IF NOT EXISTS public.reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reminder_date TIMESTAMPTZ NOT NULL,
  type TEXT NOT NULL DEFAULT 'once' CHECK (type IN ('once', 'daily', 'weekly', 'custom')),
  custom_message TEXT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  notification_id INTEGER NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON public.reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_task_id ON public.reminders(task_id);
CREATE INDEX IF NOT EXISTS idx_reminders_reminder_date ON public.reminders(reminder_date);
CREATE INDEX IF NOT EXISTS idx_reminders_is_active ON public.reminders(is_active);
CREATE INDEX IF NOT EXISTS idx_reminders_updated_at ON public.reminders(updated_at DESC);

-- ========================================
-- 💬 TABELA DE COMENTÁRIOS
-- ========================================
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content TEXT NOT NULL CHECK (length(trim(content)) >= 2 AND length(trim(content)) <= 5000),
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  parent_id UUID NULL REFERENCES public.comments(id) ON DELETE CASCADE,
  is_edited BOOLEAN NOT NULL DEFAULT false,
  edited_at TIMESTAMPTZ NULL,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Constraints de domínio
  CONSTRAINT no_self_reply CHECK (parent_id != id),
  CONSTRAINT edited_state_consistency CHECK (
    (is_edited = true AND edited_at IS NOT NULL) OR 
    (is_edited = false AND edited_at IS NULL)
  )
);

-- Índices para performance e threading
CREATE INDEX IF NOT EXISTS idx_comments_task_id ON public.comments(task_id);
CREATE INDEX IF NOT EXISTS idx_comments_author_id ON public.comments(author_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON public.comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON public.comments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_updated_at ON public.comments(updated_at DESC);

-- ========================================
-- 🔄 FUNÇÃO DE ATUALIZAÇÃO AUTOMÁTICA
-- ========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ========================================
-- ⚡ TRIGGERS PARA UPDATED_AT
-- ========================================
CREATE TRIGGER update_users_updated_at 
  BEFORE UPDATE ON users 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at 
  BEFORE UPDATE ON projects 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at 
  BEFORE UPDATE ON categories 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at 
  BEFORE UPDATE ON tasks 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reminders_updated_at 
  BEFORE UPDATE ON reminders 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at 
  BEFORE UPDATE ON comments 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- 🛡️ ROW LEVEL SECURITY (RLS)
-- ========================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 👥 POLÍTICAS PARA USERS
-- ========================================
CREATE POLICY "public read users" ON public.users
  FOR SELECT TO anon USING (true);

CREATE POLICY "public write users" ON public.users
  FOR ALL TO anon USING (true);

-- ========================================
-- 📋 POLÍTICAS PARA PROJECTS
-- ========================================
CREATE POLICY "public read projects" ON public.projects
  FOR SELECT TO anon USING (true);

CREATE POLICY "public write projects" ON public.projects
  FOR ALL TO anon USING (true);

-- ========================================
-- 🏷️ POLÍTICAS PARA CATEGORIES
-- ========================================
-- Política para permitir que usuários vejam apenas suas próprias categorias
CREATE POLICY "Users can view own categories" ON public.categories
  FOR SELECT TO anon USING (user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Política para permitir que usuários criem suas próprias categorias
CREATE POLICY "Users can create own categories" ON public.categories
  FOR INSERT TO anon WITH CHECK (user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Política para permitir que usuários atualizem suas próprias categorias
CREATE POLICY "Users can update own categories" ON public.categories
  FOR UPDATE TO anon USING (user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Política para permitir que usuários deletem suas próprias categorias
CREATE POLICY "Users can delete own categories" ON public.categories
  FOR DELETE TO anon USING (user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- ========================================
-- 📝 POLÍTICAS PARA TASKS
-- ========================================
-- Política para permitir que usuários vejam apenas suas próprias tarefas
CREATE POLICY "Users can view own tasks" ON public.tasks
  FOR SELECT TO anon USING (user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Política para permitir que usuários criem suas próprias tarefas
CREATE POLICY "Users can create own tasks" ON public.tasks
-- ========================================
-- ⏰ POLÍTICAS PARA REMINDERS
-- ========================================
-- Política para permitir que usuários vejam apenas seus próprios lembretes
CREATE POLICY "Users can view own reminders" ON public.reminders
  FOR SELECT TO anon USING (user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Política para permitir que usuários criem seus próprios lembretes
CREATE POLICY "Users can create own reminders" ON public.reminders
  FOR INSERT TO anon WITH CHECK (user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Política para permitir que usuários atualizem seus próprios lembretes
CREATE POLICY "Users can update own reminders" ON public.reminders
  FOR UPDATE TO anon USING (user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- Política para permitir que usuários deletem seus próprios lembretes
CREATE POLICY "Users can delete own reminders" ON public.reminders
  FOR DELETE TO anon USING (user_id::text = current_setting('request.jwt.claims', true)::json->>'sub'); own tasks" ON public.tasks
  FOR DELETE TO anon USING (user_id::text = current_setting('request.jwt.claims', true)::json->>'sub');

-- ========================================
-- ⏰ POLÍTICAS PARA REMINDERS
-- ========================================
CREATE POLICY "public read reminders" ON public.reminders
  FOR SELECT TO anon USING (true);

CREATE POLICY "public write reminders" ON public.reminders
  FOR ALL TO anon USING (true);

-- ========================================
-- 💬 POLÍTICAS PARA COMMENTS
-- ========================================
CREATE POLICY "public read comments" ON public.comments
  FOR SELECT TO anon USING (true);

CREATE POLICY "public write comments" ON public.comments
  FOR ALL TO anon USING (true);

-- ========================================
-- 📦 STORAGE BUCKETS
-- ========================================

-- Bucket para avatares de usuários
INSERT INTO storage.buckets (id, name, public) 
VALUES ('user-avatars', 'user-avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Bucket para imagens de projetos
INSERT INTO storage.buckets (id, name, public) 
VALUES ('project-images', 'project-images', true)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- 🧪 DADOS INICIAIS PARA TESTE
-- ========================================

-- Usuário de teste
INSERT INTO public.users (id, name, email, phone, is_active) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', 'João Desenvolvedor', 'joao@taskflow.com', '+5511999887766', true),
  ('550e8400-e29b-41d4-a716-446655440002', 'Maria Testadora', 'maria@taskflow.com', '+5511987654321', true)
ON CONFLICT (id) DO NOTHING;

-- Projeto de teste
INSERT INTO public.projects (id, name, description, owner_id, status, color) VALUES
  ('550e8400-e29b-41d4-a716-446655440010', 'TaskFlow Development', 'Desenvolvimento do app TaskFlow', '550e8400-e29b-41d4-a716-446655440001', 'active', '#FF5722')
ON CONFLICT (id) DO NOTHING;

-- Categorias de teste
INSERT INTO public.categories (id, name, description, user_id, color, icon, sort_order) VALUES
  ('550e8400-e29b-41d4-a716-446655440020', 'Trabalho', 'Tarefas relacionadas ao trabalho', '550e8400-e29b-41d4-a716-446655440001', '#4CAF50', 'work_outline', 1),
  ('550e8400-e29b-41d4-a716-446655440021', 'Estudos', 'Tarefas de aprendizado', '550e8400-e29b-41d4-a716-446655440001', '#2196F3', 'school', 2),
  ('550e8400-e29b-41d4-a716-446655440022', 'Reuniões', 'Sub-categoria de trabalho', '550e8400-e29b-41d4-a716-446655440001', '#FF9800', 'meeting_room', 1)
ON CONFLICT (id) DO NOTHING;

-- Atualizar categoria pai (hierarquia)
UPDATE public.categories 
SET parent_id = '550e8400-e29b-41d4-a716-446655440020' 
WHERE id = '550e8400-e29b-41d4-a716-446655440022';

-- Tarefas de teste com relacionamentos
INSERT INTO public.tasks (id, title, description, is_completed, priority, project_id, category_id, assigned_to) VALUES
  ('550e8400-e29b-41d4-a716-446655440030', 'Implementar Entity/DTO/Mapper', 'Criar arquitetura para 4 novas entidades', false, 3, '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440001'),
  ('550e8400-e29b-41d4-a716-446655440031', 'Estudar Clean Architecture', 'Revisar conceitos e padrões', false, 2, NULL, '550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440001'),
  ('550e8400-e29b-41d4-a716-446655440032', 'Reunião de planejamento', 'Definir próximos passos do projeto', true, 2, '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440022', '550e8400-e29b-41d4-a716-446655440001')
ON CONFLICT (id) DO NOTHING;

-- Comentários de teste
INSERT INTO public.comments (id, content, task_id, author_id, is_edited) VALUES
  ('550e8400-e29b-41d4-a716-446655440040', 'Arquitetura Entity/DTO/Mapper implementada com sucesso! Todas as validações de domínio funcionando.', '550e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440001', false),
  ('550e8400-e29b-41d4-a716-446655440041', 'Testes de conversão bidirecional aprovados ✅', '550e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440002', false)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- ✅ VERIFICAÇÃO FINAL
-- ========================================
-- Execute esta query para verificar se tudo foi criado:

SELECT 
  'users' as tabela, count(*) as registros FROM users
UNION ALL
SELECT 
  'projects' as tabela, count(*) as registros FROM projects
UNION ALL
SELECT 
  'categories' as tabela, count(*) as registros FROM categories
UNION ALL
SELECT 
  'tasks' as tabela, count(*) as registros FROM tasks
UNION ALL
SELECT 
  'comments' as tabela, count(*) as registros FROM comments;

-- ========================================
-- 🔍 QUERY PARA TESTAR RELACIONAMENTOS
-- ========================================
-- Teste completo da estrutura hierárquica
SELECT 
  t.title as tarefa,
  p.name as projeto,
  c.name as categoria,
  u.name as responsavel,
  count(cm.id) as comentarios
FROM tasks t
LEFT JOIN projects p ON t.project_id = p.id
LEFT JOIN categories c ON t.category_id = c.id
LEFT JOIN users u ON t.assigned_to = u.id
LEFT JOIN comments cm ON cm.task_id = t.id
GROUP BY t.id, t.title, p.name, c.name, u.name
ORDER BY t.title;

-- ========================================
-- 📝 NOTAS IMPORTANTES:
-- ========================================
-- 1. Execute este script completo no SQL Editor do Supabase
-- 2. Todas as tabelas seguem a arquitetura Entity/DTO/Mapper implementada
-- 3. RLS habilitado com políticas públicas para desenvolvimento
-- 4. Constraints de domínio implementadas no banco para garantir integridade
-- 5. Relacionamentos hierárquicos suportados (categories, comments)
-- 6. Índices otimizados para sync incremental e performance
-- 7. Dados de teste incluem relacionamentos completos
-- 8. Para produção, ajustar políticas RLS conforme necessário
-- ========================================