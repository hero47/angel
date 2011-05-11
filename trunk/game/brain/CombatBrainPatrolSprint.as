package angel.game.brain {
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainPatrolSprint extends CombatBrainPatrol {
		
		public function CombatBrainPatrolSprint(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat, param, ComplexEntity.GAIT_SPRINT);	
		}
		
	}

}