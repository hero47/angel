package angel.game {
	import angel.common.Catalog;
	import angel.common.Defaults;
	import angel.common.ICleanup;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.SimplerButton;
	import angel.common.SplashResource;
	import angel.common.Util;
	import angel.game.script.ScriptContext;
	import angel.game.script.TriggerMaster;
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
	public class GameMenu extends Sprite implements ICleanup {
		
		private var saveDataForCurrentGame:SaveGame;
		
		private var main:Main;
		private var background:Bitmap;
		private var startButton:SimplerButton;
		private var resumeButton:SimplerButton;
		private var quitButton:SimplerButton;
		
		public function GameMenu(main:Main, allowResume:Boolean, newSaveData:SaveGame) {
			this.main = main;
			if (allowResume) {
				if (newSaveData == null) {
					saveDataForCurrentGame = SaveGame.loadFromDisk();
				} else {
					newSaveData.saveToDisk();
					saveDataForCurrentGame = newSaveData;
				}
			} else {
				SaveGame.deleteFromDisk();
			}
			
			var splash:SplashResource = Settings.catalog.retrieveSplashResource(Defaults.GAME_MENU_SPLASH_ID);
			background = new Bitmap(splash.bitmapData);
			addChild(background);
			
			startButton = new SimplerButton("New Game", startNewGame, SplashScreen.BUTTON_COLOR);
			startButton.width = 100;
			startButton.x = (background.width - startButton.width) / 2;
			startButton.y = 300;
			addChild(startButton);
			
			quitButton = new SimplerButton("Close Game", quitGame, SplashScreen.BUTTON_COLOR);
			quitButton.width = 100;
			Util.addBelow(quitButton, startButton, 10);
			
			if (this.saveDataForCurrentGame != null) {
				resumeButton = new SimplerButton("Return", resumeGame, SplashScreen.BUTTON_COLOR);
				resumeButton.width = 100;
				Util.addBelow(resumeButton, quitButton, 30);
			}
			main.addChild(this);
		}
		
		public function cleanup():void {
			startButton.cleanup();
			quitButton.cleanup();
			if (resumeButton != null) {
				resumeButton.cleanup();
			}
			removeChild(background);
			if (parent != null) {
				parent.removeChild(this);
			}
		}
		
		private function startNewGame(event:Event):void {
			saveDataForCurrentGame = Settings.saveDataForNewGame;
			resumeGame(event);
			if (Settings.startScript != null) {
				Settings.startScript.run(main);
			}
		}
		
		public function resumeGame(event:Event):void {
			var main:Main = Main(this.parent);
			this.cleanup();
			saveDataForCurrentGame.resumeSavedGame(main);
		}
		
		private function quitGame(event:Event):void {
			fscommand("quit");
		}
		
	}

}