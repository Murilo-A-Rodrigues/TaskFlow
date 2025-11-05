# 🚀 Guia de Configuração do Supabase para TaskFlow

## 📝 Instruções para Configurar o Supabase

### 1. Criar Conta no Supabase

1. Acesse [supabase.com](https://supabase.com)
2. Clique em "Start your project"
3. Crie uma conta usando GitHub, Google ou email

### 2. Criar Novo Projeto

1. No dashboard, clique em "New Project"
2. Escolha a organização (pode ser pessoal)
3. Preencha:
   - **Name**: TaskFlow
   - **Database Password**: Crie uma senha segura (anote!)
   - **Region**: Escolha a mais próxima (ex: South America)
4. Clique em "Create new project"
5. Aguarde uns 2-3 minutos para o projeto ser criado

### 3. Obter Credenciais do Projeto

1. No dashboard do projeto, vá em **Settings** > **API**
2. Você verá:
   - **Project URL**: Ex: `https://xxxxxxxxxxx.supabase.co`
   - **API Keys**:
     - **anon/public**: Esta é segura para usar no app
     - **service_role**: ⚠️ NUNCA use esta no frontend!

### 4. Configurar Arquivo .env

Abra o arquivo `.env` e substitua os valores:

```env
# ========================================
# 🔗 SUPABASE CONFIGURATION
# ========================================
SUPABASE_URL=https://seuprojetoid.supabase.co
SUPABASE_ANON_KEY=sua_chave_anon_aqui

# ========================================
# 📱 APP CONFIGURATION
# ========================================
APP_NAME=TaskFlow
APP_VERSION=1.0.0
ENVIRONMENT=development
DEBUG_MODE=true
ENABLE_LOGGING=true
```

**⚠️ IMPORTANTE:**
- Substitua `https://seuprojetoid.supabase.co` pela URL real do seu projeto
- Substitua `sua_chave_anon_aqui` pela chave **anon/public** (não a service_role!)
- Use apenas a chave **anon/public** no frontend por segurança

### 5. Configurar Arquivo .env.production

Para produção, configure o `.env.production`:

```env
# ========================================
# 🔗 SUPABASE CONFIGURATION (PRODUCTION)
# ========================================
SUPABASE_URL=https://seuprojetoid.supabase.co
SUPABASE_ANON_KEY=sua_chave_anon_aqui

# ========================================
# 📱 APP CONFIGURATION (PRODUCTION)
# ========================================
APP_NAME=TaskFlow
APP_VERSION=1.0.0
ENVIRONMENT=production
DEBUG_MODE=false
ENABLE_LOGGING=false
```

### 6. Instalar Dependências

Execute no terminal do projeto:

```bash
flutter pub get
```

### 7. Criar Tabelas no Supabase (Opcional)

Se quiser usar o banco de dados, vá no **SQL Editor** do Supabase e execute:

```sql
-- Criar tabela de tarefas
CREATE TABLE tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT,
  due_date TIMESTAMP WITH TIME ZONE,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS (Row Level Security)
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Política para permitir acesso público (para desenvolvimento)
CREATE POLICY "Permitir acesso público" ON tasks
FOR ALL USING (true);

-- Criar bucket para upload de arquivos (opcional)
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
```

### 8. Testar Configuração

Rode o app e observe o console. Você deve ver:

```
✅ ConfigService - Variáveis de ambiente carregadas
🔧 ConfigService - Validando configurações...
   isInitialized: true
   appName: TaskFlow
   hasValidSupabaseConfig: true
✅ ConfigService - Configurações válidas!
```

### 9. Exemplo de Uso no App

```dart
// Inicializar Supabase (já está no main.dart)
await SupabaseService.initialize();

// Criar uma tarefa
final task = await SupabaseService.createTask(
  title: 'Minha primeira tarefa',
  description: 'Testar integração com Supabase',
  category: 'Trabalho',
);

// Buscar todas as tarefas
final tasks = await SupabaseService.getTasks();
print('Tarefas encontradas: ${tasks.length}');
```

## 🔒 Segurança

- ✅ **NUNCA** commite o arquivo `.env` ou `.env.production`
- ✅ **SEMPRE** use apenas a chave `anon/public` no frontend
- ✅ A chave `service_role` deve ser usada apenas no backend
- ✅ Configure RLS (Row Level Security) nas tabelas para produção
- ✅ O arquivo `.env.example` pode ser commitado (é só um template)

## 🆘 Solução de Problemas

### Erro: "Configuração do Supabase inválida"
- Verifique se o arquivo `.env` existe
- Confirme que `SUPABASE_URL` e `SUPABASE_ANON_KEY` estão preenchidos
- A URL deve começar com `https://` e terminar com `.supabase.co`

### Erro: "Target of URI doesn't exist: supabase_flutter"
- Execute `flutter pub get` para instalar as dependências

### App não conecta com Supabase
- Verifique se a URL e chave estão corretas
- Teste a URL no navegador - deve abrir uma página do Supabase
- Verifique a conexão com internet

## 📚 Próximos Passos

Após configurar, você pode:

1. **Integrar com TaskService**: Fazer o TaskService salvar tarefas no Supabase
2. **Upload de Avatar**: Usar o SupabaseService.uploadFile() para avatares
3. **Sincronização**: Sincronizar tarefas entre dispositivos
4. **Backup Automático**: Backup das tarefas na nuvem
5. **Autenticação**: Adicionar login de usuários (opcional)

**🎉 Sucesso! Seu TaskFlow agora está configurado com Supabase!**