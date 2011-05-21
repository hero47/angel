package angel.game.action {
	import angel.game.script.Script;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IActionToBeMergedWithPreviousIf extends IAction {
	
		function get condition():FlagCondition;
		function get script():Script;
	}
	
}