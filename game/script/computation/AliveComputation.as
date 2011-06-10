package angel.game.script.computation {
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class AliveComputation implements IComputation {
		private var all:Boolean;
		private var faction:int;
		
		public static const TAG:String = "alive";
		
		public function AliveComputation(param:String, script:Script) {
			if (param == "all") {
				all = true;
			} else {
				faction = ComplexEntity.factionFromName(param);
			}
		}
		
		/* INTERFACE angel.game.script.computation.IComputation */
		
		public function value(context:ScriptContext):int {
			var count:int = 0;
			context.room.forEachComplexEntity(function(entity:ComplexEntity):void{
				if (entity.isAlive() && (all || (entity.faction == faction))) {
					++count;
				}
			} );
			return count;
		}
		
	}

}