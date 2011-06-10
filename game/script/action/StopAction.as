package angel.game.script.action {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class StopAction implements IAction {
		private var id:String;
		
		public static const TAG:String = "stop";
		
		public function StopAction(id:String) {
			this.id = id;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "id", actionXml)) {
				return null;
			}
			return new StopAction(actionXml.@id);
			
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var entity:ComplexEntity = context.charWithScriptId(id, TAG);
			if (entity != null) {
				if (entity.movement.moving()) {
					entity.movement.interruptMovementAfterTileFinished();
				}
			}
			return null;
			
		}
		
	}

}