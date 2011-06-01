package angel.game.brain {
	import angel.common.Assert;
	import angel.common.Util;
	import angel.game.combat.Grenade;
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.event.EntityQEvent;
	import angel.game.Icon;
	import angel.game.Settings;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */		
	
		// This awkwardly-named class serves as a parent to all the combat brains, and also to an even-more-awkwardly-named
		// player ui-driven brain-substitute.  Between them, they handle all the details of an entity's combat turn.
		
		// Turn structure: Each combatant (beginning with player) gets a turn, in a continuous cycle.  Each entity's
		// turn consists of two phases: move, then fire.  (Actions other than fire may be added later; they will
		// go in the fire phase.)  Move phase has two sub-phases: select path (shown as colored dots), then follow
		// path.  For NPCs we pause after the "select path" portion; for PC, they can select/unselect/change as much
		// as they want via UI, and the "follow path" portion begins when they finally commit to the move.
		// Fire phase for PC is similar to move, with a "select target" that they can do/undo/change as much as they
		// want via UI, and the actual "fire" beginning when they finally commit.  For NPC, there is no visual indication
		// of target and thus no pause to view it.  In both cases, once the "fire" takes place, we pause again to
		// view the results.
		
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
			if (Settings.showEnemyMoves) {
				me.centerRoomOnMe();
			} else {
				combat.room.mainPlayerCharacter.centerRoomOnMe();
			}
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
			doFireBody();
		}
		
		protected function doFireBody():void {
			combat.showPhase(RoomCombat.ENEMY_FIRE, true);
			doFire();
		}
		
		public function beginFireGunOrReserve(shooter:ComplexEntity, target:ComplexEntity):void {
			if (target == null) {
				trace(shooter.aaId, "reserve fire");
				if (shooter.isPlayerControlled) {
					combat.displayActionFloater(shooter, (shooter.currentGun() == null ? Icon.NoGunFloater : Icon.ReserveFireFloater));
				} else if (combat.anyPlayerCanSeeLocation(shooter.location)) {
					combat.displayActionFloater(shooter, Icon.ReserveFireFloater);
				}
			} else {
				trace(shooter.aaId, "firing at", target.aaId, target.location);
				shooter.fireCurrentGunAt(target);
				if (shooter.isPlayerControlled || Settings.showEnemyMoves) {
					shooter.centerRoomOnMe();
				}
			}
			
			// Give the player some time to gaze at the fire graphic before continuing with turn.
			combat.room.pauseGameTimeForFixedDelay(RoomCombat.PAUSE_TO_VIEW_FIRE_SECONDS, this, finishedFire);
		}
			
		public function beginThrowGrenade(shooter:ComplexEntity, targetLocation:Point):void {
			trace(shooter.aaId, "throws grenade at", targetLocation);
			var grenade:Grenade = Grenade.getCopy();
			grenade.throwAt(shooter, targetLocation);
			
			// Give the player some time to gaze at the fire graphic before continuing with turn.
			combat.room.pauseGameTimeForFixedDelay(RoomCombat.PAUSE_TO_VIEW_FIRE_SECONDS, this, finishedFire);
		}
		
		// Called each time the timer for gazing at the fire graphic expires
		private function finishedFire():void {
			trace(me.aaId, "finished fire");
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