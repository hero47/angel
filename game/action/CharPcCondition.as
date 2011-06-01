package angel.game.action {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CharPcCondition implements ICondition {
		private var charId:String;
		private var desiredValue:Boolean;
		
		public function CharPcCondition(charId:String, desiredValue:Boolean) {
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