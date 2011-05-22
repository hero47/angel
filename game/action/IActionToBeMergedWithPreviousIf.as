package angel.game.action {
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