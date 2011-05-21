package angel.game.action {
	import angel.common.Alert;
	import angel.game.Flags;
	import angel.game.script.Script;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class IfAction implements IAction {
		private var cases:Vector.<ConditionAndScript>;
		
		public function IfAction(condition:FlagCondition, script:Script) {
			cases = new Vector.<ConditionAndScript>();
			cases.push(new ConditionAndScript(condition, script));
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var condition:FlagCondition = FlagCondition.createFromXml(actionXml);
			var script:Script = new Script(actionXml, "In if action: ");
			return new IfAction(condition, script);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			for (var i:int = 0; i < cases.length; ++i) {
				var condition:FlagCondition = cases[i].condition;
				if ((condition == null) || condition.isMet()) {
					cases[i].script.doActions(doAtEnd);
					return null;
				}
			}
			return null;
		}
		
		public function addCase(action:IActionToBeMergedWithPreviousIf):void {
			cases.push(new ConditionAndScript(action.condition, action.script));
		}
		
	}

}

import angel.game.action.FlagCondition;
import angel.game.script.Script;
class ConditionAndScript {
	public var condition:FlagCondition;
	public var script:Script;
	
	public function ConditionAndScript(condition:FlagCondition, script:Script) {
		this.condition = condition;
		this.script = script;
	}
}