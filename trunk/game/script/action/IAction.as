package angel.game.script.action {
	import angel.game.script.ScriptContext;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IAction {
		function doAction(context:ScriptContext):Object; // returns object with topic & id if action is goto, null otherwise
		
		// also static function createFromXml(actionXml:XML):IAction but Actionscript doesn't allow that in interface
	}
	
}