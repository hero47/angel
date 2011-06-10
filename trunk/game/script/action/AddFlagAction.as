package angel.game.script.action {
	import angel.game.Flags;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class AddFlagAction implements IAction {
		private var flag:String;
		
		public static const TAG:String = "addFlag";
		
		public function AddFlagAction(flag:String) {
			this.flag = flag;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "flag", actionXml)) {
				return null;
			}
			var flag:String = actionXml.@flag;
			return new AddFlagAction(flag);
		}
		
		public function doAction(context:ScriptContext):Object {
			Flags.setValue(flag, true);
			return null;
		}
		
	}

}