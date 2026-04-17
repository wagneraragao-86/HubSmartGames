class Game {
  final String id;
  final String name;
  final String description;
  final String icon;

  const Game({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  static List<Game> getAvailableGames() {
    return [
      Game(
        id: 'snake',
        name: 'Snake',
        description: 'Clássico jogo da cobrinha',
        icon: '🐍',
      ),
      Game(
        id: 'hanoi',
        name: 'Torre de Hanói',
        description: 'Quebra-cabeça clássico',
        icon: '🗼',
      ),
      Game(
        id: 'hidro_flux',
        name: 'Hidro Flux',
        description: 'Conecte canos e faça o líquido fluir',
        icon: '💧',
      ),
      Game(
        id: 'reaction',
        name: 'Reação',
        description: 'Teste seu tempo de resposta',
        icon: '⚡',
      ),
    ];
  }
}
