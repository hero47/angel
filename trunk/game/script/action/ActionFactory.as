package angel.game.script.action {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.game.Flags;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ActionFactory {
		
		private static const actionNameToClass:Object = {
			"addNpc":AddNpcAction,
			"add":AddFlagAction,
			"addToInventory":AddToInventoryAction,
			"change":ChangeAction,
			"changeMainPc":ChangeMainPcAction,
			"changeRoom":ChangeRoomAction,
			"changeToNpc":ChangeToNpcAction,
			"changeToPc":ChangeToPcAction,
			"conversation":ConversationAction,
			"else":ElseAction,
			"elseif":ElseIfAction,
			"elseIf":ElseIfAction,
			"goto":GotoAction,
			"if":IfAction,
			"loseGame":LoseGameAction,
			"message":MessageAction,
			"remove":RemoveFlagAction,
			"removeFromInventory":RemoveFromInventoryAction,
			"removeFromRoom":RemoveFromRoomAction,
			"stop":StopAction,
			"winGame":WinGameAction
		};
		
		public function ActionFactory() {
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