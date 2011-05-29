package angel.game.action {
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
		
		public function value():int {
			return val;
		}
		
	}

}