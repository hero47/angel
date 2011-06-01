package angel.game.script.action {
	import angel.common.Alert;
	import angel.game.Flags;
	import angel.game.script.condition.ConditionFactory;
	import angel.game.script.condition.ICondition;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class IfAction implements IAction {
		private var cases:Vector.<ConditionAndScript>;
		
		public function IfAction(condition:ICondition, script:Script) {
			cases = new Vector.<ConditionAndScript>();
			cases.push(new ConditionAndScript(condition, script));
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var conditionAndScript:ConditionAndScript = conditionAndScriptFromXml(actionXml);
			if ((conditionAndScript == null) || (conditionAndScript.script == null)) {
				return null;
			}
			return new IfAction(conditionAndScript.condition, conditionAndScript.script);
		}
		
		public static function conditionAndScriptFromXml(actionXml:XML):ConditionAndScript {
			var condition:ICondition;
			var scriptXml:XML;
			condition = ConditionFactory.checkForShortcutVersion(actionXml);
			if (condition != null) {
				scriptXml = actionXml;
			} else {
				condition = ConditionFactory.createFromEnclosingXml(actionXml, true);
				if (condition == null) {
					return null;
				}
				var scriptXmlList:XMLList = actionXml.script;
				if (scriptXmlList.length() != 1) {
					Alert.show("Error! Long version of 'if' action requires exactly one 'script' child.");
					return null;
				}
				scriptXml = scriptXmlList[0];
			}
			var script:Script = new Script(scriptXml, "In if action: ");
			return new ConditionAndScript(condition, script);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			for (var i:int = 0; i < cases.length; ++i) {
				var condition:ICondition = cases[i].condition;
				if ((condition == null) || condition.isMet(context)) {
					cases[i].script.doActions(context);
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

import angel.game.script.condition.ICondition;
import angel.game.script.Script;
internal class ConditionAndScript {
	public var condition:ICondition;
	public var script:Script;
	
	public function ConditionAndScript(condition:ICondition, script:Script) {
		this.condition = condition;
		this.script = script;
	}
}