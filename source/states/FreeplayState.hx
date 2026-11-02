package states;

import Ui.Btn;
import data.Songs;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import net.Net;

typedef Hit =
{
	var bg:FlxSprite;
	var act:Void->Void;
}

/** Freeplay: songs (practice offline or create a room) + open matches and online players. */
class FreeplayState extends FlxState
{
	var status:FlxText;
	var dyn:FlxGroup;
	var back:Btn;
	var staticHits:Array<Hit> = [];
	var dynHits:Array<Hit> = [];

	override function create()
	{
		super.create();
		Ui.menuMusic();
		Net.connect();

		var bg = new FlxSprite(0, 0, Paths.img("menus/menuBGBlue"));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		add(bg);

		back = new Btn(16, 16, 130, 44, "BACK", 28);
		add(back);
		add(Ui.text(166, 18, 500, "FREEPLAY", 56));
		status = Ui.text(600, 24, 664, "", 28, FlxTextAlign.RIGHT);
		add(status);

		add(Ui.text(40, 100, 560, "SONGS", 38, FlxTextAlign.LEFT, 0xFFFFE066));
		var songs = Songs.all();
		for (i in 0...songs.length)
		{
			var s = songs[i];
			var y = 150 + i * 96;
			add(new FlxSprite(40, y).makeGraphic(570, 80, 0xAA10182E));
			add(Ui.text(56, y + 26, 250, s.name, 34));
			var practice = new Btn(300, y + 14, 150, 52, "PRACTICE", 26);
			var room = new Btn(465, y + 14, 130, 52, "ROOM", 26, 0xFF2E7D32);
			add(practice);
			add(room);
			staticHits.push({bg: practice.bg, act: function() startPractice(s.id)});
			staticHits.push({bg: room.bg, act: function() createRoom(s.id)});
		}

		dyn = new FlxGroup();
		add(dyn);

		Net.onLobby = refresh;
		Net.onStart = function(m:Dynamic)
		{
			PlayState.setup(m.song, true, m.opp.name, m.opp.skin, m.diff);
			Transition.to(function():FlxState return new PlayState());
		};
		refresh();
	}

	function startPractice(song:String):Void
	{
		PlayState.setup(song, false, "CPU", "dad", "normal");
		Transition.to(function():FlxState return new PlayState());
	}

	function createRoom(song:String):Void
	{
		if (!Net.connected)
		{
			status.text = "No connection";
			return;
		}
		Net.send({t: "create", song: song});
	}

	function refresh():Void
	{
		status.text = "Server: " + Net.status;
		dyn.forEach(function(o) o.destroy());
		dyn.clear();
		dynHits = [];

		dyn.add(Ui.text(650, 100, 560, "MATCHES", 38, FlxTextAlign.LEFT, 0xFFFFE066));
		if (!Net.connected)
		{
			dyn.add(Ui.text(650, 150, 600, "You are offline.", 30));
			var b = new Btn(650, 190, 260, 52, "RECONNECT", 26);
			dyn.add(b);
			dynHits.push({bg: b.bg, act: function() Net.reconnect()});
			return;
		}

		var shown = 0;
		for (r in Net.rooms)
		{
			if (shown >= 4)
				break;
			var y = 150 + shown * 62;
			var mine = (Net.myRoom != null && r.id == Net.myRoom);
			var row = new Btn(650, y, 600, 52, (mine ? "(yours) " : "") + r.host + " - " + r.song, 26, mine ? 0xFF555555 : 0xFF223355);
			dyn.add(row);
			var id:Int = r.id;
			dynHits.push({bg: row.bg, act: function()
			{
				if (!mine)
					Net.send({t: "join", room: id});
			}});
			shown++;
		}
		if (shown == 0)
			dyn.add(Ui.text(650, 150, 600, "No open rooms. Press ROOM on a song!", 28));

		dyn.add(Ui.text(650, 420, 560, "ONLINE (" + Net.players.length + ")", 34, FlxTextAlign.LEFT, 0xFFFFE066));
		var names:Array<String> = [];
		for (p in Net.players)
			names.push(p.name + (p.busy ? " (playing)" : ""));
		dyn.add(Ui.text(650, 462, 600, names.slice(0, 7).join("\n"), 28));

		if (Net.myRoom != null)
		{
			dyn.add(Ui.text(40, 660, 700, "Waiting for an opponent...", 34, FlxTextAlign.LEFT, 0xFFFFE066));
			var c = new Btn(FlxG.width - 200, 650, 170, 52, "CANCEL", 26, 0xFF8E2A2A);
			dyn.add(c);
			dynHits.push({bg: c.bg, act: function() Net.send({t: "leave"})});
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (Transition.active)
			return;
		if (Ui.backPressed() || back.tapped())
		{
			if (Net.myRoom != null)
				Net.send({t: "leave"});
			Transition.to(function():FlxState return new MainMenuState());
			return;
		}
		if (FlxG.mouse.justPressed)
		{
			for (h in staticHits.concat(dynHits))
				if (FlxG.mouse.overlaps(h.bg))
				{
					FlxG.sound.play("assets/sounds/menu/confirm.ogg", 0.6);
					h.act();
					break;
				}
		}
	}

	override function destroy()
	{
		Net.onLobby = null;
		Net.onStart = null;
		super.destroy();
	}
}
