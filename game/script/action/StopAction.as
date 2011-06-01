package angel.game.script.action {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.script.ScriptContext;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class StopAction implements IAction {
		private var id:String;
		
		public function StopAction(id:String) {
			this.id = id;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			return new StopAction(actionXml.@id);
			
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var entityWithId:SimpleEntity = context.entityWithScriptId(id);
			if (entityWithId is ComplexEntity) {
				var entity:ComplexEntity = ComplexEntity(entityWithId);
				if (entity.movement.moving()) {
					entity.movement.interruptMovementAfterTileFinished();
				}
			} else {
				Alert.show("Script error: no character " + id + " in room for stop");
			}
			return null;
			
		}
		
	}

}