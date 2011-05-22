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
			"else":ElseAction,
			"elseif":ElseIfAction,
			"elseIf":ElseIfAction,
			"goto":GotoAction,
			"if":IfAction,
			"message":MessageAction,
			"remove":RemoveFlagAction,
			"removeFromRoom":RemoveFromRoomAction,
			"startCombat":StartCombatAction
		};
		
		public function Action() {
			Assert.fail("Should never be called");
		}
		
		public static function createFromXml(actionXml:XML, errorPrefix:String=""):IAction {
			var name:String = actionXml.name();
			if (name == "comment") {
				return null;
			}
			
			var actionClass:Class = actionNameToClass[name];
			if (actionClass == null) {
				Alert.show(errorPrefix + "Unknown action " + name);
				return null;
			}
			
			return actionClass.createFromXml(actionXml);
		}
		
	}

}