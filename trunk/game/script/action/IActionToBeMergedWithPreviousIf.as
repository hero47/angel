package angel.game.script.action {
	import angel.game.script.condition.ICondition;
	import angel.game.script.Script;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IActionToBeMergedWithPreviousIf extends IAction {
	
		function get condition():ICondition;
		function get script():Script;
	}
	
}