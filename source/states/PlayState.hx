package states;

import Ui.Btn;
import data.Chart;
import data.Songs;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import net.Net;
import objects.Character;
import objects.Note;
import objects.Receptor;

class PlayState extends FlxState
{
	public static var song:String = "bopeebo";
	public static var diff:String = "normal";
	public static var online:Bool = false;
	public static var oppName:String = "CPU";
	public static var oppSkin:String = "dad";

	public static function setup(song:String, online:Bool, oppName:String, oppSkin:String, ?diff:String):Void
	{
		PlayState.song = song;
		PlayState.online = online;
		PlayState.oppName = oppName;
		PlayState.oppSkin = oppSkin;
		PlayState.diff = (diff == null) ? "normal" : diff;
	}

	static inline var NOTE_SCALE:Float = 0.75;
	static inline var LANE_GAP:Float = 125;
	static inline var STRUM_Y:Float = 50;
	static inline var SPEED_MUL:Float = 2.0;
	static inline var MISS_MS:Float = 166;
	static inline var LEAD_MS:Float = 3000;

	static inline var GROUND_Y:Float = 850;
	static inline var OPP_X:Float = 350;
	static inline var ME_X:Float = 1000;
	static inline var CAM_Y:Float = 470;
	static inline var BASE_ZOOM:Float = 0.9;

	static inline var HEALTH_BAR_WIDTH:Float = 600;
	static inline var HEALTH_BAR_HEIGHT:Float = 20;

	var colW:Float;

	var chart:Chart;
	var inst:FlxSound;
	var voices:FlxSound;
	var songPos:Float = -LEAD_MS;
	var started:Bool = false;
	var finished:Bool = false;
	var pps:Float;
	var crochet:Float = 600;
	var lastBeat:Int = -999;

	var camHUD:FlxCamera;
	var camFollow:FlxObject;
	var ci:Int = 0;

	var noteFrames:FlxAtlasFrames;
	var sustainGroup:FlxGroup;
	var noteGroup:FlxGroup;
	var activeNotes:Array<Note> = [];
	var si:Int = 0;
	var oi:Int = 0;

	var strums:Array<Receptor> = [];
	var oppStrums:Array<Receptor> = [];
	var oppTimers:Array<Float> = [0, 0, 0, 0];
	var held:Array<Bool> = [false, false, false, false];
	var glow:Array<FlxSprite> = [];

	var me:Character;
	var opp:Character;

	var score:Int = 0;
	var combo:Int = 0;
	var misses:Int = 0;
	var accPts:Float = 0;
	var judged:Int = 0;
	var oppScore:Int = 0;
	var oppGone:Bool = false;

	var health:Float = 1.0;

	var healthBarBG:FlxSprite;
	var healthBarOpponent:FlxSprite;
	var healthBarPlayer:FlxSprite;

	var playerAvatar:FlxText;
	var opponentAvatar:FlxText;

	var scoreText:FlxText;
	var oppHud:FlxText;

	var judgeText:FlxText;
	var countText:FlxText;
	var banner:FlxText;
	var exitBtn:Btn;
	var lastCount:Int = 99;

	static var DIRS:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT"];
	static var JUDGE:Array<String> = ["SICK!!", "GOOD", "BAD", "SHIT", "MISS"];
	static var JCOLOR:Array<Int> = [
		0xFF66CCFF,
		0xFF66FF66,
		0xFFFFCC33,
		0xFFFF6644,
		0xFFFF3333
	];
	static var JSCORE:Array<Int> = [350, 200, 100, 50];
	static var JACC:Array<Float> = [1, 0.75, 0.5, 0.25];

	function hudAdd(o:FlxBasic):Void
	{
		o.cameras = [camHUD];
		add(o);
	}

	override function create()
	{
		super.create();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		colW = FlxG.width / 4;
		chart = Chart.load(song, diff);

		var info = Songs.info(song);
		crochet = 60000 / info.bpm;
		pps = 0.45 * chart.speed * SPEED_MUL;

		camHUD = new FlxCamera();
		camHUD.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, false);

