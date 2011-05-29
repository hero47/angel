package angel.game.action {
	import angel.common.Alert;
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class DistanceComputation implements IComputation {
		private var id1:String;
		private var id2:String;
		
		public function DistanceComputation(param:String) {
			var ids:Array = param.split(",");
			if (ids.length != 2) {
				Alert.show("Script error! Distance requires 'id,id' param.");
			}
			id1 = ids[0];
			id2 = ids[1];
		}
		
		/* INTERFACE angel.game.action.IComputation */
		
		public function value(context:ScriptContext):int {
			var entity1:ComplexEntity = ComplexEntity(context.entityWithScriptId(id1));
			if (entity1 == null) {
				Alert.show("Error! No character " + id1 + " in current room.");
				return 0;
			}
			var entity2:ComplexEntity = ComplexEntity(context.entityWithScriptId(id2));
			if (entity2 == null) {
				Alert.show("Error! No character " + id2 + " in current room.");
				return 0;
			}
			return Util.chessDistance(entity1.location, entity2.location);
			
		}
		
	}

}