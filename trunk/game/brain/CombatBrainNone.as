package angel.game.brain {
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainNone extends CombatBrainUiMeld {
		
		public function CombatBrainNone(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat);
		}
		
		/* INTERFACE angel.game.brain.ICombatBrain */
		
		override public function doFire():void {
			carryOutAttack(null, null);
		}
		
	}

}