package angel.game.action {
	import angel.game.script.ScriptContext;
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
			var andVersion:ICondition = Condition.createFromEnclosingXml(conditionXml);
			if (andVersion is AndCondition) {
				return new OrCondition(AndCondition(andVersion).conditions, AndCondition(andVersion).desiredValue);
			} else {
				return andVersion;
			}
		}
			
		
		/* INTERFACE angel.game.action.ICondition */
		
		public function isMet(context:ScriptContext):Boolean {
			for each (var condition:ICondition in conditions) {
				if (condition.isMet(context)) {
					return desiredValue;
				}
			}
			return !desiredValue;
		}
		
		public function reverseMeaning():void {
			desiredValue = false;
		}
		
	}

}