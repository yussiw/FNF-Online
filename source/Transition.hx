package;

import flixel.FlxG;
import flixel.FlxState;
import openfl.display.GradientType;
import openfl.display.Sprite;
import openfl.geom.Matrix;

/**
 * FNF-style transition: a black block with a soft gradient edge slides down
 * to cover the screen, the state is switched, then it slides away.
 */
class Transition
{
	static inline var DUR:Float = 0.4;
	static inline var G:Float = 340; // gradient height

	static var spr:Sprite;
	static var phase:Int = 0; // 0 idle, 1 cover, 2 reveal
	static var t:Float = 0;
	static var next:Void->FlxState;

	public static var active(get, never):Bool;

	static function get_active():Bool
		return phase != 0;

	public static function init():Void
	{
		if (spr != null)
			return;
		var w = FlxG.width;
		var h = FlxG.height;
		spr = new Sprite();
		spr.mouseEnabled = false;
		spr.mouseChildren = false;
		var g = spr.graphics;
		g.beginFill(0x000000, 1);
		g.drawRect(0, 0, w, h);
		g.endFill();
		var m = new Matrix();
		m.createGradientBox(w, G, Math.PI / 2, 0, h);
		g.beginGradientFill(GradientType.LINEAR, [0x000000, 0x000000], [1, 0], [0, 255], m);
		g.drawRect(0, h, w, G);
		g.endFill();
		spr.visible = false;
		FlxG.game.addChild(spr);
		FlxG.signals.postUpdate.add(update);
	}

	public static function to(factory:Void->FlxState):Void
	{
		if (phase != 0)
			return;
		init();
		next = factory;
		phase = 1;
		t = 0;
		spr.scaleY = 1;
		spr.y = -(FlxG.height + G);
		spr.visible = true;
		FlxG.game.addChild(spr); // keep it on top
	}

	static inline function ease(k:Float):Float
		return k * k * (3 - 2 * k);

	static function update():Void
	{
		if (phase == 0)
			return;
		var h:Float = FlxG.height;
		t += FlxG.elapsed / DUR;
		if (phase == 1)
		{
			var k = Math.min(t, 1);
			spr.y = -(h + G) * (1 - ease(k));
			if (t >= 1)
			{
				FlxG.switchState(next());
				phase = 2;
				t = -0.12; // small wait so the new state can build itself
				spr.scaleY = -1;
				spr.y = h;
			}
		}
		else
		{
			var k = Math.max(0, Math.min(t, 1));
			spr.y = h + (h + G) * ease(k);
			if (t >= 1)
			{
				phase = 0;
				spr.visible = false;
			}
		}
	}
}
