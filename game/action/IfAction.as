package angel.game.action {
	import angel.common.Alert;
	import angel.game.Flags;
	import angel.game.script.Script;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class IfAction implements IAction {
		private var flagId:String;
		private var desiredFlagValue:Boolean;
		private var script:Script;
		
		public function IfAction(flagId:String, desiredFlagValue:Boolean, script:Script) {
			this.flagId = flagId;
			this.desiredFlagValue = desiredFlagValue;
			this.script = script;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var flag:String = actionXml.@flag;
			var notFlag:String = actionXml.@notFlag;
			var desiredFlagValue:Boolean;
			
			if ((flag != "") && (notFlag != "")) {
				Alert.show("Error! If action cannot have both flag and notFlag.");
				return null;
			} else if ((flag == "") && (notFlag == "")) {
				Alert.show("Error! If action requires flag or notFlag.");
				return null;
			}
			
			if (flag != "") {
				desiredFlagValue = true;
			} else {
				flag = notFlag;
			}
			Flags.getValue(flag); // if flag is undefined, show error now rather than waiting for script execution
			
			var script:Script = new Script(actionXml, "In if action: ");
			return new IfAction(flag, desiredFlagValue, script);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			if (Flags.getValue(flagId) == desiredFlagValue) {
				script.doActions(doAtEnd);
			}
			return null;
		}
		
	}

}