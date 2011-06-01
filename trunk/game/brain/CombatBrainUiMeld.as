package angel.game.brain {
	import angel.common.Assert;
	import angel.common.Util;
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.event.EntityQEvent;
	import angel.game.Settings;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainUiMeld implements ICombatBrain {
		protected var me:ComplexEntity;
		protected var combat:RoomCombat;
		protected var gait:int;
		protected var returnHereAfterFire:Point;
		private var myTurn:Boolean;
		
		public function CombatBrainUiMeld(entity:ComplexEntity, combat:RoomCombat) {
			me = entity;
			this.combat = combat;
		}
		
		public function cleanup():void {
			Settings.gameEventQueue.removeAllListenersOwnedBy(this);
			if (myTurn) {
				endTurn();
			}
			me = null;
		}
		
		public function chooseMoveAndDrawDots():void {
			//override
			Assert.fail("Should be overridden");
		}
		
		public function doFire():void {
			//override
			Assert.fail("Should be overridden");
		}
		
		public function startTurn():void {
			myTurn = true;
			Settings.gameEventQueue.dispatch(new EntityQEvent(me, EntityQEvent.START_TURN));
			Settings.gameEventQueue.addListener(this, me, EntityQEvent.FINISHED_MOVING, finishedMovingListener);
			Settings.gameEventQueue.addListener(this, me, EntityQEvent.MOVE_INTERRUPTED, moveInterruptedListener);
			Settings.gameEventQueue.addListener(this, me.room, EntityQEvent.BECAME_VISIBLE, enemyBecameVisible);
			//CONSIDER: figure out how to skip move entirely if entity can't move, and go straight to fire phase.
			me.movement.initForCombatMove();
			doMoveBody();
		}
		
		protected function doMoveBody():void {
			trace("Begin turn for npc (pause timer will start before move calc)", me.aaId);
			combat.showPhase(RoomCombat.ENEMY_MOVE, true);
			
			// Give the player some time to gaze at the enemy's move dots before continuing with turn.
			// (The timer will be running while enemy calculates move, so if that takes a while once we
			// start complicating the AI, then there may be a delay before the move dots are drawn, but
			// the total time between enemy's turn starting and enemy beginning to follow dots should
			// stay at that time unless we're really slow.)
			combat.room.pauseGameTimeForFixedDelay(RoomCombat.PAUSE_TO_VIEW_MOVE_SECONDS, this, carryOutPlottedMove);
			chooseMoveAndDrawDots();
		}
		
		// Called when the timer for gazing at the enemy's move dots expires, or when player commits move from ui
		public function carryOutPlottedMove():void {
			trace(me.aaId, "carryOutPlottedMove");
			combat.mover.startEntityFollowingPath(me, gait);		
		}
		
		//NOTE: currently (May 2011) AI brains have full access to map data, regardless of line-of-sight.
		//Player-controlled characters are always visible.
		//The BECAME_VISIBLE event specifically means that an enemy became visible to the player, not vice versa
		//(but the event can occur due to either player or enemy movement)
		private function enemyBecameVisible(event:EntityQEvent):void {
			if (me.isReallyPlayer) {
				trace(event.complexEntity.id, "became visible");
				//CONSIDER: center room or hilight the enemy who just became visible?
				me.movement.interruptMovementAfterTileFinished();
			}
		}
		
		protected function moveInterruptedListener(event:EntityQEvent):void {
			Assert.fail("AI move can't be interrupted");
			finishedMovingListener(event);
		}
		
		protected function finishedMovingListener(event:EntityQEvent):void {
			trace(me.aaId, "finished move");
			Settings.gameEventQueue.removeListener(me, EntityQEvent.FINISHED_MOVING, finishedMovingListener);
			Settings.gameEventQueue.removeListener(me, EntityQEvent.MOVE_INTERRUPTED, moveInterruptedListener);
			Settings.gameEventQueue.removeListener(me.room, EntityQEvent.BECAME_VISIBLE, enemyBecameVisible);
			combat.mover.clearPath();	// If movement finished unexpectedly (via ChangeAction or ??) dots may still be hanging around
			me.hasCoverFrom.length = 0;
			if (endTurnIfDeadOrCombatOver()) {
				return;
			}
			me.actionsRemaining = 1; // everyone gets one action per turn, at least for now
			Settings.gameEventQueue.addListener(this, me, EntityQEvent.FINISHED_FIRE, finishedFireListener);
			doFireBody();
		}
		
		protected function doFireBody():void {
			combat.showPhase(RoomCombat.ENEMY_FIRE, true);
			doFire();
		}
		
		private function finishedFireListener(event:EntityQEvent):void {
			trace(me.aaId, "finished fire");
			Settings.gameEventQueue.removeListener(me, EntityQEvent.FINISHED_FIRE, finishedFireListener);
			if (endTurnIfDeadOrCombatOver()) {
				return;
			}
			if (returnHereAfterFire != null) {
				combat.room.changeEntityLocation(me, me.location, returnHereAfterFire);
				combat.augmentedReality.adjustAllEnemyVisibility();
				returnHereAfterFire = null;
				combat.mover.removeReturnMarker();
			}
			endTurn();
		}
		
		protected function endTurnIfDeadOrCombatOver():Boolean {
			if (!me.isAlive() || combat.checkForCombatOver()) {
				endTurn();
				return true;
			}
			return false;
		}
		
		protected function endTurn():void {
			Settings.gameEventQueue.dispatch(new EntityQEvent(me, EntityQEvent.END_TURN));
			myTurn = false;
		}
		
		public function setupFireFromCoverMove():void {
			Assert.assertTrue(me.hasCoverFrom.length == 0, "cover list not cleared");
			var meLocation:Point = me.location;
			for each (var possibleShooter:ComplexEntity in combat.fighters) {
				if (combat.opposingFactions(possibleShooter, me) && !Util.entityHasLineOfSight(possibleShooter, meLocation)) {
					me.hasCoverFrom.push(possibleShooter);
				}
			}
			returnHereAfterFire = meLocation;
			combat.mover.displayReturnMarker(meLocation);
		}
		
	}

}