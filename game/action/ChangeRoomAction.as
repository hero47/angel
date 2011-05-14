package angel.game.action {
	import angel.common.Alert;
	import angel.common.LoaderWithErrorCatching;
	import angel.game.combat.RoomCombat;
	import angel.game.Room;
	import angel.game.RoomExplore;
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
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			doAtEnd.push(changeRoom);
			return null;
		}
		
		private function changeRoom():void {
			if ((filename == null) || (filename == "")) {
				Alert.show("Error! Missing filename in change room action");
				return;
			}
			LoaderWithErrorCatching.LoadFile(filename, roomXmlLoaded);
		}
		
		private function roomXmlLoaded(event:Event, filename:String):void {
			var xml:XML = new XML(event.target.data);
			var newRoom:Room = Room.createFromXml(xml, filename);
			if (newRoom != null) {
				var newMode:Class = startMode;
				if ((newMode == null) && (Settings.currentRoom.mode != null)) {
					newMode = Object(Settings.currentRoom.mode).constructor;
				}
				var roomParent:DisplayObjectContainer = Settings.currentRoom.parent;
				Settings.currentRoom.cleanup();
				roomParent.addChild(newRoom);
				Settings.currentRoom = newRoom;
				
				newRoom.addPlayerCharactersFromSettings(startSpot);
				if (newMode != null) {
					newRoom.changeModeTo(newMode);
				}
				
			}
		}
		
	}

}