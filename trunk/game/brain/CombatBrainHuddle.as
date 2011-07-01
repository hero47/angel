package angel.game.brain {
	import angel.common.Prop;
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.Icon;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainHuddle extends CombatBrainNone {
		
		public function CombatBrainHuddle(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat, param);
		}
		
		// return true if actually moved, false if not
		override public function chooseMoveAndDrawDots():Boolean {
			me.huddle();
			return false;
		}
		
		override public function cleanup():void {
			if (me.isActive()) {
				me.standUp();
			}
			super.cleanup();
		}
		
	}

}