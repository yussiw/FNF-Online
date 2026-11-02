// Servidor WebSocket do FNF Online. Uso: npm install && npm start  (porta 8080 ou $PORT)
const { WebSocketServer } = require("ws");

const PORT = process.env.PORT || 8080;
const SONGS = new Set(["bopeebo", "fresh", "dadbattle"]);
const wss = new WebSocketServer({ port: PORT });

let nextId = 1;
let nextRoom = 1;
const players = new Map(); // ws -> player
const rooms = new Map(); // id -> room

const send = (ws, o) => {
  if (ws.readyState === 1) ws.send(JSON.stringify(o));
};
const clean = (s, max, fallback) =>
  typeof s === "string" && s.trim() ? s.trim().slice(0, max) : fallback;

function lobbyFor(p) {
  return {
    t: "lobby",
    mine: p.room ? p.room.id : null,
    players: [...players.values()].map((x) => ({ name: x.name, skin: x.skin, busy: !!(x.room && x.room.state === "playing") })),
    rooms: [...rooms.values()]
      .filter((r) => r.state === "waiting")
      .map((r) => ({ id: r.id, song: r.song, host: r.players[0].name, skin: r.players[0].skin })),
  };
}

function broadcastLobby() {
  for (const p of players.values()) send(p.ws, lobbyFor(p));
}

function closeRoom(room, leaver) {
  rooms.delete(room.id);
  for (const p of room.players) {
    p.room = null;
    if (p !== leaver && room.state === "playing") send(p.ws, { t: "oppLeft" });
  }
}

function leaveRoom(p) {
  if (p.room) closeRoom(p.room, p);
}

wss.on("connection", (ws) => {
  const p = { id: nextId++, ws, name: "Player", skin: "bf", room: null, last: Date.now() };
  players.set(ws, p);

  ws.on("message", (raw) => {
    p.last = Date.now();
    let m;
    try {
      m = JSON.parse(raw.toString());
    } catch {
      return;
    }
    switch (m.t) {
      case "hello":
        p.name = clean(m.name, 16, p.name);
        p.skin = clean(m.skin, 24, p.skin);
        send(ws, { t: "welcome", id: p.id });
        broadcastLobby();
        break;
      case "skin":
        p.skin = clean(m.skin, 24, p.skin);
        broadcastLobby();
        break;
      case "create": {
        if (p.room || !SONGS.has(m.song)) break;
        const room = { id: nextRoom++, song: m.song, diff: "normal", state: "waiting", players: [p], results: new Map() };
        rooms.set(room.id, room);
        p.room = room;
        broadcastLobby();
        break;
      }
      case "join": {
        const room = rooms.get(m.room);
        if (p.room || !room || room.state !== "waiting") break;
        room.players.push(p);
        p.room = room;
        room.state = "playing";
        for (const x of room.players) {
          const other = room.players.find((y) => y !== x);
          send(x.ws, { t: "start", song: room.song, diff: room.diff, opp: { name: other.name, skin: other.skin } });
        }
        broadcastLobby();
        break;
      }
      case "leave":
        leaveRoom(p);
        broadcastLobby();
        break;
      case "n": {
        // retransmite a jogada para o oponente
        const room = p.room;
        if (!room || room.state !== "playing") break;
        const other = room.players.find((y) => y !== p);
        if (other) send(other.ws, { t: "opp", lane: m.lane | 0, r: m.r | 0, score: m.score | 0 });
        break;
      }
      case "finish": {
        const room = p.room;
        if (!room) break;
        room.results.set(p.id, { score: m.score | 0, acc: Number(m.acc) || 0, misses: m.misses | 0 });
        if (room.results.size === room.players.length) {
          for (const x of room.players) {
            const other = room.players.find((y) => y !== x);
            send(x.ws, { t: "result", you: room.results.get(x.id), opp: room.results.get(other.id) });
          }
          rooms.delete(room.id);
          for (const x of room.players) x.room = null;
          broadcastLobby();
        }
        break;
      }
      case "ping":
        break;
    }
  });

  ws.on("close", () => {
    leaveRoom(p);
    players.delete(ws);
    broadcastLobby();
  });
  ws.on("error", () => ws.terminate());
});

// derruba conexoes mortas (cliente manda ping a cada 15 s)
setInterval(() => {
  const now = Date.now();
  for (const p of players.values()) if (now - p.last > 60000) p.ws.terminate();
}, 15000);

console.log("FNF Online server na porta " + PORT);
