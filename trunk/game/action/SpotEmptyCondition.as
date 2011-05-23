package angel.game.action {
	import angel.common.Alert;
	import angel.game.Settings;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class SpotEmptyCondition implements ICondition {
		public var spotId:String;
		public var desiredValue:Boolean;
		
		public function SpotEmptyCondition(spotId:String, desiredValue:Boolean) {
			this.spotId = spotId;
			this.desiredValue = desiredValue;
		}
		
		public static function isSimpleCondition():Boolean {
			return true;
		}
		
		/* INTERFACE angel.game.action.ICondition */
		
		public function isMet():Boolean {
			var location:Point = Settings.currentRoom.spotLocation(spotId);
			if (location == null) {
				Alert.show("Error in condition: spot '" + spotId + "' undefined in current room.");
				return false;
			}
			return(Settings.currentRoom.firstEntityIn(location) == null ? desiredValue : !desiredValue);
		}
		
	}

}