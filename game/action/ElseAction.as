package angel.game.action {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.game.script.Script;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ElseAction implements IActionToBeMergedWithPreviousIf {
		
		private var myScript:Script;
		
		public function ElseAction(script:Script) {
			this.myScript = script;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var script:Script = new Script(actionXml, "In else action: ");
			return new ElseAction(script);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
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