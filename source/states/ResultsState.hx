package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;

typedef Result =
{
	var score:Int;
	var acc:Float;
	var misses:Int;
}

class ResultsState extends FlxState
{
	public static var mine:Result = {score: 0, acc: 0, misses: 0};
	public static var opp:Result = null;
	public static var oppName:String = "CPU";

	override function create()
	{
		super.create();
		Ui.menuMusic();
		var bg = new FlxSprite(0, 0, Paths.img("menus/menuBGBlue"));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		add(bg);

		var title = "SONG COMPLETE";
		if (opp != null)
			title = mine.score > opp.score ? "YOU WIN!" : (mine.score < opp.score ? "YOU LOSE" : "DRAW");
		add(Ui.text(0, 60, FlxG.width, title, 80, FlxTextAlign.CENTER, 0xFFFFE066));

		add(Ui.text(140, 220, 500, "YOU\n" + line(mine), 40));
		if (opp != null)
			add(Ui.text(700, 220, 500, oppName + "\n" + line(opp), 40));
		else
			add(Ui.text(700, 220, 500, "(no opponent)", 34));

		add(Ui.text(0, FlxG.height - 60, FlxG.width, "Tap to continue", 34, FlxTextAlign.CENTER));
	}

	static function line(r:Result):String
		return "Score: " + r.score + "\nAccuracy: " + (Math.round(r.acc * 10) / 10) + "%\nMisses: " + r.misses;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (Transition.active)
			return;
		if (FlxG.mouse.justPressed || FlxG.keys.justPressed.ENTER || Ui.backPressed())
			Transition.to(function():FlxState return new FreeplayState());
	}
}
