package angel.game.script.condition {
	import angel.common.Alert;
	import angel.game.Flags;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	public class FlagCondition implements ICondition {
		private var flagId:String;
		private var desiredFlagValue:Boolean;
		
		public static const TAG:String = "flag";
		
		public function FlagCondition(flagId:String, desiredValue:Boolean, script:Script) {
			this.flagId = flagId;
			this.desiredFlagValue = desiredValue;
		}
		
		public static function isSimpleCondition():Boolean {
			return true;
		}
		
		public function isMet(context:ScriptContext):Boolean {
			return (context.getFlagValue(flagId) == desiredFlagValue);
		}
		
		public function reverseMeaning():void {
			desiredFlagValue = false;
		}
		
	}

}