package angel.game.script {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.MessageCollector;
	import angel.game.ComplexEntity;
	import angel.game.GameMenu;
	import angel.game.Room;
	import angel.game.SaveGame;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ScriptContext {
		public var player:ComplexEntity;
		private var triggeringEntity:SimpleEntity;
		private var scriptRoom:Room;
		private var doAtEnd:Vector.<Function> = new Vector.<Function>();
		public var messages:MessageCollector; // holds both script-generated messages and script error messages
		private var gameLost:Boolean;
		private var gameOver:Boolean;
		
		public var catalog:Catalog;
		
		public function ScriptContext(room:Room, player:ComplexEntity, triggeringEntity:SimpleEntity = null) {
			this.triggeringEntity = triggeringEntity;
			this.scriptRoom = room;
			this.player = player;
			this.catalog = Settings.catalog;
			this.messages = new MessageCollector();
		}
		
		public function entityWithScriptId(entityId:String, actionName:String = null):SimpleEntity {
			var entity:SimpleEntity;
			if (entityId == Script.TRIGGERING_ENTITY_ID) {
				entity = triggeringEntity;
			} else {
				entity = room.entityInRoomWithId(entityId);
			}
			if (entity == null) {
				scriptError("No entity '" + entityId + "' in current room.", actionName);
			}
			return entity;
		}
		
		public function charWithScriptId(entityId:String, actionName:String = null):ComplexEntity {
			var entity:SimpleEntity;
			if (entityId == Script.TRIGGERING_ENTITY_ID) {
				entity = triggeringEntity;
			} else {
				entity = room.entityInRoomWithId(entityId);
			}
			if (!(entity is ComplexEntity)) {
				scriptError("No character '" + entityId + "' in current room.", actionName);
			}
			return entity as ComplexEntity;
		}
		
		public function locationWithSpotId(spotId:String, actionName:String = null):Point {
			var location:Point = room.spotLocation(spotId);
			if (location == null) {
				scriptError("spot '" + spotId + "' undefined in current room.", actionName);
			}
			return location;
		}
		
		public function scriptError(text:String, actionName:String = null):void {
			messages.add("Script error" + (actionName == null ? "" : " in " + actionName) + ": " + text);
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
			messages.add(text);
		}
		
		public function endOfScriptActions():void {
			while (doAtEnd.length > 0) {
				var f:Function = doAtEnd.shift();
				f(this); // No, this is not a comment on my satisfaction with the code!
			}
			if (!messages.empty()) {
				if (room != null) {
					room.pauseGameTimeIndefinitely(this);
				}
				var options:Object = { callback:continueAfterMessageOk };
				if (gameOver && !gameLost) {
					options.buttons = ["Kewl"];
				}
				messages.displayIfNotEmpty(null, options);
			}
		}
		
		private function continueAfterMessageOk(button:String):void {
			if (room != null) {
				room.unpauseAndDeleteAllOwnedBy(this);
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