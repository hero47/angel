package angel.game.script.computation {
	import angel.common.Alert;
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class DistanceComputation implements IComputation {
		private var id1:String;
		private var id2:String;
		
		public static const TAG:String = "distance";
		
		public function DistanceComputation(param:String, script:Script) {
			var ids:Array = param.split(",");
			if (ids.length != 2) {
				script.addError(TAG + " requires 'id,id' param.");
			}
			id1 = ids[0];
			id2 = ids[1];
		}
		
		/* INTERFACE angel.game.action.IComputation */
		
		public function value(context:ScriptContext):int {
			var entity1:ComplexEntity = context.charWithScriptId(id1, TAG);
			var entity2:ComplexEntity = context.charWithScriptId(id2, TAG);
			if ((entity1 == null) || (entity2 == null)) {
				return 0;
			}
			return Util.chessDistance(entity1.location, entity2.location);
			
		}
		
	}

}