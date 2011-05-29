package angel.game.action {
	import angel.game.script.ScriptContext;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public interface ICondition {
		function isMet(context:ScriptContext):Boolean;
		function reverseMeaning():void;
		
		// also static function isSimpleCondition():Boolean
		// if isSimpleCondition is true, constructor takes (param, desiredValue)
		// if isSimpleCondition is false, use static function createFromXml(actionXml:XML):IAction
	}
	
}