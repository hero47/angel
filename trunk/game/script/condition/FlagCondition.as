package angel.game.script.condition {
	import angel.common.Alert;
	import angel.game.Flags;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	public class FlagCondition implements ICondition {
		private var flagId:String;
		private var desiredFlagValue:Boolean;
		
		public function FlagCondition(flagId:String, desiredValue:Boolean) {
			this.flagId = flagId;
			this.desiredFlagValue = desiredValue;
			
			Flags.getValue(flagId); // if flag is undefined, force an error now rather than waiting for script execution
		}
		
		public static function isSimpleCondition():Boolean {
			return true;
		}
		
		public function isMet(context:ScriptContext):Boolean {
			return (Flags.getValue(flagId) == desiredFlagValue);
		}
		
		public function reverseMeaning():void {
			desiredFlagValue = false;
		}
		
	}

}