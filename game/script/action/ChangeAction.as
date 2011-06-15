package angel.game.script.action {
	import angel.common.Alert;
	import angel.common.Util;
	import angel.game.brain.UtilBrain;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ChangeAction implements IAction {
		private var id:String;
		private var xyFromXml:Point;
		private var xml:XML;
		
		public static const TAG:String = "change";
		
		public function ChangeAction(id:String, xml:XML, xyFromXml:Point) {
			this.id = id;
			this.xml = xml;
			this.xyFromXml = xyFromXml;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "id", actionXml)) {
				return null;
			}
			var id:String = actionXml.@id;
			var xyFromXml:Point;
			if ((String(actionXml.@x) != "") || (String(actionXml.@y) != "")) {
				xyFromXml = new Point(int(actionXml.@x), int(actionXml.@y));
				if ((xyFromXml.x < 0) || (xyFromXml.y < 0)) {
					script.addError(TAG + ": Negative position");
					xyFromXml = null;
				}
			}
			var otherXml:XML = actionXml.copy();
			for each (var attributeName:String in ["id", "x", "y"]) { // delete these from list
				if (otherXml.@[attributeName].length() > 0) {
					delete otherXml.@[attributeName];
				}
			}
			return new ChangeAction(id, actionXml, xyFromXml);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var id:String = xml.@id;
			var entity:SimpleEntity = context.entityWithScriptId(id, TAG);
			if (entity == null) {
				return null;
			}
			
			var complexEntity:ComplexEntity = entity as ComplexEntity; // it's not an error for this to be null!
			var spotId:String = xml.@spot;
			var newLocation:Point;
			if (spotId != "") {
				newLocation = context.locationWithSpotId(spotId, TAG);
			}
			if (xyFromXml != null) {
				if (newLocation != null) {
					context.scriptError("contains both spot and x,y", TAG);
				}
				if ((xyFromXml.x > context.room.size.x) || (xyFromXml.y > context.room.size.y)) {
					context.scriptError("position out of room boundaries", TAG);
				} else {
					newLocation = new Point(int(xml.@x), int(xml.@y));
				}
			}
			
			if (newLocation != null) {
				var wasMoving:Boolean = (complexEntity != null) && (complexEntity.moving());
				context.room.changeEntityLocation(entity, entity.location, newLocation);
				if (wasMoving) { // Whatever path they were following is no longer valid
					complexEntity.movement.interruptMovementAfterTileFinished();
				}
			}
			
			if (complexEntity != null) {
				if ((xml.@explore.length() > 0) || (xml.@exploreParam.length() > 0)) {
					var exploreBrainClass:Class = (xml.@explore.length() == 0) ? complexEntity.exploreBrainClass :
							UtilBrain.exploreBrainClassFromString(xml.@explore);
					var exploreParam:String = (xml.@exploreParam.length() == 0) ? complexEntity.exploreBrainParam : xml.@exploreParam;
					complexEntity.setBrain(true, exploreBrainClass, exploreParam);
				}
				if ((xml.@combat.length() > 0) || (xml.@combatParam.length() > 0)) {
					var combatBrainClass:Class = (xml.@combat.length() == 0) ? complexEntity.combatBrainClass :
							UtilBrain.combatBrainClassFromString(xml.@combat);
					var combatParam:String = (xml.@combatParam.length() == 0) ? complexEntity.combatBrainParam : xml.@combatParam;
					complexEntity.setBrain(false, combatBrainClass, combatParam);
				}
				if (xml.@faction.length() > 0) {
					if (complexEntity.isReallyPlayer) {
						context.scriptError("cannot change faction of a player character", TAG);
					} else {
						complexEntity.changeFaction(xml.@faction);
					}
				}
			}
			
			entity.setCommonPropertiesFromXml(xml);
			return null;
		}
		
	}

}