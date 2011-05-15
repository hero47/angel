package angel.game.brain {
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.EntityMovement;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainPatrolSprint extends CombatBrainPatrol {
		
		public function CombatBrainPatrolSprint(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat, param, EntityMovement.GAIT_SPRINT);	
		}
		
	}

}