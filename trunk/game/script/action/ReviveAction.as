package angel.game.script.action {
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ReviveAction implements IAction {
		private var id:String;
		
		public static const TAG:String = "revive";
		
		public function ReviveAction(id:String) {
			this.id = id;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			var id:String = actionXml.@id;
			return new ReviveAction(id == "" ? ScriptContext.SpecialId(Script.SELF) : id);
		}
		
		/* INTERFACE angel.game.script.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var entity:ComplexEntity = context.charWithScriptId(id, TAG);
			if (entity == null) {
				return null;
			}
			entity.revive();
			return null;
		}
		
	}

}