-- ========================================
-- 🔄 MIGRATION: SOFT DELETE IMPLEMENTATION
-- ========================================
-- Execute este script no SQL Editor do Supabase se você já tem
-- as tabelas criadas e deseja adicionar o soft delete

-- ========================================
-- 📝 ADICIONAR COLUNAS DE SOFT DELETE EM TASKS
-- ========================================
DO $$ 
BEGIN
  -- Adiciona is_deleted se não existir
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'is_deleted'
  ) THEN
    ALTER TABLE public.tasks ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT false;
    RAISE NOTICE 'Coluna is_deleted adicionada à tabela tasks';
  ELSE
    RAISE NOTICE 'Coluna is_deleted já existe na tabela tasks';
  END IF;

  -- Adiciona deleted_at se não existir
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE public.tasks ADD COLUMN deleted_at TIMESTAMPTZ NULL;
    RAISE NOTICE 'Coluna deleted_at adicionada à tabela tasks';
  ELSE
    RAISE NOTICE 'Coluna deleted_at já existe na tabela tasks';
  END IF;
END $$;

-- ========================================
-- 🏷️ ADICIONAR COLUNAS DE SOFT DELETE EM CATEGORIES
-- ========================================
DO $$ 
BEGIN
  -- Adiciona is_deleted se não existir
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'categories' AND column_name = 'is_deleted'
  ) THEN
    ALTER TABLE public.categories ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT false;
    RAISE NOTICE 'Coluna is_deleted adicionada à tabela categories';
  ELSE
    RAISE NOTICE 'Coluna is_deleted já existe na tabela categories';
  END IF;

  -- Adiciona deleted_at se não existir
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'categories' AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE public.categories ADD COLUMN deleted_at TIMESTAMPTZ NULL;
    RAISE NOTICE 'Coluna deleted_at adicionada à tabela categories';
  ELSE
    RAISE NOTICE 'Coluna deleted_at já existe na tabela categories';
  END IF;
END $$;

-- ========================================
-- 📊 CRIAR ÍNDICES PARA PERFORMANCE
-- ========================================

-- Índice para tasks.is_deleted
CREATE INDEX IF NOT EXISTS idx_tasks_is_deleted ON public.tasks(is_deleted);

-- Índice para categories.is_deleted
CREATE INDEX IF NOT EXISTS idx_categories_is_deleted ON public.categories(is_deleted);

-- ========================================
-- ✅ VERIFICAÇÃO
-- ========================================
DO $$ 
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'MIGRATION COMPLETED SUCCESSFULLY';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Tasks: is_deleted and deleted_at columns added';
  RAISE NOTICE 'Categories: is_deleted and deleted_at columns added';
  RAISE NOTICE 'Indexes created for performance';
  RAISE NOTICE '========================================';
END $$;

-- ========================================
-- 📝 QUERY DE VERIFICAÇÃO
-- ========================================
-- Execute estas queries para verificar as colunas criadas:

-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'tasks' AND column_name IN ('is_deleted', 'deleted_at')
-- ORDER BY column_name;

-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'categories' AND column_name IN ('is_deleted', 'deleted_at')
-- ORDER BY column_name;
