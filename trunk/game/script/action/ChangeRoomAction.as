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
	public class ChangeRoomAction implements IAction {
		private var filename:String;
		private var startSpot:String;
		private var startMode:Class;
		
		public function ChangeRoomAction(filename:String, startSpot:String=null, startMode:Class=null) {
			this.filename = filename;
			this.startSpot = (startSpot == "" ? null : startSpot);
			this.startMode = startMode;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var modeClass:Class;
			var modeName:String = actionXml.@mode;
			if (modeName == "combat") {
				modeClass = RoomCombat;
			} else if (modeName == "explore") {
				modeClass = RoomExplore;
			} else if (modeName != "") {
				Alert.show("Error! Unknown mode " + modeName);
			}
			return new ChangeRoomAction(actionXml.@file, actionXml.@start, modeClass);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			context.doThisAtEnd(changeRoom);
			return null;
		}
		
		private function changeRoom(context:ScriptContext):void {
			if ((filename == null) || (filename == "")) {
				Alert.show("Error! Missing filename in change room action");
				return;
			}
			LoaderWithErrorCatching.LoadFile(filename, roomXmlLoaded, context);
		}
		
		private function roomXmlLoaded(event:Event, param:Object, filenameForErrors:String):void {
			var context:ScriptContext = ScriptContext(param);
			var xml:XML = Util.parseXml(event.target.data, filenameForErrors);
			if (xml == null) {
				return;
			}
			
			var oldRoom:Room = context.room;
			var save:SaveGame = new SaveGame();
			save.collectRoomInfo(oldRoom);
			save.startLocation = null;
			save.startSpot = startSpot;

			var newRoom:Room = Room.createFromXml(xml, save, filename);
			if (newRoom != null) {
				var modeFromOldRoom:Class = (oldRoom.mode == null ? null : Object(oldRoom.mode).constructor);
				var parentFromOldRoom:DisplayObjectContainer = oldRoom.parent;
				var newMode:Class = (startMode == null ? modeFromOldRoom : startMode);
				oldRoom.cleanup();
				parentFromOldRoom.addChild(newRoom); // Room will start itself running when it goes on stage
				
				if (newMode != null) {
					newRoom.changeModeTo(newMode, true);
				}
				context.roomChanged(newRoom);
			}
		}
		
	}

}