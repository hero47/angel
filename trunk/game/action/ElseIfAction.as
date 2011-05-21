package angel.game.action {
	import angel.common.Assert;
	import angel.game.script.Script;
	import angel.game.action.FlagCondition;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ElseIfAction implements IActionToBeMergedWithPreviousIf {
				
		private var myScript:Script;
		private var myCondition:FlagCondition;
		
		public function ElseIfAction(condition:FlagCondition, script:Script) {
			myCondition = condition;
			myScript = script;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var condition:FlagCondition = FlagCondition.createFromXml(actionXml);
			var script:Script = new Script(actionXml, "In elseIf action: ");
			return new ElseIfAction(condition, script);
		}
		
		/* INTERFACE angel.game.action.IActionToBeMergedWithPreviousIf */
		
		public function get condition():FlagCondition {
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