		var back = new FlxSprite(-600, -200, "assets/images/stages/default/stageback.png");
		back.scrollFactor.set(0.9, 0.9);
		add(back);

		var front = new FlxSprite(-600, 600, "assets/images/stages/default/stagefront.png");
		front.scrollFactor.set(0.9, 0.9);
		add(front);

		opp = new Character(oppSkin, false, GROUND_Y, OPP_X);
		add(opp);

		me = new Character(Settings.skin, true, GROUND_Y, ME_X);
		add(me);

		var curtains = new FlxSprite(-500, -300, "assets/images/stages/default/stagecurtains.png");
		curtains.scrollFactor.set(1.3, 1.3);
		add(curtains);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		setCamTarget(false);

		FlxG.camera.zoom = BASE_ZOOM;
		FlxG.camera.follow(camFollow, FlxCameraFollowStyle.LOCKON, 0.06);
		FlxG.camera.focusOn(camFollow.getPosition());

		noteFrames = Paths.atlas("game/notes/default");

		for (i in 0...4)
		{
			var g = new FlxSprite(i * colW, 0)
				.makeGraphic(Std.int(colW), FlxG.height, 0xFFFFFFFF);

			g.alpha = 0;
			glow.push(g);
			hudAdd(g);
		}

		for (i in 0...4)
		{
			var r = new Receptor(laneX(i), STRUM_Y, i, NOTE_SCALE, noteFrames);
			strums.push(r);
			hudAdd(r);

			var o = new Receptor(20 + i * 46, 14, i, 0.3, noteFrames);
			oppStrums.push(o);
			hudAdd(o);
		}

		sustainGroup = new FlxGroup();
		noteGroup = new FlxGroup();

		hudAdd(sustainGroup);
		hudAdd(noteGroup);

		createHealthHUD();

		oppHud = Ui.text(20, 62, 400, "", 26);
		hudAdd(oppHud);

		judgeText = Ui.text(0, 330, FlxG.width, "", 90, FlxTextAlign.CENTER);
		judgeText.alpha = 0;
		hudAdd(judgeText);

		countText = Ui.text(0, 240, FlxG.width, "", 160, FlxTextAlign.CENTER);
		hudAdd(countText);

		banner = Ui.text(0, 190, FlxG.width, "", 38, FlxTextAlign.CENTER, 0xFFFFE066);
		hudAdd(banner);

		exitBtn = new Btn(FlxG.width - 96, 6, 90, 38, "EXIT", 24, 0xFF8E2A2A);
		exitBtn.bg.cameras = [camHUD];
		exitBtn.label.cameras = [camHUD];
		exitBtn.cameras = [camHUD];
		add(exitBtn);

		inst = FlxG.sound.load(Paths.songFile(song, "Inst"));
		inst.onComplete = finish;

		if (Paths.exists(Paths.songFile(song, "Voices")))
			voices = FlxG.sound.load(Paths.songFile(song, "Voices"));

		if (online)
		{
			Net.onOpp = onOppMsg;

			Net.onOppLeft = function()
			{
				oppGone = true;
				banner.text = "Opponent left";
			};

			Net.onResult = onResult;
		}

