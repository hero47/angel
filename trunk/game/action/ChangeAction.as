package angel.game.action {
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
		
		public function ChangeAction(id:String, xml:XML, xyFromXml:Point) {
			this.id = id;
			this.xml = xml;
			this.xyFromXml = xyFromXml;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var id:String = actionXml.@id;
			var xyFromXml:Point;
			if ((String(actionXml.@x) != "") || (String(actionXml.@y) != "")) {
				xyFromXml = new Point(int(actionXml.@x), int(actionXml.@y));
				if ((xyFromXml.x < 0) || (xyFromXml.y < 0)) {
					Alert.show("Error! Negative position");
					xyFromXml = null;
				}
			}
			var otherXml:XML = actionXml.copy();
			for each (var attributeName:String in ["id", "x", "y"]) {
				if (otherXml.@[attributeName].length() > 0) {
					delete otherXml.@[attributeName];
				}
			}
			return new ChangeAction(id, actionXml, xyFromXml);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var id:String = xml.@id;
			var entity:SimpleEntity = context.entityWithScriptId(id);
			var complexEntity:ComplexEntity = entity as ComplexEntity;
			if (entity == null) {
				Alert.show("Script error: no id " + id + " in room for changeAttributes");
				return null;
			}
			
			var spotId:String = xml.@spot;
			var newLocation:Point;
			if (spotId != "") {
				newLocation = context.room.spotLocation(spotId);
				if (newLocation == null) {
					Alert.show("Error in change: spot '" + spotId + "' undefined in current room.");
				}
			}
			if (xyFromXml != null) {
				if (newLocation != null) {
					Alert.show("Error: change action with both spot and x,y");
				}
				if ((xyFromXml.x > context.room.size.x) || (xyFromXml.y > context.room.size.y)) {
					Alert.show("Error in change: position out of room boundaries");
				} else {
					newLocation = new Point(int(xml.@x), int(xml.@y));
				}
			}
			
			if (newLocation != null) {
				var wasMoving:Boolean = (complexEntity != null) && (complexEntity.moving());
				context.room.changeEntityLocation(entity, entity.location, newLocation);
				if (wasMoving) { // Whatever path they were following is no longer valid
					complexEntity.movement.endMoveImmediately();
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
			}
			
			entity.setCommonPropertiesFromXml(xml);
			return null;
		}
		
	}

}