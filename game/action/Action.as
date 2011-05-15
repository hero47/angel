package angel.game.action {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.game.Flags;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Action {
		
		private static const actionNameToClass:Object = {
			"addNpc":AddNpcAction,
			"add":AddFlagAction,
			"change":ChangeAction,
			"changeRoom":ChangeRoomAction,
			"changeToNpc":ChangeToNpcAction,
			"changeToPc":ChangeToPcAction,
			"conversation":ConversationAction,
			"goto":GotoAction,
			"if":IfAction,
			"message":MessageAction,
			"remove":RemoveFlagAction,
			"removeFromRoom":RemoveFromRoomAction,
			"startCombat":StartCombatAction
		};
		
		public function Action() {
			Assert.assertTrue(true, "Should never be called");
		}
		
		public static function createFromXml(actionXml:XML, errorPrefix:String=""):IAction {
			var name:String = actionXml.name();
			if (actionNameToClass[name] == null) {
				Alert.show(errorPrefix + "Unknown action " + name);
				return null;
			}
			
			var actionClass:Class = actionNameToClass[name];
			return actionClass.createFromXml(actionXml);
		}
		
	}

}