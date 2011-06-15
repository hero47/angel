package angel.game.script {
	import angel.common.Util;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class TriggeredScript {
		public var script:Script;
		public var entityIds:Vector.<String>;
		public var entitySpecialIds:Vector.<String>;
		public var spotIds:Vector.<String>;
		
		public function TriggeredScript() {
			
		}

		public function setEntityIds(idsParam:String):void {
			if (Util.nullOrEmpty(idsParam)) {
				return;
			}
			entityIds = Vector.<String>(idsParam.split(","));
			entitySpecialIds = new Vector.<String>();
			for (var i:int = entityIds.length - 1; i >= 0; --i) {
				if (entityIds[i].charAt(0) == "*") {
					entitySpecialIds.push(entityIds.splice(i, 1)[0].substr(1));
				}
			}
		}
				
		public function passesIdFilter(context:ScriptContext):Boolean {
			if (entityIds == null) {
				return true;
			}
			var entity:SimpleEntity = context.entityWithSpecialId("it");
			if (entityIds.indexOf(entity.id) >= 0) {
				return true;
			}
			for (var i:int = 0; i < entitySpecialIds.length; ++i) {
				if (context.entityWithSpecialId(entitySpecialIds[i]) == entity) {
					return true;
				}
			}
			return false;
		}
			
		public function passesSpotFilter(spotsThisEntityIsOn:Vector.<String>):Boolean {
			if (spotIds == null) {
				return true;
			}
			
			for each (var spotId:String in spotsThisEntityIsOn) {
				if (spotIds.indexOf(spotId) >= 0) {
					return true;
				}
			}
			return false;
		}
		
		public function passesFilter(context:ScriptContext, spotsIfAnyoneCares:Vector.<String>):Boolean {
			return (passesIdFilter(context) && ((spotsIfAnyoneCares == null) || passesSpotFilter(spotsIfAnyoneCares)));
		}
	
		
	}

}