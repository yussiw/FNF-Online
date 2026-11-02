package objects;

import data.Chart.NoteData;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class Note extends FlxSprite
{
	static var COLORS:Array<String> = ["purple", "blue", "green", "red"];

	public var time:Float;
	public var lane:Int;
	public var len:Float;
	public var hit:Bool = false;
	public var missed:Bool = false;
	public var holding:Bool = false;
	public var tail:FlxSprite; // pedaco do sustain (esticado)
	public var cap:FlxSprite; // ponta do sustain
	public var sc:Float;

	public function new(d:NoteData, f:FlxAtlasFrames, x:Float, sc:Float)
	{
		super(x, -1000);
		time = d.time;
		lane = d.lane;
		len = d.len;
		this.sc = sc;
		var c = COLORS[lane];
		frames = f;
		animation.addByNames("n", [c + "0000"], 24, true);
		animation.play("n");
		scale.set(sc, sc);
		updateHitbox();
		antialiasing = true;

		if (len > 80)
		{
			tail = new FlxSprite();
			tail.frames = f;
			tail.animation.addByNames("t", [c + " hold piece0000"], 24, true);
			tail.animation.play("t");
			tail.origin.set(0, 0);
			tail.antialiasing = true;

			cap = new FlxSprite();
			cap.frames = f;
			var capName = (c == "purple") ? "pruple end hold0000" : (c + " hold end0000"); // "pruple" = typo do atlas original
			cap.animation.addByNames("c", [capName], 24, true);
			cap.animation.play("c");
			cap.origin.set(0, 0);
			cap.scale.set(sc, sc);
			cap.antialiasing = true;
		}
	}

	/** posiciona o sustain a partir do topo (yTop) com comprimento em pixels */
	public function layoutTail(yTop:Float, px:Float):Void
	{
		if (tail == null)
			return;
		if (px < 1)
		{
			tail.visible = false;
			cap.visible = false;
			return;
		}
		tail.visible = cap.visible = true;
		tail.scale.set(sc, px / tail.frameHeight);
		tail.x = x + width / 2 - tail.frameWidth * sc / 2;
		tail.y = yTop;
		cap.x = x + width / 2 - cap.frameWidth * sc / 2;
		cap.y = yTop + px;
	}

	public function dim():Void
	{
		alpha = 0.35;
		if (tail != null)
			tail.alpha = cap.alpha = 0.3;
	}
}
