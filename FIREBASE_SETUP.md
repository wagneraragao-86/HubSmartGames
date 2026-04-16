# Hub Smart Games - Firebase Setup

Este projeto agora inclui integração com Firebase para autenticação com Google e armazenamento de dados na nuvem.

## Configuração do Firebase

### 1. Criar projeto no Firebase Console

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Clique em "Criar um projeto" ou selecione um projeto existente
3. Siga os passos para criar o projeto

### 2. Configurar Autenticação

1. No menu lateral, clique em "Authentication"
2. Vá para a aba "Sign-in method"
3. Ative o provedor "Google"
4. Configure as informações necessárias

### 3. Configurar Firestore Database

1. No menu lateral, clique em "Firestore Database"
2. Clique em "Criar banco de dados"
3. Escolha "Iniciar no modo de teste" (para desenvolvimento)
4. Selecione uma localização para o banco de dados

### 4. Configurar plataformas

#### Android:
1. No Firebase Console, clique no ícone Android
2. Package name: `com.example.hubsmartgames` (verifique no android/app/build.gradle)
3. Baixe o arquivo `google-services.json`
4. Coloque o arquivo na pasta `android/app/`

#### iOS:
1. No Firebase Console, clique no ícone iOS
2. Bundle ID: `com.example.hubsmartgames` (verifique no ios/Runner.xcodeproj)
3. Baixe o arquivo `GoogleService-Info.plist`
4. Coloque o arquivo na pasta `ios/Runner/`

#### Web:
1. No Firebase Console, clique no ícone Web
2. Registre o app com um nome
3. Copie as configurações do Firebase
4. Cole as configurações no arquivo `web/index.html` dentro da tag `<body>`

### 5. Executar o app

Após configurar todas as plataformas, execute:

```bash
flutter run
```

## Funcionalidades do Firebase

- **Autenticação com Google**: Login seguro usando conta Google
- **Armazenamento na nuvem**: Scores e progresso salvos no Firestore
- **Rankings globais**: Compita com jogadores de todo o mundo
- **Sincronização**: Dados locais são sincronizados automaticamente

## Estrutura dos dados no Firestore

### Coleção: `players`
```json
{
  "id": "user_uid",
  "name": "Nome do Jogador",
  "avatar": "url_da_foto",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "friendIds": ["friend_id_1", "friend_id_2"]
}
```

### Coleção: `scores`
```json
{
  "id": "score_id",
  "gameId": "snake",
  "playerId": "user_uid",
  "playerName": "Nome do Jogador",
  "points": 1500,
  "date": "2024-01-01T00:00:00.000Z",
  "userId": "firebase_user_id",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Desenvolvimento

Para desenvolvimento local sem Firebase, o app ainda funciona com armazenamento local (Hive). A sincronização com Firebase acontece automaticamente quando o usuário está logado.