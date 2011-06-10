package angel.game.script.condition {
	import angel.common.Alert;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class SpotEmptyCondition implements ICondition {
		private var spotId:String;
		private var desiredValue:Boolean;
		
		public static const TAG:String = "spotEmpty";
		
		public function SpotEmptyCondition(spotId:String, desiredValue:Boolean, script:Script) {
			this.spotId = spotId;
			this.desiredValue = desiredValue;
		}
		
		public static function isSimpleCondition():Boolean {
			return true;
		}
		
		/* INTERFACE angel.game.action.ICondition */
		
		public function isMet(context:ScriptContext):Boolean {
			var location:Point = context.locationWithSpotId(spotId, TAG);
			if (location == null) {
				return false;
			}
			return(context.room.firstEntityIn(location) == null ? desiredValue : !desiredValue);
		}
		
		public function reverseMeaning():void {
			desiredValue = false;
		}
		
	}

}