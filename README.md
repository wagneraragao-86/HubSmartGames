# Hub Smart Games

Um aplicativo mobile desenvolvido em Flutter para um hub de jogos com suporte a offline e online com ranking de pontuações.

## 🎮 Jogos Disponíveis

- **Snake**: O clássico jogo da cobrinha com sistema de níveis progressivos
- **Torre de Hanói**: Quebra-cabeça clássico com pontuação baseada em eficiência
- **Hidro flux**: puzzle de canos para chegar em um determinado destino

## ✨ Funcionalidades

### Jogos
- ✅ Jogo Snake com níveis e pontuação dinâmica
- ✅ Torre de Hanói com cálculo de eficiência
- ✅ Hidro flux com contagem de movimentos 
- ✅ Funcionamento offline
- ✅ Salva automático de scores

### Rankings
- ✅ Ranking Geral (todos os tempos)
- ✅ Ranking Semanal (últimas 7 dias)
- ✅ Ranking entre Amigos
- ✅ Estatísticas do jogador
- ✅ Top 10 scores

### Gerenciamento de Jogadores
- ✅ Criar múltiplos perfis de jogadores
- ✅ Sistema de amigos
- ✅ Persistência local de dados

## 📱 Requisitos

- Flutter 3.0+
- Dart 3.0+
- iOS 11+ ou Android 6.0+

## 🚀 Instalação

1. Clone o repositório:
```bash
git clone <https://github.com/wagneraragao-86/HubSmartGames.git>
cd HubSmartGames
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Execute o app:
```bash
flutter run
```

## 📦 Estrutura do Projeto

```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models (Game, Player, Score)
├── services/                 # StorageService, LeaderboardService
├── providers/                # State management (Provider)
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── player_selection_screen.dart
│   ├── games_hub_screen.dart
│   ├── leaderboard_screen.dart
│   └── games/
│       ├── snake_screen.dart
│       └── hanoi_screen.dart
├── games/                    # Game logic
│   ├── snake_game.dart
│   └── hanoi_game.dart
└── widgets/                  # Reusable widgets
```

## 🎯 Como Usar

1. **Criar um Jogador**: Na tela inicial, preencha o nome e clique em "Criar Jogador"
2. **Selecionar Jogador**: Escolha entre jogadores existentes ou crie um novo
3. **Escolher Jogo**: Selecione o jogo desejado no Hub
4. **Jogar**: Use os controles da interface para jogar
5. **Ver Rankings**: Acesse a aba "Rankings" para ver os leaderboards

## 🎮 Controles

### Snake
- Setas direcionais para mover
- Botão de pausa para pausar/retomar
- Evite colidir com o corpo da cobra
- Coma a comida vermelha para ganhar pontos

### Torre de Hanói
- Toque em uma torre para selecionar um disco
- Toque em outra torre para mover
- Resolva o quebra-cabeça no menor número de movimentos possível

## 🔧 Dependências Principais

- **provider**: State management
- **hive & hive_flutter**: Persistent local storage
- **uuid**: ID generation
- **intl**: Internationalization

## 📊 Sistema de Pontuação

### Snake
- Base: 10 pontos por comida
- Bônus: Aumenta com o nível
- Todos os níveis somam para o score total

### Torre de Hanói
- Base: 500 pontos
- Penalidade: 10 pontos por movimento acima do ideal
- Mínimo: 50 pontos

## 🚀 Roadmap

- [ ] Sistema de amigos online
- [ ] Integração com Firebase para rankings online
- [ ] Mais jogos (2048, Sudoku, etc)
- [ ] Achievements e badges
- [ ] Sistema de skins customizáveis
- [ ] Modo multijogador local
- [ ] Temas personalizados

## 📝 Licença

MIT - Sinta-se livre para usar e modificar este projeto

## 👨‍💻 Contribuições

Contribuições são bem-vindas! Por favor, abra uma issue ou pull request para sugerir mudanças.

---

Desenvolvido com ❤️ em Flutter
