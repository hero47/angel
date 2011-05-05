package angel.game.action {
	import angel.game.Flags;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class RemoveFlagAction implements IAction {
		private var flag:String;
		
		public function RemoveFlagAction(flag:String) {
			this.flag = flag;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var flag:String = actionXml.@flag;
			return new RemoveFlagAction(flag);
		}
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			Flags.setValue(flag, false);
			return null;
		}
		
	}

}