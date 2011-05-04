package angel.game.action {
	import angel.game.Settings;
	import angel.game.Walker;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// For convenience, we're going to piggyback on the room's XML format for content.  The easiest way to
	// create an addNPC action is to copy a walker line from the <contents> of a room file and change "walker" to "addNpc".
	// This means that the NPC is added at a location concretely specified in the XML. 
	// As we start developing content we may find that may too limiting, and may need to figure out some way to vary it.
	
	public class AddNpcAction implements IAction {
		private var walkerXml:XML;
		private static const CONTENTS_VERSION:int = 1;
		
		
		public function AddNpcAction(walkerXml:XML) {
			this.walkerXml = walkerXml;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			return new AddNpcAction(actionXml);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction():Object {
			Settings.currentRoom.addEntityUsingItsLocation(Walker.createFromRoomContentsXml(walkerXml, CONTENTS_VERSION, Settings.catalog));
			return null;
		}
		
	}

}