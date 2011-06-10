package angel.game.script.condition {
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class OrCondition implements ICondition {
		
		private var conditions:Vector.<ICondition>;
		private var desiredValue:Boolean;
		
		public static const TAG:String = "or";
		
		public function OrCondition(conditions:Vector.<ICondition>, desiredValue:Boolean) {
			this.conditions = conditions;
			this.desiredValue = desiredValue;
		}
		
		public static function isSimpleCondition():Boolean {
			return false;
		}
		
		public static function createFromXml(conditionXml:XML, script:Script):ICondition {
			var andVersion:ICondition = ConditionFactory.createFromEnclosingXml(conditionXml, script);
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