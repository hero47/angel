package angel.game.brain {
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.EntityMovement;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainPatrolWalk extends CombatBrainPatrol {
		
		public function CombatBrainPatrolWalk(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat, param, EntityMovement.GAIT_WALK);
		}
		
	}

}