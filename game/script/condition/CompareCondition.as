package angel.game.script.condition {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.game.script.computation.ComputationFactory;
	import angel.game.script.computation.IComputation;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CompareCondition implements ICondition {
		private var left:IComputation;
		private var right:IComputation;
		private var op:Function;
		private var desiredValue:Boolean;
		
		public static const TAG:String = "compare";
		
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
		
		public static function createFromXml(conditionXml:XML, rootScript:Script):ICondition {
			var op:Function = legalOps[conditionXml.@op];
			if (op == null) {
				rootScript.addError(TAG + ": missing or invalid op");
				return null;
			}
			var leftXml:XMLList = conditionXml.left;
			var rightXml:XMLList = conditionXml.right;
			if ((leftXml.length() != 1) || (rightXml.length() != 1)) {
				rootScript.addError(TAG + " requires left and right children");
				return null;
			}
			var left:IComputation = ComputationFactory.createFromXml(leftXml[0], rootScript);
			var right:IComputation = ComputationFactory.createFromXml(rightXml[0], rootScript);
			if ((left == null) || (right == null)) {
				return null;
			}
			return new CompareCondition(op, left, right);
		}
		
		/* INTERFACE angel.game.action.ICondition */
		
		public function isMet(context:ScriptContext):Boolean {
			return op(left, right, context) ? desiredValue : !desiredValue;
		}
		
		public function reverseMeaning():void {
			desiredValue = false;
		}
		
		private static function less(a:IComputation, b:IComputation, context:ScriptContext):Boolean {
			return a.value(context) < b.value(context);
		}
		
		private static function greater(a:IComputation, b:IComputation, context:ScriptContext):Boolean {
			return a.value(context) > b.value(context);
		}
		
		private static function equal(a:IComputation, b:IComputation, context:ScriptContext):Boolean {
			return a.value(context) == b.value(context);
		}
		
		private static function lessOrEqual(a:IComputation, b:IComputation, context:ScriptContext):Boolean {
			return a.value(context) <= b.value(context);
		}
		
		private static function greaterOrEqual(a:IComputation, b:IComputation, context:ScriptContext):Boolean {
			return a.value(context) >= b.value(context);
		}
		
		private static function notEqual(a:IComputation, b:IComputation, context:ScriptContext):Boolean {
			return a.value(context) != b.value(context);
		}
		
	}

}