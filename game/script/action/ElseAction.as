package angel.game.script.action {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.game.script.condition.ICondition;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ElseAction implements IActionToBeMergedWithPreviousIf {
		
		private var myScript:Script;
		
		public static const TAG:String = "else";
		
		public function ElseAction(script:Script) {
			this.myScript = script;
		}
		
		public static function createFromXml(actionXml:XML, rootScript:Script):IAction {
			var script:Script = new Script(actionXml, rootScript);
			return new ElseAction(script);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			Assert.fail("Else action should never be executed, it should have been merged with if.");
			return null;
		}
		
		/* INTERFACE angel.game.action.IActionToBeMergedWithPrevioiusIf */
		public function get condition():ICondition {
			return null;
		}
		
		public function get script():Script {
			return myScript;
		}
		
	}

}