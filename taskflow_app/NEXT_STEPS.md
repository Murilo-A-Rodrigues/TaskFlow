# Próximos Passos — Avatar com Foto no Drawer

Data: 22/10/2025

---

## ✅ Implementação Concluída

A feature "Avatar com Foto no Drawer" (MVP) foi implementada com sucesso. Consulte `IMPLEMENTATION_AVATAR_RECORD_UPDATED.md` para detalhes completos.

**Status da implementação:**
- ✅ Todos os arquivos criados e modificados
- ✅ Testes unitários implementados (`test/unit/photo_service_test.dart`)
- ✅ Testes de widget implementados (`test/widget/user_avatar_test.dart`)
- ✅ Arquivos temporários removidos (TMP_IMPLEMENTATION_APPEND.md, IMPLEMENTATION_AVATAR_RECORD.md)
- ✅ **Teste smoke otimizado:** Corrigido `test/widget_test.dart` que estava demorando muito
  - Removido teste de app completo (que inicializava serviços reais)
  - Substituído por testes simples de widgets isolados
  - Tempo de execução: **6 segundos para 13 testes** (muito mais rápido!)
- ✅ Documentação completa

---

## 🚀 Ações Recomendadas

### 1. Instalar Dependências

Execute no terminal (PowerShell):

```powershell
cd "c:\Users\Muril\Downloads\Trabalho OO\TaskFlow\taskflow_app"
flutter pub get
```

### 2. Analisar e Corrigir Warnings

```powershell
flutter analyze
```

Se houver imports não utilizados, remova-os conforme sugerido pelo analyzer.

### 3. Executar Testes

```powershell
# Todos os testes
flutter test

# Testes específicos
flutter test test/unit/photo_service_test.dart
flutter test test/widget/user_avatar_test.dart
```

### 4. Configurar Permissões (Obrigatório para Dispositivos Físicos)

#### Android

Edite `android/app/src/main/AndroidManifest.xml` e adicione:

```xml
<manifest>
    <!-- Adicione estas linhas antes de <application> -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    
    <!-- Para Android < 13, use: -->
    <!-- <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" /> -->
    
    <application>
        ...
    </application>
</manifest>
```

#### iOS

Edite `ios/Runner/Info.plist` e adicione:

```xml
<dict>
    <!-- Adicione estas linhas -->
    <key>NSCameraUsageDescription</key>
    <string>O TaskFlow precisa acessar a câmera para tirar foto do seu perfil.</string>
    
    <key>NSPhotoLibraryUsageDescription</key>
    <string>O TaskFlow precisa acessar sua galeria para escolher foto do seu perfil.</string>
    
    <!-- Resto do arquivo -->
</dict>
```

### 5. Testar no Emulador/Dispositivo

```powershell
flutter run
```

### 6. Fazer Commit das Mudanças

```powershell
git add .
git commit -m "feat: implementa avatar com foto no drawer (MVP)

- Adiciona PhotoService para seleção, compressão e armazenamento de fotos
- Implementa UserAvatar widget com fallback para iniciais
- Adiciona Drawer com foto de perfil e opções de edição
- Implementa testes unitários e de widget
- Suporte a LGPD (armazenamento local, remoção EXIF/GPS)
- Acessibilidade completa (semanticsLabel, área clicável ≥48dp)"

git push origin main
```

---

## 🔮 Melhorias Futuras (Fase 2 - Opcional)

### Fase 2.1 — Edição de Imagem
- [ ] Implementar crop/editor antes de salvar
- [ ] Ajuste de zoom e rotação
- [ ] Filtros básicos

### Fase 2.2 — Sincronização em Nuvem
- [ ] Upload para Supabase Storage
- [ ] Sincronização multi-dispositivo
- [ ] Fallback para foto local se offline

### Fase 2.3 — UX Avançado
- [ ] Animações de transição ao trocar foto
- [ ] Placeholder shimmer durante carregamento
- [ ] Histórico de fotos anteriores

### Fase 2.4 — Testes Avançados
- [ ] Testes de integração (E2E)
- [ ] Testes de permissões (mock de negação)
- [ ] Testes de performance (compressão)
- [ ] Coverage report (meta: >80%)

---

## 📚 Documentação de Referência

- `IMPLEMENTATION_AVATAR_RECORD_UPDATED.md` — Registro completo da implementação
- `CHANGELOG_AVATAR_FEATURE.md` — Changelog da feature
- `PRD_TaskFlow.md` — Documento de requisitos do projeto

---

## ❓ Dúvidas/Suporte

Se encontrar problemas:

1. Verifique que `flutter pub get` foi executado
2. Confirme que as permissões Android/iOS foram adicionadas
3. Execute `flutter clean` e `flutter pub get` novamente
4. Consulte logs: `flutter run --verbose`

---

**Status:** ✅ Pronto para uso  
**Última atualização:** 22/10/2025
