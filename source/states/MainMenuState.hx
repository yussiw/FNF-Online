package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import net.Net;

class MainMenuState extends FlxState
{
	static inline var FIRST_Y:Float = 250;
	static inline var SPACING:Float = 210;

	var items:Array<FlxSprite> = [];
	var sel:Int = 0;
	var locked:Bool = false;
	var bg:FlxSprite;
	var extra:Float = 0;
	var info:FlxText;

	override function create()
	{
		super.create();
		Transition.init();
		Ui.menuMusic();
		Net.connect();

		// background is bigger than the screen and slides with the selection
		bg = new FlxSprite(0, 0, Paths.img("menus/menuBG"));
		bg.setGraphicSize(Std.int(FlxG.width * 1.25));
		bg.updateHitbox();
		bg.x = (FlxG.width - bg.width) / 2;
		extra = bg.height - FlxG.height;
		add(bg);

		var fp = new FlxSprite();
		fp.frames = Paths.atlas("menus/mainmenu/freeplay");
		fp.animation.addByPrefix("idle", "freeplay basic", 24, true);
		fp.animation.addByPrefix("sel", "freeplay white", 24, true);

		var sk = new FlxSprite();
		sk.frames = Paths.atlas("menus/mainmenu/skins");
		sk.animation.addByNames("idle", ["skins0", "skins1", "skins2"], 24, true);
		sk.animation.addByNames("sel", ["skins selected0", "skins selected1", "skins selected2"], 24, true);

		items = [fp, sk];
		for (i in 0...items.length)
		{
			var it = items[i];
			it.antialiasing = true;
			it.animation.play("idle");
			it.updateHitbox();
			it.x = (FlxG.width - it.width) / 2;
			it.y = FIRST_Y + i * SPACING - it.height / 2;
			add(it);
		}

		info = Ui.text(14, FlxG.height - 30, FlxG.width - 28, "", 28);
		add(info);
		highlight(false);
		bg.y = 0;
	}

	function highlight(sound:Bool = true):Void
	{
		if (sound)
			FlxG.sound.play("assets/sounds/menu/scroll.ogg");
		for (i in 0...items.length)
		{
			var it = items[i];
			it.animation.play(i == sel ? "sel" : "idle", true);
			it.centerOffsets();
		}
	}

	/** which option is under this Y (the whole band is a hit area, so swiping works anywhere) */
	function itemAt(y:Float):Int
	{
		for (i in 0...items.length)
			if (Math.abs(y - (FIRST_Y + i * SPACING)) < SPACING / 2)
				return i;
		return -1;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		info.text = "Player: " + Settings.name + "   Skin: " + Settings.skin + "   Server: " + Net.status;

		var target = -extra * (items.length > 1 ? sel / (items.length - 1) : 0);
		bg.y += (target - bg.y) * Math.min(1, elapsed * 7);

		if (locked || Transition.active)
			return;

		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W)
			move(-1);
		if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S)
			move(1);
		if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
			accept();

		// finger down / sliding: selects what is under it; lifting the finger confirms
		if (FlxG.mouse.pressed)
		{
			var i = itemAt(FlxG.mouse.y);
			if (i >= 0 && i != sel)
			{
				sel = i;
				highlight();
			}
		}
		if (FlxG.mouse.justReleased && itemAt(FlxG.mouse.y) == sel)
			accept();
	}

	function move(d:Int):Void
	{
		sel = (sel + d + items.length) % items.length;
		highlight();
	}

	function accept():Void
	{
		locked = true;
		FlxG.sound.play("assets/sounds/menu/confirm.ogg");
		for (i in 0...items.length)
			if (i != sel)
				FlxTween.tween(items[i], {alpha: 0}, 0.4);
		FlxFlicker.flicker(items[sel], 0.8, 0.06, false, false, function(_)
		{
			Transition.to(function():FlxState
			{
				if (sel == 0)
					return new FreeplayState();
				return new SkinState();
			});
		});
	}
}
