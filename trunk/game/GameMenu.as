package angel.game {
	import angel.common.Catalog;
	import angel.common.Defaults;
	import angel.common.ICleanup;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.SimplerButton;
	import angel.common.SplashResource;
	import angel.common.Util;
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.system.fscommand;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class GameMenu implements ICleanup {
		
		public static const BUTTON_COLOR:uint = 0xffcccc;
		
		private var main:DisplayObjectContainer;
		
		private var background:Bitmap;
		private var startButton:SimplerButton;
		private var quitButton:SimplerButton;
		
		public function GameMenu(main:DisplayObjectContainer) {
			this.main = main;
			
			var splash:SplashResource = Settings.catalog.retrieveSplashResource(Defaults.GAME_MENU_SPLASH_ID);
			background = new Bitmap(splash.bitmapData);
			main.addChild(background);
			
			startButton = new SimplerButton("New Game", startGame);
			startButton.width = 100;
			startButton.x = (background.width - startButton.width) / 2;
			startButton.y = 300;
			main.addChild(startButton);
			
			quitButton = new SimplerButton("Close Game", quitGame);
			quitButton.width = 100;
			Util.addBelow(quitButton, startButton, 10);
			
		}
		
		public function cleanup():void {
			startButton.cleanup();
			quitButton.cleanup();
			main.removeChild(background);
		}
		
		private function startGame(event:Event):void {
			LoaderWithErrorCatching.LoadFile(Settings.startRoomFile, roomXmlLoaded);
		}
		
		private function roomXmlLoaded(event:Event, filename:String):void {
			var xml:XML = Util.parseXml(event.target.data, filename);
			if (xml == null) {
				return;
			}
			var room:Room = Room.createFromXml(xml, filename);
			if (room != null) {
				main.addChild(room);
				room.addPlayerCharactersFromSettings(Settings.startSpot);
				room.changeModeTo(RoomExplore, true);
				this.cleanup();
			}
		}
		
		private function quitGame(event:Event):void {
			fscommand("quit");
		}
		
	}

}