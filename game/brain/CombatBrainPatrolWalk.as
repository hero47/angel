package angel.game.brain {
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainPatrolWalk extends CombatBrainPatrol {
		
		public function CombatBrainPatrolWalk(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat, param, ComplexEntity.GAIT_WALK);
		}
		
	}

}