package angel.game.action {
	import angel.common.Alert;
	import angel.common.Assert;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CompareCondition implements ICondition {
		private var left:IComputation;
		private var right:IComputation;
		private var op:Function;
		private var desiredValue:Boolean;
		
		private static const legalOps:Object = { "lt":less, "gt":greater, "eq":equal, "le":lessOrEqual, "ge":greaterOrEqual,
		"ne":notEqual };
		
		public function CompareCondition(op:Function, left:IComputation, right:IComputation) {
			this.op = op;
			this.left = left;
			this.right = right;
			this.desiredValue = true;
		}
		
		public static function isSimpleCondition():Boolean {
			return false;
		}
		
		public static function createFromXml(conditionXml:XML):ICondition {
			var op:Function = legalOps[conditionXml.@op];
			if (op == null) {
				Alert.show("Error: missing or invalid op in compare");
				return null;
			}
			var leftXml:XMLList = conditionXml.left;
			var rightXml:XMLList = conditionXml.right;
			if ((leftXml.length() != 1) || (rightXml.length() != 1)) {
				Alert.show("Error: compare requires left and right children");
				return null;
			}
			var left:IComputation = Computation.createFromXml(leftXml[0], "Error: compare left");
			var right:IComputation = Computation.createFromXml(rightXml[0], "Error: compare right");
			if ((left == null) || (right == null)) {
				return null;
			}
			return new CompareCondition(op, left, right);
		}
		
		/* INTERFACE angel.game.action.ICondition */
		
		public function isMet():Boolean {
			return op(left, right) ? desiredValue : !desiredValue;
		}
		
		public function reverseMeaning():void {
			desiredValue = false;
		}
		
		private static function less(a:IComputation, b:IComputation):Boolean {
			return a.value() < b.value();
		}
		
		private static function greater(a:IComputation, b:IComputation):Boolean {
			return a.value() > b.value();
		}
		
		private static function equal(a:IComputation, b:IComputation):Boolean {
			return a.value() == b.value();
		}
		
		private static function lessOrEqual(a:IComputation, b:IComputation):Boolean {
			return a.value() <= b.value();
		}
		
		private static function greaterOrEqual(a:IComputation, b:IComputation):Boolean {
			return a.value() >= b.value();
		}
		
		private static function notEqual(a:IComputation, b:IComputation):Boolean {
			return a.value() != b.value();
		}
		
	}

}