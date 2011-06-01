package angel.game.script.condition {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class PcCondition implements ICondition {
		private var charId:String;
		private var desiredValue:Boolean;
		
		public function PcCondition(charId:String, desiredValue:Boolean) {
			this.charId = charId;
			this.desiredValue = desiredValue;
		}
		
		public static function isSimpleCondition():Boolean {
			return true;
		}
		
		/* INTERFACE angel.game.action.ICondition */
		
		public function isMet(context:ScriptContext):Boolean {
			var char:ComplexEntity = context.entityWithScriptId(charId) as ComplexEntity;
			if (char == null) {
				Alert.show("Error in condition: no character '" + charId + "' in current room.");
				return false;
			}
			return(char.isReallyPlayer ? desiredValue : !desiredValue);
		}
		
		public function reverseMeaning():void {
			desiredValue = false;
		}
		
	}

}