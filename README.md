# FNF Online (inicial)

Engine de Friday Night Funkin' online em Haxe (HaxeFlixel) + WebSocket (`haxe-ws`).
Os assets (Codename Engine) ficam em `assets/` - so o basico. Veja os creditos do Codename Engine.

## Telas
- **Main Menu**: Freeplay e Skins (+ status da conexao)
- **Skins**: escolhe bf / bf-pixel / pico; salva e manda pro servidor
- **Freeplay**: esquerda = musicas (TREINO offline ou SALA online); direita = partidas abertas (toque para entrar) e jogadores online
- **PlayState**: toque nas 4 colunas (ou D F J K / setas). Voce joga no centro; o oponente aparece com a skin dele, mini setas acendem quando ele acerta
- **Resultados**: pontos, acerto, erros e vencedor

## Rodar o servidor (precisa de Node 18+)
    cd server && npm install && npm start
Hospede em Render/Railway/Fly (qualquer um que rode Node). Depois edite `assets/server.txt`
com o endereco, ex.: `ws://meu-servidor.onrender.com`  (veja a nota sobre wss no chat)

## Build Android
Push no GitHub -> aba Actions -> "Android Build" -> baixe o artefato `FNFOnline-apk`.

## Protocolo (JSON)
cliente -> servidor: hello, skin, create, join, leave, n {lane,r,score}, finish, ping
servidor -> cliente: welcome, lobby, start, opp, oppLeft, result
