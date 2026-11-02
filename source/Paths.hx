package;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets;

class Paths
{
	public static inline function img(k:String):String
		return 'assets/images/$k.png';

	public static function atlas(k:String):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow('assets/images/$k.png', 'assets/images/$k.xml');

	public static inline function sound(k:String):String
		return 'assets/sounds/$k.ogg';

	public static inline function songFile(song:String, f:String):String
		return 'assets/songs/$song/song/$f.ogg';

	public static inline function text(p:String):String
		return Assets.getText(p);

	public static inline function exists(p:String):Bool
		return Assets.exists(p);
}
