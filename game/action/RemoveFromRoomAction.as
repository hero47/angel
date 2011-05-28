package angel.game.action {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Remove the first character or prop with the given id from the current room.
	public class RemoveFromRoomAction implements IAction {
		private var id:String;
		
		public function RemoveFromRoomAction(id:String) {
			this.id = id;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			return new RemoveFromRoomAction(actionXml.@id);
		}
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			var entity:SimpleEntity = Script.entityWithScriptId(id);
			if (entity == Settings.currentRoom.mainPlayerCharacter) {
				Alert.show("Error! Cannot remove main player character, must make someone else main first.");
				return null;
			}
			if (Settings.isOnPlayerList(entity)) {
				Settings.removeFromPlayerList(entity);
			}
			Settings.currentRoom.removeEntity(entity);
			return null;
		}
		
	}

}