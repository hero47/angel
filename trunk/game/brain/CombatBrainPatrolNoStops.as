package angel.game.brain {
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainPatrolNoStops extends CombatBrainPatrol {
		
		public function CombatBrainPatrolNoStops(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat, param);
		}
		
		override protected function shouldStop():Boolean {
			return false;
		}
		
	}

}