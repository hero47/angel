package angel.game {
	import angel.common.*;
	import angel.game.brain.BrainFollow;
	import angel.game.event.EventQueue;
	import angel.game.event.QEvent;
	import angel.game.script.TriggerMaster;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.describeType;
	
	
	// GAME Main class
	public class Main extends Sprite implements IAngelMain {
		private var room:Room;
		private var gameEventQueue:EventQueue = new EventQueue();
		
		public function Main() {
			stage.scaleMode = "noScale";
			Settings.FRAMES_PER_SECOND = stage.frameRate;
			Settings.STAGE_HEIGHT = stage.stageHeight;
			Settings.STAGE_WIDTH = stage.stageWidth;
			Settings.gameEventQueue = gameEventQueue;
			addEventListener(Event.ENTER_FRAME, mainEnterFrame);
			Alert.init(stage);
			
			new InitGameFromFiles(gameInitialized);
		}
		
		private function gameInitialized(save:SaveGame):void {
			Settings.saveDataForNewGame = save;
			new GameMenu(this, true, null);
		}
		
		private function mainEnterFrame(event:Event):void {
			Settings.gameEventQueue.dispatch(new QEvent(this, Room.GAME_ENTER_FRAME));
			Settings.gameEventQueue.handleEvents();
			if (Settings.triggerMaster != null) {
				Settings.triggerMaster.gameEventsFinishedForFrame();
			}
		}
		
		public function get currentRoom():Room {
			return room;
		}
		
		public function startRoom(room:Room):void {
			if (currentRoom != null) {
				currentRoom.cleanup();
			}
			this.room = room;
			if (room != null) {
				addChildAt(room, 0);
			}
		}
		
		public function get asDisplayObjectContainer():DisplayObjectContainer {
			return this;
		}
		
	}	// end class Main
}