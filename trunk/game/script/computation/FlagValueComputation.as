package angel.game.script.computation {
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class FlagValueComputation implements IComputation {
		private var flagId:String;
		
		public static const TAG:String = "flagValue";
		
		public function FlagValueComputation(param:String, script:Script) {
			this.flagId = param;
		}
		
		/* INTERFACE angel.game.action.IComputation */
		
		public function value(context:ScriptContext):int {
			return context.getFlagValue(flagId);
		}
		
	}

}