package angel.game.brain {
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.EntityMovement;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainPatrolRun extends CombatBrainPatrol {
		
		public function CombatBrainPatrolRun(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat, param, EntityMovement.GAIT_RUN);
		}
		
	}

}