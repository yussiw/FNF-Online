package data;

import haxe.Json;
import openfl.utils.Assets;

typedef SongInfo =
{
	var id:String;
	var name:String;
	var bpm:Float;
}

class Songs
{
	public static var ids:Array<String> = ["bopeebo", "fresh", "dadbattle"];

	public static function info(id:String):SongInfo
	{
		var m:Dynamic = Json.parse(Assets.getText('assets/songs/$id/meta.json'));
		return {id: id, name: m.displayName, bpm: m.bpm};
	}

	public static function all():Array<SongInfo>
		return [for (i in ids) info(i)];
}
