package angel.game.action {
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface IAction {
		function doAction():Object; // returns object with topic & id if action is goto, null otherwise
		
		// also static function createFromXml(actionXml:XML):IAction but Actionscript doesn't allow that in interface
	}
	
}