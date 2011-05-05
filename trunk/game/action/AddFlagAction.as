package angel.game.action {
	import angel.game.Flags;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class AddFlagAction implements IAction {
		private var flag:String;
		
		public function AddFlagAction(flag:String) {
			this.flag = flag;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var flag:String = actionXml.@flag;
			return new AddFlagAction(flag);
		}
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			Flags.setValue(flag, true);
			return null;
		}
		
	}

}