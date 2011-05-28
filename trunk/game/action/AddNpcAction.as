package angel.game.action {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.Settings;
	import flash.geom.Point;
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
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			var walker:ComplexEntity = ComplexEntity.createFromRoomContentsXml(walkerXml, CONTENTS_VERSION, Settings.catalog);
			if (walker == null) {
				// don't show another error, catalog will already have displayed error
				return null;
			}
			var spotId:String = walkerXml.@spot;
			var location:Point;
			if (spotId != "") {
				location = Settings.currentRoom.spotLocation(spotId);
				if (location == null) {
					Alert.show("Error in addNpc: spot '" + spotId + "' undefined in current room.");
				}
			}
			if (location == null) {
				Settings.currentRoom.addEntityUsingItsLocation(walker);
			} else {
				Settings.currentRoom.addEntity(walker, location);
			}
			return null;
		}
		
	}

}