package;

import flixel.FlxG;
import flixel.FlxGame;
import net.Net;
import openfl.display.Sprite;
import states.MainMenuState;

class Main extends Sprite
{
	public function new()
	{
		super();
		Settings.load();
		addChild(new FlxGame(1280, 720, MainMenuState, 60, 60, true));
		// a conexao precisa ser "processada" todo frame (haxe-ws)
		FlxG.signals.preUpdate.add(Net.update);
	}
}
