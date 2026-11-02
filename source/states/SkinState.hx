package states;

import Ui.Btn;
import data.Skins;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import net.Net;
import objects.Character;

class SkinState extends FlxState
{
	var idx:Int = 0;
	var preview:Character;
	var nameText:FlxText;
	var prev:Btn;
	var next:Btn;
	var ok:Btn;
	var beatTimer:Float = 0;

	override function create()
	{
		super.create();
		Ui.menuMusic();
		var bg = new FlxSprite(0, 0, Paths.img("menus/menuBGBlue"));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		add(bg);

		add(Ui.text(0, 20, FlxG.width, "CHOOSE YOUR SKIN", 56, FlxTextAlign.CENTER));
		nameText = Ui.text(0, 80, FlxG.width, "", 40, FlxTextAlign.CENTER, 0xFFFFE066);
		add(nameText);

		prev = new Btn(60, 280, 120, 120, "<", 72);
		next = new Btn(FlxG.width - 180, 280, 120, 120, ">", 72);
		ok = new Btn(FlxG.width / 2 - 130, FlxG.height - 80, 260, 56, "ACCEPT", 34, 0xFF2E7D32);
		add(prev);
		add(next);
		add(ok);

		idx = Skins.index(Settings.skin);
		show();
	}

	function show():Void
	{
		if (preview != null)
		{
			remove(preview, true);
			preview.destroy();
		}
		var s = Skins.all[idx];
		nameText.text = s.name;
		preview = new Character(s.id, true, FlxG.height - 110, FlxG.width / 2);
		add(preview);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (Transition.active)
			return;
		beatTimer += elapsed;
		if (beatTimer > 0.5)
		{
			beatTimer = 0;
			preview.dance();
		}

		if (Ui.backPressed())
		{
			Transition.to(function():FlxState return new MainMenuState());
			return;
		}

		var l = FlxG.keys.justPressed.LEFT || prev.tapped();
		var r = FlxG.keys.justPressed.RIGHT || next.tapped();
		if (l || r)
		{
			idx = (idx + (r ? 1 : -1) + Skins.all.length) % Skins.all.length;
			FlxG.sound.play("assets/sounds/menu/scroll.ogg");
			show();
		}

		if (ok.tapped() || FlxG.keys.justPressed.ENTER)
		{
			Settings.skin = Skins.all[idx].id;
			Settings.flush();
			Net.send({t: "skin", skin: Settings.skin});
			FlxG.sound.play("assets/sounds/menu/confirm.ogg");
			Transition.to(function():FlxState return new MainMenuState());
		}
	}
}
