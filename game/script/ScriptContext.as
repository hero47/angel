package angel.game.script {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.MessageCollector;
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.GameMenu;
	import angel.game.IAngelMain;
	import angel.game.Main;
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
		private var mainWindow:IAngelMain;
		private var scriptRoom:Room;
		private var scriptIds:Object;
		private var doAtEnd:Vector.<Function> = new Vector.<Function>();
		public var messages:MessageCollector; // holds both script-generated messages and script error messages
		private var gameLost:Boolean;
		private var gameOver:Boolean;
		
		public var catalog:Catalog;
		
		public static const SPECIAL_ID_FIRST_CHARACTER:String = "*";
		public static function SpecialId(which:String):String {
			return SPECIAL_ID_FIRST_CHARACTER + which;
		}
		
		public function ScriptContext(roomOrMain:DisplayObjectContainer, player:ComplexEntity, scriptOwner:Object, triggeringEntity:SimpleEntity) {
			scriptIds = { "it":triggeringEntity, "pc":player , "me":scriptOwner};
			if (roomOrMain is Room) {
				this.scriptRoom = Room(roomOrMain);
				mainWindow = IAngelMain(room.parent);
			} else {
				mainWindow = IAngelMain(roomOrMain);
			}
			this.catalog = Settings.catalog;
			this.messages = new MessageCollector();
		}
		
		public function cloneSettings():ScriptContext {
			var newContext:ScriptContext = new ScriptContext(scriptRoom == null ? mainWindow.asDisplayObjectContainer : scriptRoom,
					null, null, null);
			for (var id:String in scriptIds) {
				newContext.scriptIds[id] = this.scriptIds[id];
			}
			return newContext;
		}
		
		public function get player():ComplexEntity {
			return scriptIds["pc"];
		}
		
		public function entityWithScriptId(entityId:String, actionName:String = null):SimpleEntity {
			var entity:SimpleEntity;
			if (entityId.charAt(0) == "*") {
				entity = scriptIds[entityId.substr(1)];
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
			if (!Util.nullOrEmpty(entityId)) {
				if (entityId.charAt(0) == "*") {
					entity = scriptIds[entityId.substr(1)];
				} else {
					entity = room.entityInRoomWithId(entityId);
				}
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
		
		public function get main():IAngelMain {
			return mainWindow;
		}
		
		public function roomChanged(newRoom:Room):void {
			scriptRoom = newRoom;
		}
		
		public function setSpecialId(idMinusFirstCharacter:String, value:Object):void {
			scriptIds[idMinusFirstCharacter] = value;
		}
		
		public function entityWithSpecialId(idMinusFirstCharacter:String):SimpleEntity {
			return scriptIds[idMinusFirstCharacter];
		}
		
		public function gameIsOver(lose:Boolean, message:String):void {
			gameOver = true;
			gameLost = lose;
			pauseAndAddMessage(message);
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
		
		public function finish():void {
			if (!messages.empty()) { // Display messages; will call this again after user OK's the messagebox
				displayMessagesAsAlert();
			} else {
				doEndOfScriptActions();
			}
		}
		
		private function doEndOfScriptActions():void {
			while (doAtEnd.length > 0) {
				var f:Function = doAtEnd.shift();
				f(this); // No, this is not a comment on my satisfaction with the code!
			}
			if (!messages.empty()) {
				displayMessagesAsAlert();
			} else if (gameOver) {
				// Room had better not be null here!
				if (gameLost) {
					room.revertToPreCombatSave();
				} else {
					new GameMenu(mainWindow, false, null);
				}
			} 
		}
		
		private function displayMessagesAsAlert():void {
			if (room != null) {
				room.pauseGameTimeIndefinitely(this);
			}
			var options:Object = { callback:continueAfterMessageOk };
			if (gameOver && !gameLost) {
				// Wm may have put this in the user story as a joke, but I'm going to take him literally
				options.buttons = ["Kewl"];
			}
			var oldMessages:MessageCollector = messages;
			messages = new MessageCollector();
			oldMessages.displayIfNotEmpty(null, options);
			oldMessages.clear();
		}
		
		private function continueAfterMessageOk(button:String):void {
			if (room != null) {
				room.unpauseAndDeleteAllOwnedBy(this);
			}
			finish();
		}
		
		public function hasEndOfScriptActions():Boolean {
			return (doAtEnd.length > 0);
		}
		
	}

}