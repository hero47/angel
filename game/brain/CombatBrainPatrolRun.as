package angel.game.brain {
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainPatrolRun extends CombatBrainPatrol {
		
		public function CombatBrainPatrolRun(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat, param, ComplexEntity.GAIT_RUN);
		}
		
	}

}