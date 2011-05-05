package angel.game.action {
	import angel.game.Settings;
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
			Settings.currentRoom.removeEntityWithId(id);
			return null;
		}
		
	}

}