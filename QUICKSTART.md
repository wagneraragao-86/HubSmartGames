# 🚀 Quick Start - Hub Smart Games

## ⚡ Iniciar em 5 Minutos

### 1. Preparar Ambiente
```bash
cd c:/Users/wagner.aragao/HubSmartGames
flutter pub get
```

### 2. Rodar no Emulador/Device
```bash
flutter run -v
```

### 3. Testar no App
- Criar um novo jogador
- Jogar Snake ou Torre de Hanói
- Ver rankings

## 📱 Controles dos Jogos

### Snake 🐍
- **Setas**: Mover cobra
- **Pausa**: Pausar/resumir
- **Objetivo**: Comer comida vermelha, não bater no corpo
- **Pontos**: 10 + bônus de nível

### Torre de Hanói 🗼
- **Tap Torre 1-3**: Selecionar/mover disco
- **Objetivo**: Mover todos os discos para torre 3
- **Ótimo**: Se conseguir em 7 movimentos

## 📊 Onde Ver Rankings

1. Abra o app
2. Selecione um jogador
3. Clique na aba **Rankings**
4. Escolha o jogo
5. Veja: Geral, Semanal ou Amigos

## 🎮 Testar Novo Jogo

### Template (copie e adapte)
```dart
// file: lib/games/novo_jogo.dart
class NovoJogo {
  int score = 0;
  DateTime gameStartTime = DateTime.now();
  
  void update() {
    // Lógica aqui
  }
  
  Map<String, dynamic> getGameStats() {
    return {'score': score, 'duration': ...};
  }
}
```

Depois siga o guia completo em **DEVELOPMENT.md**

## 📚 Documentação

| Documento | Para Quem |
|-----------|-----------|
| **README.md** | Usuários finais |
| **DEVELOPMENT.md** | Devs adicionando features |
| **TESTING.md** | QA e debugging |
| **ROADMAP.md** | PM e planejamento |
| **PROJECT_SUMMARY.md** | Visão geral técnica |

## 🔧 Troubleshoot Rápido

### App não abre?
```bash
flutter clean
flutter pub get
flutter run
```

### Emulador não funciona?
```bash
flutter devices  # ver disponíveis
flutter run -d <id>  # executar em device específico
```

### Dados não salvam?
```bash
# Abra app, faça algo, feche
# Reabra - dados devem estar lá
# Se não: verificar permissões em Android/iOS
```

## 🎯 Primeiras Tasks

- [ ] Jogar Snake e contar pontos
- [ ] Resolver Torre de Hanói
- [ ] Criar 2-3 Jogadores
- [ ] Comparar rankings
- [ ] Ler DEVELOPMENT.md
- [ ] Adicionar novo jogo

## 💡 Dicas Rápidas

```bash
# Hot reload durante desenvolvimento
Pressione 'r' no terminal

# Ver todas as loções
flutter logs

# Carregar no seu telefone
flutter run -v
# Conecte via USB com debug ativado

# Build release
flutter build apk --release
```

## 🎨 Customizações Rápidas

### Mudar cor primária
Abra `lib/main.dart`, na seção `theme:`:
```dart
ThemeData(
  primarySwatch: Colors.green,  // mude aqui
  ...
)
```

### Mudar nome do app
`pubspec.yaml`:
```yaml
name: novo_nome_app
```

### Adicionar novo idioma
Já suporta intl, veja em DEVELOPMENT.md

## 📞 Ajuda Rápida

**Erro na análise?**
```bash
flutter analyze
```

**Precisa limpar tudo?**
```bash
flutter clean
flutter pub get
flutter run
```

**Quer ver performance?**
```bash
flutter run --profile
# Durante execução: 'p'
```

## 🎉 Parabéns!

Seu app está pronto para:
✅ Desenvolvimento local
✅ Testes
✅ Build para device
✅ Publicação na Play Store

---

**Próximo**: Leia DEVELOPMENT.md para adicionar novos jogos!

**Quando estiver pronto para produção**, execute:
```bash
flutter build apk --release
flutter build appbundle --release  # para Play Store
```