		updateHud();
	}

	function createHealthHUD():Void
	{
		var barX = (FlxG.width - HEALTH_BAR_WIDTH) / 2;
		var barY = FlxG.height - 78;

		healthBarBG = new FlxSprite(barX - 4, barY - 4)
			.makeGraphic(
				Std.int(HEALTH_BAR_WIDTH + 8),
				Std.int(HEALTH_BAR_HEIGHT + 8),
				FlxColor.BLACK
			);

		healthBarOpponent = new FlxSprite(barX, barY)
			.makeGraphic(
				Std.int(HEALTH_BAR_WIDTH),
				Std.int(HEALTH_BAR_HEIGHT),
				0xFFCC3333
			);

		healthBarPlayer = new FlxSprite(barX + HEALTH_BAR_WIDTH / 2, barY)
			.makeGraphic(
				Std.int(HEALTH_BAR_WIDTH / 2),
				Std.int(HEALTH_BAR_HEIGHT),
				0xFF66FF33
			);

		playerAvatar = Ui.text(
			barX + HEALTH_BAR_WIDTH + 8,
			barY - 22,
			52,
			"BF",
			34,
			FlxTextAlign.CENTER,
			FlxColor.WHITE
		);

		opponentAvatar = Ui.text(
			barX - 60,
			barY - 22,
			52,
			"DAD",
			30,
			FlxTextAlign.CENTER,
			FlxColor.WHITE
		);

		scoreText = Ui.text(
			0,
			FlxG.height - 42,
			FlxG.width,
			"",
			25,
			FlxTextAlign.CENTER
		);

		hudAdd(healthBarBG);
		hudAdd(healthBarOpponent);
		hudAdd(healthBarPlayer);
		hudAdd(opponentAvatar);
		hudAdd(playerAvatar);
		hudAdd(scoreText);
	}

	function updateHealthHUD():Void
	{
		health = Math.max(0, Math.min(2, health));

		var width = HEALTH_BAR_WIDTH * (health / 2);

		healthBarPlayer.setGraphicSize(
			Std.int(width),
			Std.int(HEALTH_BAR_HEIGHT)
		);

		healthBarPlayer.updateHitbox();

		healthBarPlayer.x =
			healthBarBG.x + 4 + HEALTH_BAR_WIDTH - width;

		var acc = judged > 0
			? Math.round(accPts / judged * 1000) / 10
			: 100;

		scoreText.text =
			"Score: " + score +
			"    Misses: " + misses +
			"    Accuracy: " + acc + "%";

		opponentAvatar.text = online ? "OPP" : "DAD";
	}

	inline function laneX(lane:Int):Float
		return (FlxG.width - (3 * LANE_GAP + 157 * NOTE_SCALE)) / 2 + lane * LANE_GAP;

	function setCamTarget(player:Bool):Void
	{
		if (player)
			camFollow.setPosition(ME_X - 120, CAM_Y);
		else
			camFollow.setPosition(OPP_X + 120, CAM_Y);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Ui.backPressed() || exitBtn.tapped(camHUD))
		{
			leave();
			return;
		}

		if (finished || Transition.active)
			return;

		songPos += elapsed * 1000;

		if (!started)
		{
			updateCountdown();

			if (songPos >= 0)
				startSong();
		}
		else if (inst.playing && Math.abs(inst.time - songPos) > 50)
			songPos = inst.time;

		while (ci < chart.cam.length && chart.cam[ci].time <= songPos)
			setCamTarget(chart.cam[ci++].player);

		var k = Math.exp(-elapsed * 5);
		FlxG.camera.zoom = FlxMath.lerp(BASE_ZOOM, FlxG.camera.zoom, k);
		camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, k);

		spawnNotes();
		pollInput();
		updateNotes(elapsed);
		updateOpponent();
		updateBeat();
		updateHud();

		if (judgeText.alpha > 0)
			judgeText.alpha -= elapsed * 2.2;
	}

	function startSong():Void
	{
		started = true;
		countText.text = "";

		inst.play();

		if (voices != null)
			voices.play();

		songPos = 0;
	}

	function updateCountdown():Void
	{
		var n = Math.ceil(-songPos / 1000);

		if (n == lastCount)
			return;

		lastCount = n;

		if (n >= 1 && n <= 3)
		{
			countText.text = Std.string(n);
			FlxG.sound.play(Paths.sound("intro" + n));
		}
		else
		{
			countText.text = "GO!";
			FlxG.sound.play(Paths.sound("introGo"));
		}
	}

	function updateBeat():Void
	{
		var b = Math.floor(songPos / crochet);

		if (b != lastBeat)
		{
			lastBeat = b;

			if (b % 2 == 0)
			{
				me.dance();
				opp.dance();
			}

			if (b > 0 && b % 4 == 0)
			{
				FlxG.camera.zoom += 0.02;
				camHUD.zoom += 0.04;
			}
		}
	}

	function updateHud():Void
	{
		oppHud.text = online ? oppName + ": " + oppScore : "";
		updateHealthHUD();
	}

	function spawnNotes():Void
	{
		var ahead = (FlxG.height - STRUM_Y + 100) / pps;

		while (si < chart.player.length && chart.player[si].time - songPos < ahead)
		{
			var d = chart.player[si++];
			var n = new Note(d, noteFrames, laneX(d.lane), NOTE_SCALE);

			n.cameras = [camHUD];

			if (n.tail != null)
			{
				n.tail.cameras = [camHUD];
				n.cap.cameras = [camHUD];

				sustainGroup.add(n.tail);
				sustainGroup.add(n.cap);
			}

			noteGroup.add(n);
			activeNotes.push(n);
		}
	}

	function removeNote(n:Note):Void
	{
		activeNotes.remove(n);
		noteGroup.remove(n, true);

		if (n.tail != null)
		{
			sustainGroup.remove(n.tail, true);
			sustainGroup.remove(n.cap, true);
			n.tail.destroy();
			n.cap.destroy();
		}

		n.destroy();
	}

	function updateNotes(elapsed:Float):Void
	{
		var i = activeNotes.length;

		while (i-- > 0)
		{
			var n = activeNotes[i];
			var dt = n.time - songPos;
			var half = n.height / 2;

			if (n.holding)
			{
				var end = n.time + n.len;

				if (!held[n.lane] && songPos < end - 120)
				{
					removeNote(n);
					continue;
				}

				if (songPos >= end)
				{
					strums[n.lane].play(held[n.lane] ? "confirm" : "static");
					removeNote(n);
					continue;
				}

				score += Std.int(elapsed * 1000 * 0.25);
				n.layoutTail(STRUM_Y + half, (end - songPos) * pps);

				var ca = strums[n.lane].animation.curAnim;

				if (ca != null && ca.finished)
					strums[n.lane].play("confirm");

				continue;
			}

			n.y = STRUM_Y + dt * pps;
			n.layoutTail(n.y + half, n.len * pps);

			if (!n.missed && -dt > MISS_MS)
				miss(n);

			if (n.y + n.height + n.len * pps + 80 < 0)
				removeNote(n);
		}
	}

	function pollInput():Void
	{
		var now = [false, false, false, false];

		if (FlxG.keys.anyPressed([FlxKey.LEFT, FlxKey.D, FlxKey.A]))
			now[0] = true;

		if (FlxG.keys.anyPressed([FlxKey.DOWN, FlxKey.F, FlxKey.S]))
			now[1] = true;

		if (FlxG.keys.anyPressed([FlxKey.UP, FlxKey.J, FlxKey.W]))
			now[2] = true;

		if (FlxG.keys.anyPressed([FlxKey.RIGHT, FlxKey.K, FlxKey.L]))
			now[3] = true;

		for (t in FlxG.touches.list)
			if (t.pressed)
			{
				if (t.screenX > FlxG.width - 110 && t.screenY < 52)
					continue;

				var l = Std.int(t.screenX / colW);
				now[Std.int(Math.max(0, Math.min(3, l)))] = true;
			}

		for (l in 0...4)
		{
			glow[l].alpha = now[l] ? 0.16 : 0;

			if (now[l] && !held[l])
				press(l);
			else if (!now[l] && held[l])
				strums[l].play("static");

			held[l] = now[l];
		}
	}

	function press(lane:Int):Void
	{
		if (!started || finished)
			return;

		var best:Note = null;

		for (n in activeNotes)
			if (n.lane == lane && !n.hit && !n.missed && Math.abs(n.time - songPos) <= 135)
				if (best == null || Math.abs(n.time - songPos) < Math.abs(best.time - songPos))
					best = n;

		if (best != null)
			hitNote(best);
		else
			strums[lane].play("press");
	}

	function hitNote(n:Note):Void
	{
		var d = Math.abs(n.time - songPos);
		var r = d < 45 ? 0 : (d < 90 ? 1 : (d < 125 ? 2 : 3));

		n.hit = true;
		score += JSCORE[r];
		accPts += JACC[r];
		judged++;
		combo++;

		health = Math.min(2, health + 0.023);

		strums[n.lane].play("confirm");
		me.playAnim("sing" + DIRS[n.lane]);

		if (voices != null)
			voices.volume = 1;

		showJudge(r);
		sendNote(n.lane, r);

		if (n.len > 80)
		{
			n.holding = true;
			n.visible = false;
			n.y = STRUM_Y;
		}
		else
			removeNote(n);
	}

	function miss(n:Note):Void
	{
		n.missed = true;
		n.dim();
		combo = 0;
		misses++;
		judged++;
		score -= 10;

		health = Math.max(0, health - 0.047);

		me.playAnim("sing" + DIRS[n.lane] + "miss");

		if (voices != null)
			voices.volume = 0;

		FlxG.sound.play(Paths.sound("missnote" + FlxG.random.int(1, 3)), 0.4);
		showJudge(4);
		sendNote(n.lane, 4);
	}

	function showJudge(r:Int):Void
	{
		judgeText.text = JUDGE[r];
		judgeText.color = JCOLOR[r];
		judgeText.alpha = 1;
	}

	function sendNote(lane:Int, r:Int):Void
	{
		if (online)
			Net.send({t: "n", lane: lane, r: r, score: score});
	}

	function oppSing(lane:Int, miss:Bool):Void
	{
		opp.playAnim("sing" + DIRS[lane] + (miss ? "miss" : ""));

		if (!miss)
		{
			oppStrums[lane].play("confirm");
			oppTimers[lane] = 0.15;
		}
	}

	function onOppMsg(m:Dynamic):Void
	{
		var r:Int = m.r;
		oppScore = m.score;
		oppSing(m.lane, r == 4);
	}

	function updateOpponent():Void
	{
		if (!online && started)
			while (oi < chart.opponent.length && chart.opponent[oi].time <= songPos)
				oppSing(chart.opponent[oi++].lane, false);

		for (l in 0...4)
			if (oppTimers[l] > 0)
			{
				oppTimers[l] -= FlxG.elapsed;

				if (oppTimers[l] <= 0)
					oppStrums[l].play("static");
			}
	}

	function finish():Void
	{
		if (finished)
			return;

		finished = true;
		inst.stop();

		if (voices != null)
			voices.stop();

		var acc = judged > 0 ? accPts / judged * 100 : 100;

		ResultsState.mine = {score: score, acc: acc, misses: misses};
		ResultsState.oppName = oppName;
		ResultsState.opp = null;

		if (online && !oppGone)
		{
			Net.send({t: "finish", score: score, acc: acc, misses: misses});
			banner.text = "Waiting for the opponent to finish...";
		}
		else
			Transition.to(function():FlxState return new ResultsState());
	}

	function onResult(m:Dynamic):Void
	{
		ResultsState.mine = {score: m.you.score, acc: m.you.acc, misses: m.you.misses};
		ResultsState.opp = {score: m.opp.score, acc: m.opp.acc, misses: m.opp.misses};

		Transition.to(function():FlxState return new ResultsState());
	}

	function leave():Void
	{
		if (Transition.active)
			return;

		if (online)
			Net.send({t: "leave"});

		inst.stop();

		if (voices != null)
			voices.stop();

		Transition.to(function():FlxState return new FreeplayState());
	}

	override function destroy()
	{
		Net.clearHandlers();
		super.destroy();
	}
}