package;

import flixel.util.FlxSave;
import openfl.utils.Assets;

class Settings
{
	public static var skin:String = "bf";
	public static var name:String = "Player";
	public static var server:String = "ws://127.0.0.1:8080";

	static var save:FlxSave;

	public static function load():Void
	{
		// endereco do servidor: edite assets/server.txt (sem precisar digitar no celular)
		if (Assets.exists("assets/server.txt"))
			server = StringTools.trim(Assets.getText("assets/server.txt"));

		save = new FlxSave();
		save.bind("fnfonline");
		if (save.data.skin != null)
			skin = save.data.skin;
		if (save.data.name != null)
			name = save.data.name;
		else
		{
			name = "Player" + (Std.random(900) + 100);
			flush();
		}
	}

	public static function flush():Void
	{
		save.data.skin = skin;
		save.data.name = name;
		save.flush();
	}
}
