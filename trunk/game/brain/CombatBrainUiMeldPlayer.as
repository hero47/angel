package angel.game.brain {
	import angel.common.Assert;
	import angel.game.combat.CombatFireUi;
	import angel.game.combat.CombatMoveUi;
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.event.EntityQEvent;
	import angel.game.IRoomUi;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainUiMeldPlayer extends CombatBrainUiMeld {
		private var ui:IRoomUi;
		
		public function CombatBrainUiMeldPlayer(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat);
		}
		
		override protected function doMoveBody():void {
			trace("Begin turn for PC", me.aaId);
			combat.showPhase(RoomCombat.PLAYER_MOVE, false);
			ui = new CombatMoveUi(combat.room, combat);
			combat.room.enableUi(ui, me);
		}
		
		public function setGait(gait:int):void {
			this.gait = gait;
		}
		
		override protected function moveInterruptedListener(event:EntityQEvent):void {
			Assert.assertTrue(returnHereAfterFire == null, "fire from cover can't be interrupted because it's a one-square move");
			combat.mover.clearPath();
			trace(event.simpleEntity.aaId, "move interrupted");
			if (endTurnIfDeadOrCombatOver()) {
				return;
			}
			
			me.movement.restrictGaitUntilMoveFinished(me.movement.mostRecentGait);
			Assert.assertTrue(ui is CombatMoveUi, "Wrong ui type");
			combat.room.enableUi(ui, me);
		}
		
		override protected function doFireBody():void {
			combat.showPhase(RoomCombat.PLAYER_FIRE, false);
			if (me.hasAWeapon()) {
				ui = new CombatFireUi(combat.room, combat);
				combat.room.enableUi(ui, me);
			} else {
				combat.beginFireGunOrReserve(me, null);
			}
		}
		
	}

}