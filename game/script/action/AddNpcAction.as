package angel.game.script.action {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
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
		private var charXml:XML;
		private static const CONTENTS_VERSION:int = 1;
		
		public static const TAG:String = "addNpc";
		
		public function AddNpcAction(charXml:XML) {
			this.charXml = charXml;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "id", actionXml)) {
				return null;
			}
			return new AddNpcAction(actionXml);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var entity:ComplexEntity = ComplexEntity.createFromRoomContentsXml(charXml, Settings.catalog, context.messages);
			if (entity == null) {
				// don't show another error, catalog will already have displayed error
				return null;
			}
			var spotId:String = charXml.@spot;
			var location:Point;
			if (spotId != "") {
				location = context.locationWithSpotId(spotId, TAG);
			}
			if (location == null) {
				context.room.addEntityUsingItsLocation(entity);
			} else {
				context.room.addEntity(entity, location);
			}
			return null;
		}
		
	}

}