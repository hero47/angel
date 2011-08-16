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
	public class AddFlagAction implements IAction {
		private var flag:String;
		private var value:IComputation;
		
		public static const TAG:String = "addFlag";
		
		public function AddFlagAction(flag:String, value:IComputation) {
			this.flag = flag;
			this.value = value;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "flag", actionXml)) {
				return null;
			}
			var flag:String = actionXml.@flag;
			
			if (actionXml.attributes().length() > 1) {
				var xml:XML = actionXml.copy();
				delete xml.@flag;
				var value:IComputation = ComputationFactory.createFromXml(xml, script);
				return (value == null ? null : new AddFlagAction(flag, value));
			}
			return new AddFlagAction(flag, null);
		}
		
		public function doAction(context:ScriptContext):Object {
			if (value == null) {
				context.setFlagValue(flag, 1);
			} else {
				context.setFlagValue(flag, value.value(context));
			}
			return null;
		}
		
	}

}