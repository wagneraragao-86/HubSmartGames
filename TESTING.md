# Guia de Testes e Debugging

## Executar a Aplicação

### Debug no Android
```bash
flutter run -v
```

### Release no Android
```bash
flutter run --release
```

### Debug no iOS (macOS)
```bash
flutter run -d macos
```

### Debug na Web
```bash
flutter run -d chrome
```

## Testes Unitários

Para criar testes unitários, crie arquivos em `test/`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_smart_games/games/snake_game.dart';

void main() {
  group('Snake Game Tests', () {
    late SnakeGame game;

    setUp(() {
      game = SnakeGame();
    });

    test('Snake starts with correct position', () {
      expect(game.snake.length, 1);
      expect(game.snake.first.x, 10);
      expect(game.snake.first.y, 10);
    });

    test('Direction changes work correctly', () {
      game.changeDirection(Direction.up);
      expect(game.nextDirection, Direction.up);
    });

    test('Game over on self collision', () {
      // Implementar teste de colisão
    });

    test('Score increases when eating food', () {
      final initialScore = game.score;
      // Mover a cobra para comer comida
      game.update();
      // Verificar pontos
    });
  });
}
```

Execute testes com:
```bash
flutter test
```

## Debugging de Layout

### Ativar Visual Debugger
```bash
flutter run --debug --enable-debug-ui
```

### Inspecionar Widget Tree
```dart
// No código:
debugPrintBeginFrame = true;
debugPrintEndFrame = true;
```

## Ferramentas de Debug

### DevTools
```bash
flutter pub global activate devtools
devtools
```

Depois, abra http://localhost:9100 e conecte seu app.

### Logs Detalhados
```dart
import 'package:flutter/material.dart';

class DebugLog {
  static void log(Object message) {
    debugPrint('🐛 $message');
  }
  
  static void error(Object message) {
    debugPrint('❌ ERROR: $message');
  }
  
  static void success(Object message) {
    debugPrint('✅ SUCCESS: $message');
  }
}

// Usar:
DebugLog.log('Estado do jogo atualizado');
```

## Checklist de Testes Manual

### Fluxo de Criação de Jogador
- [ ] Criar novo jogador
- [ ] Verificar se jogador foi salvo
- [ ] Alternar entre jogadores
- [ ] Editar nome do jogador
- [ ] Deletar jogador

### Snake Game
- [ ] Iniciar jogo
- [ ] Cobra se move na direção correta
- [ ] Cobra pode comer comida
- [ ] Score aumenta
- [ ] Nível aumenta a cada 50 pontos
- [ ] Verificar velocidade em diferentes níveis
- [ ] Testar pause/resume
- [ ] Colisão com parede funciona (wrap)
- [ ] Colisão com corpo termina jogo
- [ ] Score é salvo corretamente

### Torre de Hanói
- [ ] Iniciar jogo
- [ ] Movimentos válidos funcionam
- [ ] Movimentos inválidos mostram feedback
- [ ] Posição no ranking atualiza
- [ ] Jogo termina quando resolvido
- [ ] Pontuação é calculada corretamente
- [ ] Score é salvo corretamente
- [ ] Botão Resetar funciona
- [ ] Botão Desfazer funciona (quando implementado)

### Leaderboards
- [ ] Ranking Geral mostra em ordem correta
- [ ] Ranking Semanal filtra dados corretamente
- [ ] Ranking de Amigos mostra amigos
- [ ] Posição do jogador é destacada
- [ ] Medais aparecem para top 3
- [ ] Todos os scores aparecem quando não há filtro

### Persistência
- [ ] Dados são salvos após jogar
- [ ] Dados persistem após fechar app
- [ ] Múltiplos jogadores têm dados separados
- [ ] Scores antigos não são perdidos

## Performance Testing

### Medir Frame Rate
```dart
void measurePerformance() {
  final sw = Stopwatch()..start();
  
  // Código a medir
  game.update();
  
  sw.stop();
  debugPrint('Tempo: ${sw.elapsedMilliseconds}ms');
}
```

### Memory Profiling
Use DevTools Memory tab para:
- Detectar memory leaks
- Monitorar alocação
- Forçar garbage collection

## Problemas Conhecidos e Soluções

### Problema: App não inicia
**Solução:**
```bash
flutter clean
flutter pub get
flutter run
```

### Problema: Scores não são salvos
**Verificação:**
1. Confirmar que `StorageService.initialize()` foi chamado
2. Verificar permissões de storage
3. Validar estrutura de dados

### Problema: Rankings estão vazios
**Verificação:**
1. Verificar se existem scores no banco de dados
2. Confirmar IDs de jogos estão corretos
3. Debugar LeaderboardService

## Hot Reload / Hot Restart

### Hot Reload (mantém state)
Pressione `r` no terminal durante debug

Útil para:
- Mudar UIElement
- Testar diferentes layouts
- Ajustar cores

### Hot Restart (reseta state)
Pressione `R` no terminal durante debug

Necessário para:
- Mudanças em providers
- Mudanças em modelos
- Reinicializar dados

## Logging Avançado

```dart
// Adicionar logger:
import 'package:flutter/foundation.dart';

class GameLogger {
  static void logGameStart(String gameId, String playerId) {
    if (kDebugMode) {
      print('🎮 Game Started: $gameId by $playerId at ${DateTime.now()}');
    }
  }

  static void logScore(int points) {
    if (kDebugMode) {
      print('⭐ Score: $points');
    }
  }

  static void logGameEnd(String gameId, int score) {
    if (kDebugMode) {
      print('🏁 Game Ended: $gameId - Final Score: $score');
    }
  }
}
```

## Monitorar State Changes

```dart
// Usar observer de Provider:
class MyObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object newValue,
    ProviderContainer container,
  ) {
    print('Provider $provider changed: $previousValue -> $newValue');
  }
}
```

---

Para mais informações, consulte a [Documentação Oficial do Flutter](https://flutter.dev/docs/testing)
