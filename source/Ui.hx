package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class Ui
{
	public static inline var FONT:String = "assets/fonts/vcr.ttf";
	/** the vcr font is wide: every size is multiplied by this */
	public static inline var SCALE:Float = 0.6;

	public static function text(x:Float, y:Float, w:Float, s:String, size:Int = 32, align:FlxTextAlign = FlxTextAlign.LEFT, color:Int = 0xFFFFFFFF):FlxText
	{
		var px = Std.int(Math.max(10, Math.round(size * SCALE)));
		var t = new FlxText(x, y, w, s, px);
		t.setFormat(FONT, px, color, align);
		t.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
		return t;
	}

	public static function backPressed():Bool
	{
		#if android
		if (FlxG.android.justReleased.BACK)
			return true;
		#end
		return FlxG.keys.justPressed.ESCAPE;
	}

	public static function menuMusic():Void
	{
		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			FlxG.sound.playMusic("assets/music/freakyMenu.ogg", 0.7);
	}
}

class Btn extends FlxSpriteGroup
{
	public var bg:FlxSprite;
	public var label:FlxText;

	public function new(x:Float, y:Float, w:Int, h:Int, s:String, size:Int = 28, col:Int = 0xFF1B2A4A)
	{
		super(x, y);
		bg = new FlxSprite().makeGraphic(w, h, col);
		add(bg);
		label = Ui.text(0, (h - size * Ui.SCALE) / 2 - 3, w, s, size, FlxTextAlign.CENTER);
		add(label);
	}

	public function tapped(?cam:FlxCamera):Bool
		return visible && FlxG.mouse.justPressed && FlxG.mouse.overlaps(bg, cam);
}
