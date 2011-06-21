package angel.game.brain {
	import angel.common.Assert;
	import angel.common.Util;
	import angel.game.combat.IWeapon;
	import angel.game.combat.RoomCombat;
	import angel.game.combat.SingleTargetWeapon;
	import angel.game.ComplexEntity;
	import angel.game.event.EntityQEvent;
	import angel.game.Icon;
	import angel.game.Settings;
	import angel.game.TimedSprite;
	import flash.display.DisplayObject;
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
		
		
		public static const PLAYER_MOVE:String = "Move";
		public static const PLAYER_FIRE:String = "Attack";
		public static const ENEMY_ACTION:String = "Enemy Action";
		public static const FRIEND_ACTION:String = "Friend Action";
		public static const CIVILIAN_ACTION:String = "Non-com Action";
		
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
		
		// return true if actually moved, false if not
		public function chooseMoveAndDrawDots():Boolean {
			//override
			Assert.fail("Should be overridden");
			return false;
		}
		
		public function doFire():void {
			// Default: fire at first available target.
			trace(me.aaId, "do fire", this);
			var weapon:SingleTargetWeapon = me.inventory.mainWeapon();
			var target:ComplexEntity = (weapon == null ? null : UtilBrain.getFirstAvailableTarget(me, weapon, combat));
			if (target == null) {
				weapon = me.inventory.offWeapon();
				target = (weapon == null ? null : UtilBrain.getFirstAvailableTarget(me, weapon, combat));
			}
			carryOutAttack(weapon, target);
		}
		
		public function startTurn():void {
			myTurn = true;
			me.actionsRemaining = me.actionsPerTurn;
			Settings.gameEventQueue.dispatch(new EntityQEvent(me, EntityQEvent.START_TURN));
			Settings.gameEventQueue.addListener(this, me, EntityQEvent.FINISHED_MOVING, finishedMovingListener);
			Settings.gameEventQueue.addListener(this, me, EntityQEvent.MOVE_INTERRUPTED, moveInterruptedListener);
			Settings.gameEventQueue.addListener(this, me.room, EntityQEvent.BECAME_VISIBLE, invisibleEntityBecameVisible);
			//CONSIDER: figure out how to skip move entirely if entity can't move, and go straight to fire phase.
			me.movement.initForCombatMove();
			//UNDONE: cooldown for unequipped weapons
			doMoveBody();
		}
		
		protected function doMoveBody():void {
			trace("Begin turn for npc (pause timer will start before move calc)", me.aaId);
			if (Settings.showEnemyMoves) {
				me.centerRoomOnMe();
			} else {
				combat.room.mainPlayerCharacter.centerRoomOnMe();
			}
			combat.showPhase(phaseLabel(), true);
			
			// Give the player some time to gaze at the enemy's move dots before continuing with turn.
			// (The timer will be running while enemy calculates move, so if that takes a while once we
			// start complicating the AI, then there may be a delay before the move dots are drawn, but
			// the total time between enemy's turn starting and enemy beginning to follow dots should
			// stay at that time unless we're really slow.)
			combat.room.pauseGameTimeForFixedDelay(RoomCombat.PAUSE_TO_VIEW_MOVE_SECONDS, this, carryOutPlottedMove);
			var moving:Boolean = chooseMoveAndDrawDots();
			if (!moving) {
				combat.room.unpauseAndDeleteAllOwnedBy(this);
				finishedMovingListener(null);
			}
		}
		
		// Called when the timer for gazing at the enemy's move dots expires, or when player commits move from ui
		public function carryOutPlottedMove():void {
			trace(me.aaId, "carryOutPlottedMove");
			combat.mover.startEntityFollowingPath(me, gait);		
		}
		
		//NOTE: currently (May 2011) AI brains have full access to map data, regardless of line-of-sight.
		//Player-controlled characters are always visible.
		//The BECAME_VISIBLE event specifically means that someone became visible to the player, not vice versa
		//(but the event can occur due to either player or non-player movement)
		private function invisibleEntityBecameVisible(event:EntityQEvent):void {
			if (me.isReallyPlayer && event.complexEntity.isEnemyOf(me)) {
				trace(event.complexEntity.id, "became visible");
				//CONSIDER: center room or hilight the enemy who just became visible?
				me.movement.interruptMovementAfterTileFinished();
			}
		}
		
		protected function moveInterruptedListener(event:EntityQEvent):void {
			// AI brains currently (6/1/11) have no special processing for an interrupted move.
			finishedMovingListener(event);
		}
		
		protected function finishedMovingListener(event:EntityQEvent):void {
			trace(me.aaId, "finished move");
			Settings.gameEventQueue.removeListener(me, EntityQEvent.FINISHED_MOVING, finishedMovingListener);
			Settings.gameEventQueue.removeListener(me, EntityQEvent.MOVE_INTERRUPTED, moveInterruptedListener);
			Settings.gameEventQueue.removeListener(me.room, EntityQEvent.BECAME_VISIBLE, invisibleEntityBecameVisible);
			combat.mover.clearPath();	// If movement finished unexpectedly (via ChangeAction or ??) dots may still be hanging around
			me.hasCoverFrom.length = 0;
			if (endTurnIfDeadOrCombatOver()) {
				return;
			}
			if (me.actionsRemaining > 0) {
				doFireBody();
			} else {
				finishedLastFirePhase();
			}
		}
		
		private function finishedOneFirePhase():void {
			if (endTurnIfDeadOrCombatOver()) {
				return;
			}
			doFireBody();
		}
		
		protected function doFireBody():void {
			//combat.showPhase(phaseLabel(), true); // currently same as move, so no need to update
			doFire();
		}
		
		public function carryOutAttack(weapon:IWeapon, target:Object):void {
			var giveAnotherFirePhase:Boolean = false;
			var pauseToViewFireGraphic:Boolean;
			if ((weapon == null) || (target == null)) {
				pauseToViewFireGraphic = showNoGunOrReserveFire();
			} else {
				weapon.attack(me, target);
				giveAnotherFirePhase = me.hasAUsableWeaponAndEnoughActions();
				pauseToViewFireGraphic = true;
			}
			if (me.isPlayerControlled || Settings.showEnemyMoves) {
				me.centerRoomOnMe();
			}
			
			var goHereNext:Function = (giveAnotherFirePhase ? finishedOneFirePhase : finishedLastFirePhase);
			if (pauseToViewFireGraphic) {
				// Give the player some time to gaze at the fire graphic before continuing with turn.
				combat.room.pauseGameTimeForFixedDelay(RoomCombat.PAUSE_TO_VIEW_FIRE_SECONDS, this, goHereNext);
			} else {
				goHereNext();
			}
		}
		
		// return true if should pause, false if not
		public function showNoGunOrReserveFire():Boolean {
			if (me.isPlayerControlled) {
				displayActionFloater(me, (me.hasAUsableWeapon() ? Icon.ReserveFireFloater : Icon.NoGunFloater));
				return true;
			} 
			// No reserve fire notice now for NPCs
			return false;
		}
		
		// Called when the timer for gazing at the fire graphic expires
		public function finishedLastFirePhase():void {
			trace(me.aaId, "finished fire");
			if (endTurnIfDeadOrCombatOver()) {
				return;
			}
			if (returnHereAfterFire != null) {
				combat.room.changeEntityLocation(me, me.location, returnHereAfterFire);
				combat.augmentedReality.adjustAllNonPlayerVisibility();
				returnHereAfterFire = null;
				combat.mover.removeReturnMarker();
			}
			endTurn();
		}
		
		protected function endTurnIfDeadOrCombatOver():Boolean {
			if (!me.isActive() || combat.checkForCombatOver()) {
				endTurn();
				return true;
			}
			return false;
		}
		
		protected function endTurn():void {
			combat.mover.clearPathAndReturnMarker(); // in case entity is being killed or removed in middle of move
			Settings.gameEventQueue.dispatch(new EntityQEvent(me, EntityQEvent.END_TURN));
			myTurn = false;
		}
		
		public function setupFireFromCoverMove():void {
			Assert.assertTrue(me.hasCoverFrom.length == 0, "cover list not cleared");
			var meLocation:Point = me.location;
			for each (var possibleShooter:ComplexEntity in combat.fighters) {
				if (possibleShooter.isEnemyOf(me) && !Util.entityHasLineOfSight(possibleShooter, meLocation)) {
					me.hasCoverFrom.push(possibleShooter);
				}
			}
			returnHereAfterFire = meLocation;
			combat.mover.displayReturnMarker(meLocation);
		}
		
		private function phaseLabel():String {
			switch (me.faction) {
				case ComplexEntity.FACTION_ENEMY:
				case ComplexEntity.FACTION_ENEMY2:
					return ENEMY_ACTION;
				case ComplexEntity.FACTION_FRIEND:
					return FRIEND_ACTION;
				default:
					return CIVILIAN_ACTION;
			}
		}
		
		// This can become a static utility function if anyone else wants to do the same thing
		private function displayActionFloater(actor:ComplexEntity, graphicClass:Class):void {
			var tempGraphic:DisplayObject = new graphicClass();
			var tempSprite:TimedSprite = new TimedSprite(actor.stage.frameRate);
			tempSprite.addChild(tempGraphic);
			tempSprite.x = actor.x;
			tempSprite.y = actor.y - tempSprite.height;
			actor.room.addChild(tempSprite);
		}
		
	}

}