package angel.game.script.action {
	import angel.game.Flags;
	import angel.game.script.computation.ComputationFactory;
	import angel.game.script.computation.IComputation;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// adjust flag value by adding the "add" parameter to it.  If parameter is missing, add 1.
	// This is very primitive functionality, only add/subtract constants, can't even add flags together, but it suffices for now.
	public class AdjustFlagAction implements IAction {
		private var flag:String;
		private var add:int;
		
		public static const TAG:String = "set";
		
		public function AdjustFlagAction(flag:String, add:int) {
			this.flag = flag;
			this.add = add;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "flag", actionXml)) {
				return null;
			}
			var flag:String = actionXml.@flag;
			var add:int = (actionXml.@add.length() > 0) ? int(actionXml.@add) : 1;
			return new AdjustFlagAction(flag, add);
		}
		
		public function doAction(context:ScriptContext):Object {
			var currentValue:int = context.getFlagValue(flag);
			context.setFlagValue(flag, currentValue + add);
			return null;
		}
		
	}

}