# Guia Rápido de Desenvolvimento

## Estrutura do Projeto

```
lib/
├── main.dart                           # Inicialização da app
├── models/                             # Modelos de dados
│   ├── game.dart                       # Modelo de Jogo
│   ├── player.dart                     # Modelo de Jogador
│   ├── score.dart                      # Modelo de Pontuação
│   └── index.dart                      # Exports
├── services/                           # Serviços de dados
│   ├── storage_service.dart            # Gerenciamento local de dados (Hive)
│   └── leaderboard_service.dart        # Lógica de rankings
├── providers/                          # State Management (Provider)
│   ├── player_provider.dart            # Gerenciamento de jogadores
│   └── score_provider.dart             # Gerenciamento de scores
├── screens/                            # Telas da aplicação
│   ├── home_screen.dart                # Tela inicial
│   ├── player_selection_screen.dart    # Seleção/criação de jogador
│   ├── games_hub_screen.dart           # Hub principal de jogos
│   ├── leaderboard_screen.dart         # Telas de rankings
│   └── games/
│       ├── snake_screen.dart           # Tela do Snake
│       └── hanoi_screen.dart           # Tela da Torre de Hanói
├── games/                              # Lógica dos jogos
│   ├── snake_game.dart                 # Lógica do Snake
│   └── hanoi_game.dart                 # Lógica da Torre de Hanói
└── widgets/                            # Widgets reutilizáveis
```

## Dependências Principais

- **provider (6.0.0)**: State management reactivo
- **hive & hive_flutter (2.2.0+)**: Banco de dados local
- **uuid (4.0.0)**: Geração de IDs únicos
- **intl (0.19.0)**: Internacionalização

## Como Adicionar um Novo Jogo

### 1. Criar a Lógica do Jogo
Crie um novo arquivo em `lib/games/novo_jogo.dart`:

```dart
class NovoJogo {
  int score = 0;
  bool isGameOver = false;
  DateTime gameStartTime = DateTime.now();

  void update() {
    // Lógica do jogo
  }

  Map<String, dynamic> getGameStats() {
    return {
      'score': score,
      'duration': DateTime.now().difference(gameStartTime).inSeconds,
    };
  }
}
```

### 2. Criar a Tela do Jogo
Crie um novo arquivo em `lib/screens/games/novo_jogo_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../games/novo_jogo.dart';
import '../../models/score.dart';
import '../../providers/score_provider.dart';
import '../../providers/player_provider.dart';

class NovoJogoScreen extends StatefulWidget {
  const NovoJogoScreen({Key? key}) : super(key: key);

  @override
  State<NovoJogoScreen> createState() => _NovoJogoScreenState();
}

class _NovoJogoScreenState extends State<NovoJogoScreen> {
  late NovoJogo game;

  @override
  void initState() {
    super.initState();
    game = NovoJogo();
  }

  void _saveScore() {
    final playerProvider = context.read<PlayerProvider>();
    final scoreProvider = context.read<ScoreProvider>();
    
    if (playerProvider.currentPlayer != null) {
      final score = Score(
        playerId: playerProvider.currentPlayer!.id,
        playerName: playerProvider.currentPlayer!.name,
        gameId: 'novo_jogo', // ID único do jogo
        points: game.score,
        duration: game.getGameStats()['duration'],
      );
      scoreProvider.saveScore(score);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Jogo'),
      ),
      body: Center(
        child: Text('Score: ${game.score}'),
      ),
    );
  }
}
```

### 3. Adicionar à Lista de Jogos
Edite `lib/models/game.dart`:

```dart
static List<Game> getAvailableGames() {
  return [
    // ... jogos existentes ...
    Game(
      id: 'novo_jogo',
      name: 'Nome do Jogo',
      description: 'Descrição',
      icon: '🎮',
    ),
  ];
}
```

### 4. Adicionar Navegação
Edite `lib/screens/games_hub_screen.dart` no método `_navigateToGame`:

```dart
void _navigateToGame(BuildContext context, Game game) {
  Widget screen;
  switch (game.id) {
    case 'snake':
      screen = const SnakeScreen();
      break;
    case 'hanoi':
      screen = const HanoiScreen();
      break;
    case 'novo_jogo':
      screen = const NovoJogoScreen();
      break;
    default:
      return;
  }
  // ...
}
```

## Sistema de Pontuação

### Snake
- Base: 10 pontos por comida
- Bônus de nível: Multiplicador baseado no nível atual
- Níveis aumentam a cada 50 pontos

### Torre de Hanói
- Base: 500 pontos
- Penalidade: 10 pontos por movimento acima do ideal
- Pontuação mínima: 50 pontos
- Exemplo: Se ideal é 7 movimentos e fez 15 → 500 - (15-7)*10 = 420 pontos

### Personalizando a Pontuação
Customize a lógica no método `_calculateScore()` da tela do jogo.

## Persistência de Dados

### Salvar um Score
```dart
final score = Score(
  playerId: player.id,
  playerName: player.name,
  gameId: 'snake',
  points: 1500,
  duration: 120,
);
scoreProvider.saveScore(score);
```

### Recuperar Scores
```dart
final scores = scoreProvider.getScoresByGameAndPlayer('snake', playerId);
final bestScore = scoreProvider.getBestScore('snake', playerId);
```

## Rankings

### Ranking Geral
```dart
final leaderboard = leaderboardService.getGeneralLeaderboard('snake');
```

### Ranking Semanal
```dart
final weeklyLeaderboard = leaderboardService.getWeeklyLeaderboard('snake');
```

### Ranking de Amigos
```dart
final friendsLeaderboard = leaderboardService.getFriendsLeaderboard(
  'snake',
  friendNames,
);
```

## Debugging

### Ver todos os scores salvos
```dart
final storage = context.read<StorageService>();
final allScores = storage.getAllScores();
print(allScores);
```

### Limpar dados (cuidado!)
```dart
await storage.close();
// Apague o app e reinstale, ou use:
// Hive.deleteBoxFromDisk('scores');
```

## Temas e Customização

O tema está definido em `lib/main.dart`. Para customizar cores:

```dart
theme: ThemeData(
  primarySwatch: Colors.blue,      // Cor primária
  scaffoldBackgroundColor: const Color(0xFF0A0E27), // Fundo
  brightness: Brightness.dark,     // Tema escuro
),
```

## Performance

- Scores são carregados na memória ao iniciar
- Operações de banco de dados são assíncronas
- Use `Consumer` para widgets que precisam de state updates
- Para listas grandes, considere usar `ListView.builder`

## Próximas Funcionalidades Sugeridas

1. Sistema de amigos online
2. Cloud sync com Firebase
3. Achievements e badges
4. Skins personalizáveis
5. Multiplayer local
6. Temas customizáveis
7. Replay de gameplay

---

Para dúvidas, consulte o README.md ou a estrutura dos códigos existentes!
