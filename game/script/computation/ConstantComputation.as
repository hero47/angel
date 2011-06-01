package angel.game.script.computation {
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConstantComputation implements IComputation {
		private var val:int;
		
		public function ConstantComputation(param:String) {
			this.val = int(param);
		}
		
		/* INTERFACE angel.game.action.IComputation */
		
		public function value(context:ScriptContext):int {
			return val;
		}
		
	}

}