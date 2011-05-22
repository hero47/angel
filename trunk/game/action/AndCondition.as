package angel.game.action {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class AndCondition implements ICondition {
		
		// public so that OrCondition can create itself from an AndCondition
		public var conditions:Vector.<ICondition>;
		public var desiredValue:Boolean;
		
		public function AndCondition(conditions:Vector.<ICondition>, desiredValue:Boolean) {
			this.conditions = conditions;
			this.desiredValue = desiredValue;
		}
		
		public static function isSimpleCondition():Boolean {
			return false;
		}
		
		public static function createFromXml(conditionXml:XML):ICondition {
			return Condition.createFromXml(conditionXml);
		}
			
		
		/* INTERFACE angel.game.action.ICondition */
		
		public function isMet():Boolean {
			for each (var condition:ICondition in conditions) {
				if (!condition.isMet()) {
					return !desiredValue;
				}
			}
			return desiredValue;
		}
		
	}

}