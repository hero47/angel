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
		private var saveDataForCurrentGame:SaveGame;
		
		private var background:Bitmap;
		private var startButton:SimplerButton;
		private var resumeButton:SimplerButton;
		private var quitButton:SimplerButton;
		
		public function GameMenu(main:DisplayObjectContainer, saveDataForCurrentGame:SaveGame = null) {
			this.main = main;
			this.saveDataForCurrentGame = saveDataForCurrentGame;
			
			var splash:SplashResource = Settings.catalog.retrieveSplashResource(Defaults.GAME_MENU_SPLASH_ID);
			background = new Bitmap(splash.bitmapData);
			main.addChild(background);
			
			startButton = new SimplerButton("New Game", startNewGame);
			startButton.width = 100;
			startButton.x = (background.width - startButton.width) / 2;
			startButton.y = 300;
			main.addChild(startButton);
			
			quitButton = new SimplerButton("Close Game", quitGame);
			quitButton.width = 100;
			Util.addBelow(quitButton, startButton, 10);
			
			if (saveDataForCurrentGame != null) {
				resumeButton = new SimplerButton("Return", resumeGame);
				resumeButton.width = 100;
				Util.addBelow(resumeButton, quitButton, 30);
			}
			
		}
		
		public function cleanup():void {
			startButton.cleanup();
			quitButton.cleanup();
			if (resumeButton != null) {
				resumeButton.cleanup();
			}
			main.removeChild(background);
		}
		
		private function startNewGame(event:Event):void {
			saveDataForCurrentGame = Settings.saveDataForNewGame;
			resumeGame(event);
		}
		
		private function resumeGame(event:Event):void {
			LoaderWithErrorCatching.LoadFile(saveDataForCurrentGame.startRoomFile, roomXmlLoaded);
		}
		
		private function roomXmlLoaded(event:Event, completeParam:Object, filename:String):void {
			var xml:XML = Util.parseXml(event.target.data, filename);
			if (xml == null) {
				return;
			}
			var room:Room = Room.createFromXml(xml, saveDataForCurrentGame, filename);
			if (room != null) {
				main.addChild(room);
				room.changeModeTo(RoomExplore, true);
				this.cleanup();
			}
		}
		
		private function quitGame(event:Event):void {
			fscommand("quit");
		}
		
	}

}