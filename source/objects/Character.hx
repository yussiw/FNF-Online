package objects;

import flixel.FlxSprite;
import openfl.utils.Assets;

/**
 * Personagem carregado dos xml do Codename Engine (assets/data/characters/<id>.xml).
 * playerSide=true  -> lado direito (olhando para a esquerda)
 * playerSide=false -> lado esquerdo (olhando para a direita)
 * Se o lado pedido for diferente do lado "nativo" do xml, o sprite e espelhado,
 * os anims esquerda/direita sao trocados e o offset X e invertido.
 * Se algum personagem ficar desalinhado, ajuste o xml dele em assets/data/characters.
 */
class Character extends FlxSprite
{
	public var skin:String;

	var offs:Map<String, Array<Float>> = new Map();
	var swapped:Bool = false;
	var sc:Float = 1;

	public function new(skin:String, playerSide:Bool, groundY:Float, cx:Float)
	{
		super();
		this.skin = skin;
		var xml = Xml.parse(Assets.getText('assets/data/characters/$skin.xml')).firstElement();
		var spr = xml.get("sprite");
		frames = Paths.atlas('characters/$spr');
		sc = num(xml.get("scale"), 1);
		antialiasing = xml.get("antialiasing") != "false";

		var nativePlayer = xml.get("isPlayer") == "true";
		var xmlFlip = xml.get("flipX") == "true";
		swapped = (playerSide != nativePlayer);
		flipX = swapped ? !xmlFlip : xmlFlip;

		for (a in xml.elementsNamed("anim"))
		{
			var n = a.get("name");
			var prefix = a.get("anim");
			var fps = Std.int(num(a.get("fps"), 24));
			var loop = a.get("loop") == "true";
			var idx = a.get("indices");
			if (idx != null && idx != "")
				animation.addByIndices(n, prefix, parseIndices(idx), "", fps, loop);
			else
				animation.addByPrefix(n, prefix, fps, loop);
			offs.set(n, [num(a.get("x"), 0), num(a.get("y"), 0)]);
		}

		scale.set(sc, sc);
		origin.set(0, 0);
		animation.play("idle");
		width = frameWidth * sc;
		height = frameHeight * sc;
		x = cx - width / 2;
		y = groundY - height;
		playAnim("idle");
	}

	static function num(s:String, d:Float):Float
	{
		if (s == null)
			return d;
		var v = Std.parseFloat(s);
		return Math.isNaN(v) ? d : v;
	}

	// "2..12,0,1" -> [2,3,...,12,0,1]
	static function parseIndices(s:String):Array<Int>
	{
		var out:Array<Int> = [];
		for (part in s.split(","))
		{
			var r = part.split("..");
			if (r.length == 2)
			{
				var a:Int = Std.parseInt(r[0]);
				var b:Int = Std.parseInt(r[1]);
				for (i in a...(b + 1))
					out.push(i);
			}
			else
				out.push(Std.parseInt(part));
		}
		return out;
	}

	static function swapLR(n:String):String
	{
		if (n.indexOf("LEFT") >= 0)
			return StringTools.replace(n, "LEFT", "RIGHT");
		if (n.indexOf("RIGHT") >= 0)
			return StringTools.replace(n, "RIGHT", "LEFT");
		return n;
	}

	public function playAnim(name:String, force:Bool = true):Void
	{
		var real = swapped ? swapLR(name) : name;
		if (!animation.exists(real))
			return;
		animation.play(real, force);
		var o = offs.get(real);
		if (o != null)
			offset.set(o[0] * sc * (swapped ? -1 : 1), o[1] * sc);
	}

	public var singing(get, never):Bool;

	function get_singing():Bool
		return animation.curAnim != null && StringTools.startsWith(animation.curAnim.name, "sing") && !animation.curAnim.finished;

	public function dance():Void
	{
		if (!singing)
			playAnim("idle");
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (animation.curAnim != null && animation.curAnim.finished && StringTools.startsWith(animation.curAnim.name, "sing"))
			playAnim("idle");
	}
}
