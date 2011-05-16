package angel.game.action {
	import angel.common.Alert;
	import angel.common.Util;
	import angel.game.brain.UtilBrain;
	import angel.game.ComplexEntity;
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
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			var id:String = xml.@id;
			var entity:SimpleEntity = Settings.currentRoom.entityInRoomWithId(id);
			var complexEntity:ComplexEntity = entity as ComplexEntity;
			if (entity == null) {
				Alert.show("Script error: no id " + id + " in room for changeAttributes");
				return null;
			}
			
			var spotId:String = xml.@spot;
			var newLocation:Point;
			if (spotId != "") {
				newLocation = Settings.currentRoom.spotLocation(spotId);
				if (newLocation == null) {
					Alert.show("Error in change: spot '" + spotId + "' undefined in current room.");
				}
			}
			if (xyFromXml != null) {
				if (newLocation != null) {
					Alert.show("Error: change action with both spot and x,y");
				}
				if ((xyFromXml.x > Settings.currentRoom.size.x) || (xyFromXml.y > Settings.currentRoom.size.y)) {
					Alert.show("Error in change: position out of room boundaries");
				} else {
					newLocation = new Point(int(xml.@x), int(xml.@y));
				}
			}
			
			if (newLocation != null) {
				if ((complexEntity != null) && (complexEntity.moving())) {
					complexEntity.movement.endMoveImmediately();
				}
				Settings.currentRoom.changeEntityLocation(entity, entity.location, newLocation);
			}
			
			if (complexEntity != null) {
				if ((String(xml.@explore) != "") || (String(xml.@exploreParam) != "")) {
					var exploreBrainClass:Class = (String(xml.@explore) == "") ? complexEntity.exploreBrainClass :
							UtilBrain.exploreBrainClassFromString(xml.@explore);
					var exploreParam:String = (String(xml.@exploreParam) == "") ? complexEntity.exploreBrainParam : xml.@exploreParam;
					complexEntity.setBrain(true, exploreBrainClass, exploreParam);
				}
				if ((String(xml.@combat) != "") || (String(xml.@combatParam) != "")) {
					var combatBrainClass:Class = (String(xml.@combat) == "") ? complexEntity.combatBrainClass :
							UtilBrain.combatBrainClassFromString(xml.@combat);
					var combatParam:String = (String(xml.@combatParam) == "") ? complexEntity.combatBrainParam : xml.@combatParam;
					complexEntity.setBrain(false, combatBrainClass, combatParam);
				}
			}
			
			entity.setCommonPropertiesFromXml(xml);
			return null;
		}
		
	}

}