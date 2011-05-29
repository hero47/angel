package angel.game.action {
	import angel.game.script.ScriptContext;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IComputation {
		
		function value(context:ScriptContext):int;
	}
	
}