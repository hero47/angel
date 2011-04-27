package angel.game.action {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.game.Flags;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Action {
		
		private static const actionNameToClass:Object = { "goto":GotoAction, "add":AddFlagAction, "remove":RemoveFlagAction };
		
		public function Action() {
			Assert.assertTrue(true, "Should never be called");
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var name:String = actionXml.name();
			trace(name);
			trace(actionNameToClass[name]);
			if (actionNameToClass[name] == null) {
				Alert.show("Bad action " + name);
				return null;
			}
			
			var actionClass:Class = actionNameToClass[name];
			return actionClass.createFromXml(actionXml);
		}
		
		// returns id if action is "goto"
		public function doAction():String {
			Assert.assertTrue(true, "Should never be called");
			return null;
		}
		
	}

}