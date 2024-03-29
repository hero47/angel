package angel.game.script.action {
	import angel.game.Flags;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	//NOTE: This is now redundant, as SetFlagAction setting to 0 does the same thing.
	public class RemoveFlagAction implements IAction {
		private var flag:String;
		
		public static const TAG:String = "removeFlag";
		
		public function RemoveFlagAction(flag:String) {
			this.flag = flag;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "flag", actionXml)) {
				return null;
			}
			var flag:String = actionXml.@flag;
			return new RemoveFlagAction(flag);
		}
		
		public function doAction(context:ScriptContext):Object {
			context.setFlagValue(flag, 0);
			return null;
		}
		
	}

}