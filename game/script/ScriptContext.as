package angel.game.script {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.game.GameMenu;
	import angel.game.Room;
	import angel.game.SaveGame;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import flash.display.DisplayObjectContainer;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ScriptContext {
		private var triggeringEntity:SimpleEntity;
		private var scriptRoom:Room;
		private var doAtEnd:Vector.<Function> = new Vector.<Function>();
		private var message:String;
		private var gameLost:Boolean;
		private var gameOver:Boolean;
		
		public var catalog:Catalog;
		
		public function ScriptContext(room:Room, triggeringEntity:SimpleEntity = null) {
			this.triggeringEntity = triggeringEntity;
			this.scriptRoom = room;
			this.catalog = Settings.catalog;
		}
		
		public function entityWithScriptId(entityId:String):SimpleEntity {
			if (entityId == Script.TRIGGERING_ENTITY_ID) {
				return triggeringEntity;
			} else {
				return room.entityInRoomWithId(entityId);
			}
		}
		
		public function get room():Room {
			return scriptRoom;
		}
		
		public function roomChanged(newRoom:Room):void {
			scriptRoom = newRoom;
		}
		
		public function gameIsOver(lose:Boolean):void {
			gameOver = true;
			gameLost = lose;
		}
		
		// f should be a function that takes this ScriptContext as a parameter.
		// These functions will be called (in the order added) after all script actions are processed.
		public function doThisAtEnd(f:Function):void {
			doAtEnd.push(f);
		}
		
		public function pauseAndAddMessage(text:String):void {
			if (room != null) {
				room.pauseGameTimeIndefinitely(this);
			}
			if (message == null) {
				message = text;
			} else {
				message += "\n" + text;
			}
		}
		
		public function endOfScriptActions():void {
			while (doAtEnd.length > 0) {
				var f:Function = doAtEnd.shift();
				f(this); // No, this is not a comment on my satisfaction with the code!
			}
			if (message != null) {
				var options:Object = { callback:continueAfterMessageOk };
				if (gameOver && !gameLost) {
					options.buttons = ["Kewl"];
				}
				Alert.show(message, options );
			}
		}
		
		private function continueAfterMessageOk(button:String):void {
			if (room != null) {
				room.unpauseFromLastIndefinitePause(this);
			}
			if (gameOver) {
				// Room had better not be null here!
				if (gameLost) {
					room.revertToPreCombatSave();
				} else {
					var main:DisplayObjectContainer = room.parent;
					room.cleanup();
					new GameMenu(main, false, null);
				}
			}
		}
		
		public function hasEndOfScriptActions():Boolean {
			return (doAtEnd.length > 0);
		}
		
	}

}