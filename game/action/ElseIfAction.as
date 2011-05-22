package angel.game.action {
	import angel.common.Assert;
	import angel.game.script.Script;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ElseIfAction implements IActionToBeMergedWithPreviousIf {
				
		private var myScript:Script;
		private var myCondition:ICondition;
		
		public function ElseIfAction(condition:ICondition, script:Script) {
			myCondition = condition;
			myScript = script;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var conditionAndScript:Object = IfAction.conditionAndScriptFromXml(actionXml);
			return (conditionAndScript.script == null ? null : new ElseIfAction(conditionAndScript.condition, conditionAndScript.script));
		}
		
		/* INTERFACE angel.game.action.IActionToBeMergedWithPreviousIf */
		
		public function get condition():ICondition {
			return myCondition;
		}
		
		public function get script():Script {
			return myScript;
		}
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			Assert.fail("ElseIf action should never be executed, it should have been merged with if.");
			return null;
		}
		
	}

}