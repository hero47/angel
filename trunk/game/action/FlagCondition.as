package angel.game.action {
	import angel.common.Alert;
	import angel.game.Flags;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Initially, conditions can only be "flag is set" or "flag is not set"
	// We will be adding more types later, so I'm calling this FlagCondition rather than just Condition
	// Condition will probably be a factory like Action
	public class FlagCondition {
		public var flagId:String;
		public var desiredFlagValue:Boolean;
		
		public function FlagCondition(flagId:String, desiredFlagValue:Boolean) {
			this.flagId = flagId;
			this.desiredFlagValue = desiredFlagValue;
		}
		
		public static function createFromXml(actionXml:XML):FlagCondition {
			var flag:String = actionXml.@flag;
			var notFlag:String = actionXml.@notFlag;
			var desiredFlagValue:Boolean;
			
			if ((flag != "") && (notFlag != "")) {
				Alert.show("Error! Condition cannot have both flag and notFlag.");
				return null;
			} else if ((flag == "") && (notFlag == "")) {
				Alert.show("Error! Condition requires flag or notFlag.");
				return null;
			}
			
			if (flag != "") {
				desiredFlagValue = true;
			} else {
				flag = notFlag;
			}
			Flags.getValue(flag); // if flag is undefined, force an error now rather than waiting for script execution
			
			return new FlagCondition(flag, desiredFlagValue);
		}
		
		public function isMet():Boolean {
			return (Flags.getValue(flagId) == desiredFlagValue);
		}
		
	}

}