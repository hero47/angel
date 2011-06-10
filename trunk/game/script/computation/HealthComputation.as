package angel.game.script.computation {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class HealthComputation implements IComputation {
		private var id:String;
		
		public static const TAG:String = "health";
		
		public function HealthComputation(param:String, script:Script) {
			id = param;
		}
		
		/* INTERFACE angel.game.action.IComputation */
		
		public function value(context:ScriptContext):int {
			var entity:ComplexEntity = context.charWithScriptId(id, TAG);
			return (entity == null ? 0 : entity.currentHealth);
		}
		
	}

}