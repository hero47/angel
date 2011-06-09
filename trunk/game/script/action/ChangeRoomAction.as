package angel.game.script.action {
	import angel.common.Alert;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Util;
	import angel.game.combat.RoomCombat;
	import angel.game.Room;
	import angel.game.RoomExplore;
	import angel.game.SaveGame;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Change to a new room, change current room's mode, or change to a new room in a specific mode.
	// If changing from one combat room to another combat room, we transfer the original preCombatSave to the new room.
	public class ChangeRoomAction implements IAction {
		private var filename:String;
		private var startSpot:String;
		private var modeClass:Class;
		
		public function ChangeRoomAction(filename:String, startSpot:String=null, startMode:Class=null) {
			this.filename = filename;
			this.startSpot = (startSpot == "" ? null : startSpot);
			this.modeClass = startMode;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var modeClass:Class;
			var modeName:String = actionXml.@mode;
			var filename:String = actionXml.@file;
			var start:String = actionXml.@start;
			switch (modeName) {
				case "combat":
					modeClass = RoomCombat;
				break;
				case "explore":
					modeClass = RoomExplore;
				break;
				case "":
					if (filename == "") {
						Alert.show("Script error! changeRoom requires filename or mode.");
						return null;
					}
				break;
				default:
					Alert.show("Error! Unknown mode " + modeName + " in changeRoom.");
					return null;
				break;
			}
			if ((filename == "") && (start != "")) {
				Alert.show("Warning: start location " + start + " ignored since no room file given in changeRoom.");
			}
			return new ChangeRoomAction(filename, start, modeClass);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			context.doThisAtEnd(changeRoom);
			return null;
		}
		
		private function changeRoom(context:ScriptContext):void {
			if (filename != "") {
				LoaderWithErrorCatching.LoadFile(filename, roomXmlLoaded, context);
			} else if (context.room.mode is modeClass) {
				Alert.show("Error! changeRoom already in requested mode.");
			} else {
				context.room.changeModeTo(modeClass);
			}
		}
		
		private function roomXmlLoaded(event:Event, param:Object, filenameForErrors:String):void {
			var context:ScriptContext = ScriptContext(param);
			var xml:XML = Util.parseXml(event.target.data, filenameForErrors);
			if (xml == null) {
				return;
			}
			
			var oldRoom:Room = context.room;
			var save:SaveGame = new SaveGame();
			save.collectGameInfo(oldRoom);
			save.startLocation = null;
			save.startSpot = startSpot;

			var newRoom:Room = Room.createFromXml(xml, save, filename);
			if (newRoom != null) {
				var modeFromOldRoom:Class = (oldRoom.mode == null ? null : Object(oldRoom.mode).constructor);
				var parentFromOldRoom:DisplayObjectContainer = oldRoom.parent;
				var newMode:Class = (modeClass == null ? modeFromOldRoom : modeClass);
				var oldPreCombatSave:SaveGame = oldRoom.preCombatSave;
				oldRoom.cleanup();
				parentFromOldRoom.addChild(newRoom); // Room will start itself running when it goes on stage
				
				if (newMode != null) {
					newRoom.changeModeTo(newMode);
					if ((newMode is RoomCombat) && (oldPreCombatSave != null)) {
						newRoom.preCombatSave = oldPreCombatSave;
					}
				}
				context.roomChanged(newRoom);
			}
		}
		
	}

}