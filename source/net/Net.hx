
package net;

import haxe.Json;
import haxe.Timer;
import haxe.net.WebSocket;

class Net
{
	public static var ws:WebSocket;
	public static var connected:Bool = false;
	public static var status:String = "offline";
	public static var players:Array<Dynamic> = [];
	public static var rooms:Array<Dynamic> = [];
	public static var myRoom:Null<Int> = null;

	public static var onLobby:Void->Void;
	public static var onStart:Dynamic->Void;
	public static var onOpp:Dynamic->Void;
	public static var onOppLeft:Void->Void;
	public static var onResult:Dynamic->Void;

	static var lastPing:Float = 0;

	public static function connect():Void
	{
		if (ws != null)
			return;

		status = "conectando...";

		try
		{
			ws = WebSocket.create(Settings.server, null, null, false);

			ws.onopen = function()
			{
				connected = true;
				status = "online";
				send({t: "hello", name: Settings.name, skin: Settings.skin});
			};

			ws.onmessageString = onMsg;

			ws.onerror = function(e:String)
			{
				status = "erro de conexao";
				connected = false;
			};

			ws.onclose = function()
			{
				connected = false;
				status = "offline";
				ws = null;
				players = [];
				rooms = [];
				myRoom = null;

				if (onLobby != null)
					onLobby();
			};
		}
		catch (e:Dynamic)
		{
			status = "erro: servidor invalido";
			ws = null;
		}
	}

	public static function reconnect():Void
	{
		if (ws != null)
		{
			try
			{
				ws.close();
			}
			catch (e:Dynamic) {}

			ws = null;
		}

		connected = false;
		connect();
	}

	public static function update():Void
	{
		if (ws == null)
			return;

		ws.process();

		if (connected && Timer.stamp() - lastPing > 15)
		{
			lastPing = Timer.stamp();
			send({t: "ping"});
		}
	}

	public static function send(o:Dynamic):Void
	{
		if (ws != null && connected)
			ws.sendString(Json.stringify(o));
	}

	static function onMsg(s:String):Void
	{
		var m:Dynamic = Json.parse(s);
		var t:String = m.t;

		switch (t)
		{
			case "lobby":
				players = m.players;
				rooms = m.rooms;
				myRoom = m.mine;

				if (onLobby != null)
					onLobby();

			case "start":
				myRoom = null;

				if (onStart != null)
					onStart(m);

			case "opp":
				if (onOpp != null)
					onOpp(m);

			case "oppLeft":
				if (onOppLeft != null)
					onOppLeft();

			case "result":
				if (onResult != null)
					onResult(m);

			default:
		}
	}

	public static function clearHandlers():Void
	{
		onLobby = null;
		onStart = null;
		onOpp = null;
		onOppLeft = null;
		onResult = null;
	}
}
