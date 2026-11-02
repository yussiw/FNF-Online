package data;

typedef SkinInfo =
{
	var id:String; // nome do xml em assets/data/characters
	var name:String;
}

class Skins
{
	// Para adicionar skin: copie png+xml do personagem para assets/images/characters,
	// o xml para assets/data/characters e adicione aqui.
	public static var all:Array<SkinInfo> = [
		{id: "bf", name: "Boyfriend"},
		{id: "bf-pixel", name: "Boyfriend Pixel"},
		{id: "pico", name: "Pico"}
	];

	public static function index(id:String):Int
	{
		for (i in 0...all.length)
			if (all[i].id == id)
				return i;
		return 0;
	}
}
