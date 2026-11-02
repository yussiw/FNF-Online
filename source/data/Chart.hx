package data;

import haxe.Json;
import openfl.utils.Assets;

typedef NoteData =
{
	var time:Float; // ms
	var lane:Int; // 0 left, 1 down, 2 up, 3 right
	var len:Float; // sustain length in ms
}

typedef CamEvent =
{
	var time:Float;
	var player:Bool; // true = camera on the player (right side)
}

/**
 * Reads two chart formats:
 *  - Codename Engine: strumLines[].notes {id,time,sLen} + events "Camera Movement"
 *  - Legacy (Psych/Kade/base game): song.notes[].sectionNotes [time,lane,sustain] + mustHitSection
 */
class Chart
{
	public var speed:Float = 1;
	public var player:Array<NoteData> = [];
	public var opponent:Array<NoteData> = [];
	public var cam:Array<CamEvent> = [];

	public function new() {}

	public static function load(song:String, diff:String):Chart
	{
		var c = new Chart();
		var raw:Dynamic = Json.parse(Assets.getText('assets/songs/$song/charts/$diff.json'));
		if (raw.strumLines != null)
			loadCodename(raw, c);
		else
			loadLegacy(raw.song, c);
		var cmp = function(a:NoteData, b:NoteData):Int return Std.int(a.time - b.time);
		c.player.sort(cmp);
		c.opponent.sort(cmp);
		c.cam.sort(function(a:CamEvent, b:CamEvent):Int return Std.int(a.time - b.time));
		return c;
	}

	static function loadCodename(raw:Dynamic, c:Chart):Void
	{
		if (raw.scrollSpeed != null)
			c.speed = raw.scrollSpeed;
		var lines:Array<Dynamic> = raw.strumLines;
		for (l in lines)
		{
			var type:Int = l.type;
			var notes:Array<Dynamic> = l.notes;
			for (n in notes)
			{
				var d:NoteData = {time: n.time, lane: n.id, len: n.sLen};
				if (type == 0)
					c.opponent.push(d);
				else if (type == 1)
					c.player.push(d);
			}
		}
		if (raw.events != null)
		{
			var evs:Array<Dynamic> = raw.events;
			for (e in evs)
				if (e.name == "Camera Movement")
				{
					var p:Array<Dynamic> = e.params;
					c.cam.push({time: e.time, player: Std.int(p[0]) == 1});
				}
		}
	}

	static function loadLegacy(song:Dynamic, c:Chart):Void
	{
		if (song.speed != null)
			c.speed = song.speed;
		var bpm:Float = song.bpm;
		var t:Float = 0;
		var sections:Array<Dynamic> = song.notes;
		for (s in sections)
		{
			if (s.changeBPM == true && s.bpm != null)
				bpm = s.bpm;
			var must:Bool = (s.mustHitSection == true);
			c.cam.push({time: t, player: must});
			var arr:Array<Dynamic> = s.sectionNotes;
			for (n in arr)
			{
				var nn:Array<Dynamic> = n;
				var lane:Int = Std.int(nn[1]);
				var isPlayer = must ? (lane < 4) : (lane >= 4);
				var d:NoteData = {time: nn[0], lane: lane % 4, len: (nn[2] == null) ? 0.0 : nn[2]};
				if (isPlayer)
					c.player.push(d);
				else
					c.opponent.push(d);
			}
			var steps:Float = (s.lengthInSteps == null) ? 16 : s.lengthInSteps;
			t += steps * (60000 / bpm / 4);
		}
	}
}
