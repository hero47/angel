package angel.game.brain {
	import angel.common.Assert;
	import angel.game.combat.CombatFireUi;
	import angel.game.combat.CombatMoveUi;
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.EntityMovement;
	import angel.game.event.EntityQEvent;
	import angel.game.IRoomUi;
	import angel.game.Settings;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainUiMeldPlayer extends CombatBrainUiMeld {
		private var ui:IRoomUi;
		private var incompletePath:Vector.<Point>;
		
		public function CombatBrainUiMeldPlayer(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat);
		}
		
		override public function cleanup():void {
			if (ui != null) {
				ui.disable();
			}
			super.cleanup();
		}
		
		override protected function doMoveBody():void {
			trace("Begin turn for PC", me.aaId);
			me.centerRoomOnMe();
			combat.showPhase(CombatBrainUiMeld.PLAYER_MOVE, false);
			ui = new CombatMoveUi(combat.room, combat);
			combat.room.enableUi(ui, me);
		}
		
		public function setGait(gait:int):void {
			this.gait = gait;
		}
		
		//NOTE: currently (May 2011) AI brains have full access to map data, regardless of line-of-sight.
		//Player-controlled characters are always visible.
		//The BECAME_VISIBLE event specifically means that someone became visible to the player, not vice versa
		//(but the event can occur due to either player or non-player movement)
		override protected function invisibleEntityBecameVisible(event:EntityQEvent):void {
			if (event.complexEntity.isEnemyOf(me)) {
				trace(event.complexEntity.id, "became visible");
				drawTempRingAround(event.complexEntity);
				incompletePath = me.movement.interruptMovementAfterTileFinished();
			}
		}
		
		override protected function moveInterruptedListener(event:EntityQEvent):void {
			Assert.assertTrue(returnHereAfterFire == null, "fire from cover can't be interrupted because it's a one-square move");
			trace(event.simpleEntity.aaId, "move interrupted");
			if (endTurnIfDeadOrCombatOver()) {
				combat.mover.clearPath();
				return;
			}
			
			me.movement.restrictGaitUntilMoveFinished(me.movement.mostRecentGait);
			if (incompletePath.length > 0) {
				combat.mover.setPathAfterInterruption(me, incompletePath);
			}
			incompletePath = null;
			Assert.assertTrue(ui is CombatMoveUi, "Wrong ui type");
			combat.room.enableUi(ui, me);
		}
		
		override protected function doFireBody():void {
			combat.showPhase(CombatBrainUiMeld.PLAYER_FIRE, false);
			if (me.hasAUsableItem()) {
				ui = new CombatFireUi(combat.room, combat);
				combat.room.enableUi(ui, me);
			} else {
				useCombatItemOnTarget(null, null);
			}
		}
		
	}

}