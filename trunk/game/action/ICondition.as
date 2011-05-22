package angel.game.action {
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface ICondition {
		function isMet():Boolean;
		
		// also static function isSimpleCondition():Boolean
		// if isSimpleCondition is true, constructor takes (param, desiredValue)
		// if isSimpleCondition is false, use static function createFromXml(actionXml:XML):IAction
	}
	
}