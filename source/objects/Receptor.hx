package objects;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class Receptor extends FlxSprite
{
	public var lane:Int;

	public function new(x:Float, y:Float, lane:Int, sc:Float, f:FlxAtlasFrames)
	{
		super(x, y);
		this.lane = lane;
		frames = f;
		var dir = ["LEFT", "DOWN", "UP", "RIGHT"][lane];
		var low = dir.toLowerCase();
		animation.addByPrefix("static", 'arrow$dir', 24, false);
		animation.addByPrefix("press", '$low press', 24, false);
		animation.addByPrefix("confirm", '$low confirm', 24, false);
		scale.set(sc, sc);
		animation.play("static");
		updateHitbox();
		antialiasing = true;
	}

	public function play(a:String):Void
	{
		animation.play(a, true);
		if (a == "static")
			updateHitbox();
		else
		{
			centerOffsets();
			centerOrigin();
		}
	}
}
