# Roadmap de Desenvolvimento

## Versão 1.0 (Atual)
✅ **Completado**
- ✅ Jogo Snake com níveis progressivos
- ✅ Torre de Hanói com cálculo de eficiência
- ✅ Sistema de múltiplos jogadores
- ✅ Persistência local com Hive
- ✅ Rankings (Geral, Semanal, Amigos)
- ✅ Leaderboards com estatísticas
- ✅ Sistema de pontuação personalizado
- ✅ Interface dark mode completa

## Versão 1.1 (Próximo Lançamento)
📋 **Planejado**
- [ ] Sistema de amigos com adição manual
- [ ] Estatísticas expandidas por jogador
- [ ] Gráficos de progresso (charts)
- [ ] Achievements simples
- [ ] Sons e efeitos sonoros
- [ ] Vibrações/Haptics
- [ ] Tema light mode
- [ ] Configurações de dificuldade personalizável

## Versão 1.2 (Medium-term)
📋 **Em Consideração**
- [ ] Multiplayer local (passaporte de controle)
- [ ] Modo competitivo local
- [ ] Gravação de replays
- [ ] Sistema de skins personalizáveis
- [ ] Backgrounds temáticos
- [ ] Mais jogos:
  - [ ] 2048
  - [ ] Flappy Bird
  - [ ] Sudoku
  - [ ] Puzzle
  - [ ] Jogo da Memória

## Versão 2.0 (Long-term)
🌐 **Online & Cloud**
- [ ] Integração com Firebase
- [ ] Sincronização em nuvem
- [ ] Rankings globais online
- [ ] Sistema de friends online
- [ ] Multiplayer online em tempo real
- [ ] Chat com amigos
- [ ] Notificações push
- [ ] Autenticação com Google/Apple
- [ ] Sistema de clã/grupos

## Versão 2.1+ (Futuro Distante)
🚀 **Inovações**
- [ ] IA para se jogar contra o computador
- [ ] Modos cooperativos
- [ ] Battle Royale (competição en tempo real)
- [ ] Torneios e eventos
- [ ] Shop in-game com moedas virtuais
- [ ] Season passes
- [ ] Crossplay entre plataformas
- [ ] Streaming integrado (Twitch)

---

## Implementações Recomendadas por Prioridade

### Curto Prazo (1-2 semanas)
1. **Sistema de Amigos v1**
   - Adicionar amigos manualmente
   - Visualizar scores de amigos
   - Criar lista de favoritos

2. **Som e Efeitos**
   - Som de pontuação
   - Som de game over
   - BGM durante gameplay
   - Toggle de som nas configurações

3. **Configurações Básicas**
   - Volume de som
   - Dificuldade do Snake
   - Tema (claro/escuro)
   - Notificações

### Médio Prazo (1 mês)
1. **Novo Jogo: 2048**
   - Mecânica de fusão de tiles
   - Pontuação dinâmica
   - Histórico de tentativas

2. **Achievements**
   - Sistema de badges
   - Primeiras conquistas básicas
   - Exibição no perfil

3. **Gráficos e Visualizações**
   - Chart de progresso semanal
   - Estatísticas avançadas
   - Comparação com amigos

### Longo Prazo (Trimestre)
1. **Backend Firebase**
   - Autenticação
   - Banco de dados
   - Sincronização em nuvem

2. **Multiplayer Local**
   - Modo vs. até 4 jogadores
   - Placar compartilhado
   - Turnos simultâneos

3. **Store de Skins**
   - Editor de cores
   - Temas customizáveis
   - Sistema de compra

---

## Tecnologias a Integrar

### Near Future
```yaml
dependencies:
  just_audio: ^0.9.0          # Áudio
  fl_chart: ^0.64.0           # Gráficos
  shared_preferences: ^2.0.0  # Configurações
  permission_handler: ^11.0.0 # Permissões
```

### Medium Future
```yaml
dependencies:
  firebase_core: ^2.24.0      # Firebase
  firebase_auth: ^4.14.0      # Autenticação
  cloud_firestore: ^4.13.0    # Database
  firebase_analytics: ^10.7.0  # Analytics
```

### Long Future
```yaml
dependencies:
  agora_rtc_engine: ^6.0.0    # Multiplayer
  freezed: ^2.0.0             # Code generation
  go_router: ^12.0.0          # Routing avançado
  riverpod: ^2.0.0            # State management upgrade
```

---

## Métricas de Sucesso

### Versão 1.0
- ✅ 2 jogos funcionais
- ✅ Sistema de rankings
- ✅ Sem crashes
- ✅ Tamanho do APK < 50MB

### Versão 1.1
- [ ] 3+ amigos por jogador
- [ ] Média de 2+ minutos por sessão
- [ ] 0 crashes críticos
- [ ] Tamanho do APK < 60MB

### Versão 2.0
- [ ] 1000+ usuários ativos
- [ ] Online multiplayer estável
- [ ] Servidor com < 100ms latência
- [ ] Taxa de retenção: 40%

---

## Como Contribuir Novas Funcionalidades

### 1. Abrir uma Issue
Descreva a feature desejada com:
- Problema que resolve
- Como funciona
- Exemplo de uso

### 2. Discutir Design
- Revisar impacto no code
- Considerar alternativas
- Validar com usuários

### 3. Implementação
- Criar branch feature
- Seguir code style
- Adicionar testes
- Documentar mudanças

### 4. Code Review
- Validar qualidade
- Performance checks
- Testes de compatibilidade

### 5. Merge e Deploy
- Merge para main
- Versionar app
- Release notes
- Testear em devices reais

---

## Issues Conhecidas a Resolver

1. **Snake**: Às vezes a cobra não responde imediatamente (delay?)
2. **Hanói**: Desfazer não está implementado
3. **Performance**: Uma lista de 1000+ scores fica lento
4. **UI**: Responsividade em tablets não foi testada
5. **Acessibilidade**: Sem suporte a screen readers ainda

---

## Agradecimentos

Este é um projeto open-source. Qualquer contribuição é bem-vinda! 🎮

---

Última atualização: Abril 2026
Mantido por: Wagner Aragão
