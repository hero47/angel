package angel.game.action {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class OrCondition implements ICondition {
		
		private var conditions:Vector.<ICondition>;
		private var desiredValue:Boolean;
		
		public function OrCondition(conditions:Vector.<ICondition>, desiredValue:Boolean) {
			this.conditions = conditions;
			this.desiredValue = desiredValue;
		}
		
		public static function isSimpleCondition():Boolean {
			return false;
		}
		
		public static function createFromXml(conditionXml:XML):ICondition {
			var andVersion:ICondition = Condition.createFromXml(conditionXml);
			if (andVersion is AndCondition) {
				return new OrCondition(AndCondition(andVersion).conditions, AndCondition(andVersion).desiredValue);
			} else {
				return andVersion;
			}
		}
			
		
		/* INTERFACE angel.game.action.ICondition */
		
		public function isMet():Boolean {
			for each (var condition:ICondition in conditions) {
				if (condition.isMet()) {
					return desiredValue;
				}
			}
			return !desiredValue;
		}
		
	}

}