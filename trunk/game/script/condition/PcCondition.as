package angel.game.script.condition {
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
	public class PcCondition implements ICondition {
		private var charId:String;
		private var desiredValue:Boolean;
		
		public static const TAG:String = "pc";
		
		public function PcCondition(charId:String, desiredValue:Boolean, script:Script) {
			this.charId = charId;
			this.desiredValue = desiredValue;
		}
		
		public static function isSimpleCondition():Boolean {
			return true;
		}
		
		/* INTERFACE angel.game.action.ICondition */
		
		public function isMet(context:ScriptContext):Boolean {
			var char:ComplexEntity = context.charWithScriptId(charId, TAG);
			if (char == null) {
				return false;
			}
			return(char.isReallyPlayer ? desiredValue : !desiredValue);
		}
		
		public function reverseMeaning():void {
			desiredValue = false;
		}
		
	}

}