package angel.game.script.computation {
	import angel.game.script.ScriptContext;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IComputation {
		
		function value(context:ScriptContext):int;
	}
	
}