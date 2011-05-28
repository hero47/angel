package angel.game.combat {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Util;
	import angel.game.brain.CombatBrainUiMeld;
	import angel.game.brain.ICombatBrain;
	import angel.game.ComplexEntity;
	import angel.game.EntityMovement;
	import angel.game.event.EntityQEvent;
	import angel.game.Icon;
	import angel.game.Room;
	import angel.game.RoomExplore;
	import angel.game.RoomMode;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import angel.game.TimedSprite;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;

	
	public class RoomCombat implements RoomMode {
		
		public var room:Room;
		public var augmentedReality:AugmentedReality;
		private var iFighterTurnInProgress:int;
		private var combatOver:Boolean = false;
		private var fireUi:CombatFireUi;
		public var mover:CombatMover;
		
		// The entities who get combat turns. Everything else is just decoration/obstacles.
		public var fighters:Vector.<ComplexEntity>;
		
		// screen labels for turn phases
		public static const PLAYER_MOVE:String = "Move";
		public static const ENEMY_MOVE:String = "Enemy Action";
		public static const PLAYER_FIRE:String = "Attack";
		public static const ENEMY_FIRE:String = "Enemy Action";
		
		public static const PAUSE_TO_VIEW_MOVE_SECONDS:Number = 1;
		public static const PAUSE_TO_VIEW_FIRE_SECONDS:Number = 1;
		
		private var modeLabel:TextField;
		private var enemyTurnOverlay:Shape;

		public function RoomCombat(room:Room) {
			trace("***BEGINNING COMBAT***");
			this.room = room;
			
			createFighterList();
			
			Settings.gameEventQueue.addListener(this, room, EntityQEvent.END_TURN, endTurnListener);
			Settings.gameEventQueue.addListener(this, room, EntityQEvent.FINISHED_ONE_TILE_OF_MOVE, checkForOpportunityFire);
			Settings.gameEventQueue.addListener(this, room, EntityQEvent.BECAME_VISIBLE, enemyBecameVisible);
			Settings.gameEventQueue.addListener(this, room, EntityQEvent.DEATH, deathListener);
			
			augmentedReality = new AugmentedReality(this);
			
			enemyTurnOverlay = new Shape();
			enemyTurnOverlay.graphics.beginFill(0x4E7DB1, 0.3); // color to match alert, no clue where that number came from, heh
			enemyTurnOverlay.graphics.drawRect(0, 0, room.stage.stageWidth, room.stage.stageHeight);
			enemyTurnOverlay.graphics.endFill();
			
			modeLabel = Util.textBox("", 350, 60, TextFormatAlign.CENTER, false, 0xffffff);
			modeLabel.mouseEnabled = false;
			//modeLabel.background = true;
			modeLabel.x = (room.stage.stageWidth - modeLabel.width) / 2;
			modeLabel.y = 5;
			room.stage.addChild(modeLabel);
			
			fireUi = new CombatFireUi(room, this);
			mover = new CombatMover(this);
			
			beginTurnForCurrentFighter();
		}
		
		/****************** INTERFACE angel.game.RoomMode ****************/
		
		public function cleanup():void {
			trace("***ENDING COMBAT***");
			room.unpauseGameTimeAndDeleteCallback();
			
			room.disableUi();
			Settings.gameEventQueue.removeAllListenersOwnedBy(this);
			
			augmentedReality.cleanup();
			
			mover.clearPathAndReturnMarker();
			room.stage.removeChild(modeLabel);
			if (enemyTurnOverlay.parent != null) {
				enemyTurnOverlay.parent.removeChild(enemyTurnOverlay);
			}
			
			for each (var fighter:ComplexEntity in fighters) {
				fighter.adjustBrainForRoomMode(null);
			}
		}
		
		// CONSIDER: Adds to end of fighter list. Would it be better to add somewhere else, like right before/after current?
		public function entityAddedToRoom(entity:SimpleEntity):void {
			if ((entity is ComplexEntity) && ComplexEntity(entity).canBeActiveInCombat()) {
				initEntityForCombat(entity as ComplexEntity);
				augmentedReality.addFighter(entity as ComplexEntity);
				Settings.gameEventQueue.dispatch(new EntityQEvent(entity, EntityQEvent.JOINED_COMBAT));
			}
		}
		
		public function entityWillBeRemovedFromRoom(entity:SimpleEntity):void {
			if (fighters.indexOf(entity) >= 0) {
				removeFighterFromCombat(entity as ComplexEntity);
				// NOTE: I did have checkForCombatOver() here, but decided that room scripts should be free to
				// manipulate entities without regard to whether an intermediate state leaves no enemies in the room.
			}
		}
		
		public function playerControlChanged(entity:ComplexEntity, pc:Boolean):void {
			var wasAlreadyAFighter:Boolean = fighters.indexOf(entity) >= 0;
			var shouldBeAFighter:Boolean = entity.canBeActiveInCombat();
			
			if (wasAlreadyAFighter) {
				augmentedReality.removeFighter(entity);
				if (shouldBeAFighter) {
					augmentedReality.addFighter(entity);
				} else {
					removeFighterFromCombat(entity as ComplexEntity);
					// NOTE: I did have checkForCombatOver() here, but decided that room scripts should be free to
					// manipulate entities without regard to whether an intermediate state leaves no enemies in the room.
				}
			} else if (shouldBeAFighter) {
				initEntityForCombat(entity as ComplexEntity);
				augmentedReality.addFighter(entity);
				Settings.gameEventQueue.dispatch(new EntityQEvent(entity, EntityQEvent.JOINED_COMBAT));
			}
		}
		
		/***************** init/cleanup related **********************/
		
		private function createFighterList():void {
			fighters = new Vector.<ComplexEntity>();
			room.forEachComplexEntity(initEntityForCombat); // init health; add enemies to fighter list & init their combat brains
			Util.shuffle(fighters); // enemy turn order is randomized at start of combat and stays the same thereafter
			makeMainPlayerGoFirst();
		}
		
		private function makeMainPlayerGoFirst():void {			
			// Move room.mainPlayerCharacter to the front of the fighters list
			fighters.splice(fighters.indexOf(room.mainPlayerCharacter), 1);
			fighters.splice(0, 0, room.mainPlayerCharacter);
		}
		
		private function initEntityForCombat(entity:ComplexEntity):void {
			entity.initHealth();
			entity.actionsRemaining = 0;
			
			if (entity.isPlayerControlled || entity.isEnemy()) {
				fighters.push(entity);
				entity.adjustBrainForRoomMode(this);
			} // else non-combattant, if there is such a thing; currently (5/5/11) means they're just a prop
		}
		
		//UNDONE - WARNING - Weird undesired things will probably happen if this is called for a player-controlled
		//character while the ui is enabled for that character!
		private function removeFighterFromCombat(deadFighter:ComplexEntity):void {
			var indexOfDeadFighter:int = fighters.indexOf(deadFighter);
			Assert.assertTrue(indexOfDeadFighter >= 0, "Removing fighter that's already removed: " + deadFighter.aaId);
			if (indexOfDeadFighter == iFighterTurnInProgress) {
				mover.clearPathAndReturnMarker();
			}
			if ((room.activeUi != null) && (room.activeUi.currentPlayer == deadFighter)) {
				Assert.fail("Removing active player from combat. This WILL break things.");
			}
			if (indexOfDeadFighter <= iFighterTurnInProgress) {
				--iFighterTurnInProgress;
				if (iFighterTurnInProgress < 0) {
					iFighterTurnInProgress = fighters.length - 1;
				}
			}
			fighters.splice(indexOfDeadFighter, 1);
			deadFighter.adjustBrainForRoomMode(null);
			augmentedReality.removeFighter(deadFighter);
		}
		
		/****************** public “api” for combat brains/ui *******************/
		
		public function showPhase(text:String, isNpcTurn:Boolean):void {
			modeLabel.text = text;
			if (isNpcTurn) {
				room.stage.addChild(enemyTurnOverlay);
			} else if (enemyTurnOverlay.parent != null) {
				room.stage.removeChild(enemyTurnOverlay);
			}
		}
		
		public function beginFireGunOrReserve(shooter:ComplexEntity, target:ComplexEntity):void {
			if (target == null) {
				trace(shooter.aaId, "reserve fire");
				if (shooter.isPlayerControlled) {
					displayTemporaryBitmapAboveHead(shooter, (shooter.currentGun() == null ? Icon.NoGunFloater : Icon.ReserveFireFloater));
				} else if (anyPlayerCanSeeLocation(shooter.location)) {
					displayTemporaryBitmapAboveHead(shooter, Icon.ReserveFireFloater);
				}
			} else {
				trace(shooter.aaId, "firing at", target.aaId, target.location);
				shooter.fireCurrentGunAt(target);
				if (shooter.isPlayerControlled || Settings.showEnemyMoves) {
					shooter.centerRoomOnMe();
				}
			}
			
			// Give the player some time to gaze at the fire graphic before continuing with turn.
			room.pauseGameTimeForFixedDelay(PAUSE_TO_VIEW_FIRE_SECONDS, finishedFire);
		}
			
		public function beginThrowGrenade(shooter:ComplexEntity, targetLocation:Point):void {
			trace(shooter.aaId, "throws grenade at", targetLocation);
			var grenade:Grenade = Grenade.getCopy();
			grenade.throwAt(shooter, targetLocation);
			
			// Give the player some time to gaze at the fire graphic before continuing with turn.
			room.pauseGameTimeForFixedDelay(PAUSE_TO_VIEW_FIRE_SECONDS, finishedFire);
		}
		
		/**************** opportunity fire ***********************/
		
		public function opposingFactions(fighterA:ComplexEntity, fighterB:ComplexEntity):Boolean {
			return (fighterA.isReallyPlayer != fighterB.isReallyPlayer);
		}
		
		private function checkForOpportunityFire(event:EntityQEvent):void {
			var entityMoving:ComplexEntity = event.complexEntity;
			if (fighters.indexOf(entityMoving) < 0) {
				// Entity was already removed from combat (probably a result of triggered script)
				return;
			}
			Assert.assertTrue(currentFighter() == entityMoving, "Wrong entity moving");
			var someoneDidOpportunityFire:Boolean = false;
			
			//NOTE: This assumes only two factions. If we add civilians and want the enemy NPCs
			//to be able to shoot them (or the PCs to avoid shooting them) it will need revision.
			for (var i:int = 0; i < fighters.length; ++i) {
				if (opposingFactions(fighters[i], entityMoving)) {
					// WARNING: using ||= prevents it from executing the function if it's already true!
					someoneDidOpportunityFire = (doOpportunityFireIfLegal(fighters[i], entityMoving) || someoneDidOpportunityFire);
					if (entityMoving.currentHealth <= 0) {
						// If the target is dead, it will have been removed from fighters
						// and this loop is no longer valid!
						break;
					}
				}
			}
			
			if (someoneDidOpportunityFire) {
				//No callback here because we're in the middle of movement and next phase will start from end-move listener
				room.pauseGameTimeForFixedDelay(PAUSE_TO_VIEW_FIRE_SECONDS, null);
			}
				
		}
		
		// return true if shooter fired, false if not
		private function doOpportunityFireIfLegal(shooter:ComplexEntity, target:ComplexEntity):Boolean {
			trace("Checking", shooter.aaId, "for opportunity fire");
			if ((shooter.actionsRemaining > 0)) {
				var gun:Gun = shooter.currentGun();
				if ((gun != null) && (gun.expectedDamage(shooter, target) >= Settings.minForOpportunity) &&
						Util.entityHasLineOfSight(shooter, target.location)) {
					var extraDefense:int = 0;
					if (target.hasCoverFrom.indexOf(shooter) >= 0) {
						extraDefense = Settings.fireFromCoverDamageReduction;
					}
					trace(shooter.aaId, "opportunity fire at", target.aaId, "extraDefense=", extraDefense);
					shooter.fireCurrentGunAt(target, extraDefense);
					return true;
				}
			}
			return false;
		}
		
		/*********** Miscellaneous *************/
		
		public function anyPlayerCanSeeLocation(target:Point):Boolean {
			if (combatOver) {
				// When combat ends, player gets omniscient vision.
				return true;
			}
			for each (var fighter:ComplexEntity in fighters) {
				if (fighter.isPlayerControlled && Util.entityHasLineOfSight(fighter, target)) {
					return true;
				}
			}
			return false;
		}
		
		public function isFighter(entity:ComplexEntity):Boolean {
			return (fighters.indexOf(entity) >= 0);
		}
		
		private function deathListener(event:EntityQEvent):void {
			var entity:ComplexEntity = event.complexEntity;
			if (isFighter(entity)) {
				removeFighterFromCombat(entity);
				checkForCombatOver();
				if (combatOver) {
					augmentedReality.adjustAllEnemyVisibility();
				}
			}
		}
		
		private function displayTemporaryBitmapAboveHead(shooter:ComplexEntity, graphicClass:Class):void {
			var tempGraphic:DisplayObject = new graphicClass();
			var tempSprite:TimedSprite = new TimedSprite(room.stage.frameRate);
			tempSprite.addChild(tempGraphic);
			tempSprite.x = shooter.x;
			tempSprite.y = shooter.y - tempSprite.height;
			room.addChild(tempSprite);
		}

		/*********** Turn-structure related **************/
		
		// Turn structure: Each combatant (beginning with player) gets a turn, in a continuous cycle.  Each entity's
		// turn consists of two phases: move, then fire.  (Actions other than fire may be added later; they will
		// go in the fire phase.)  Move phase has two sub-phases: select path (shown as colored dots), then follow
		// path.  For NPCs we pause after the "select path" portion; for PC, they can select/unselect/change as much
		// as they want via UI, and the "follow path" portion begins when they finally commit to the move.
		// Fire phase for PC is similar to move, with a "select target" that they can do/undo/change as much as they
		// want via UI, and the actual "fire" beginning when they finally commit.  For NPC, there is no visual indication
		// of target and thus no pause to view it.  In both cases, once the "fire" takes place, we pause again to
		// view the results.

		// Called each time an entity (player or NPC) finishes its combat move
		// (specifically, during ENTER_FRAME for last frame of movement)
		// Advance to that entity's fire phase.
		
		
		private function beginTurnForCurrentFighter():void {
			var fighter:ComplexEntity = currentFighter();
			if (checkForCombatOver()) {
				// don't allow next enemy to move, don't enable player UI, just wait for them to OK the message,
				// which will end combat mode.
				return;
			}
			
			if (Settings.showEnemyMoves || currentFighter().isPlayerControlled) {
				currentFighter().centerRoomOnMe();
			} else {
				room.mainPlayerCharacter.centerRoomOnMe();
			}
			
			if (fighter.brain != null) {
				CombatBrainUiMeld(fighter.brain).startTurn();
			} else {
				// Fighter must have had its brain removed by script sometime after combat started; skip that turn.
				finishedFire();
			}
		}
		
		// Called each time the timer for gazing at the fire graphic expires
		private function finishedFire():void {
			Settings.gameEventQueue.dispatch(new EntityQEvent(currentFighter(), EntityQEvent.FINISHED_FIRE));
		}
		
		private function endTurnListener(event:EntityQEvent):void {
			goToNextFighter();
			beginTurnForCurrentFighter();
		}
		
		public function currentFighter():ComplexEntity {
			if (iFighterTurnInProgress >= fighters.length) {
				return fighters[0];
			}
			return fighters[iFighterTurnInProgress];
		}
		
		private function goToNextFighter():void {
			++iFighterTurnInProgress;
			if (iFighterTurnInProgress >= fighters.length) {
				trace("All turns have been processed, go back to first player");
				iFighterTurnInProgress = 0;
			}
		}
		
		//NOTE: currently (May 2011) AI brains have full access to map data, regardless of line-of-sight.
		//Thus, the BECAME_VISIBLE event is only relevant for the player.
		private function enemyBecameVisible(event:EntityQEvent):void {
			if (currentFighter().isPlayerControlled) {
				var movement:EntityMovement = currentFighter().movement;
				if ((movement != null) && movement.moving()) {
					movement.interruptMovementAfterTileFinished();
				}
			}
		}
		
		public function checkForCombatOver():Boolean {
			if (combatOver) {
				// Once it's over, it's over.
				return true;
			}
			if (Settings.controlEnemies) {
				// If we're in the "control enemies" test mode, then there are no non-players and so combat is never over.
				return false;
			}
			
			var playerAlive:Boolean = false;
			var enemyAlive:Boolean = false;
			
			for (var i:int = 0; i < fighters.length; i++) {
				if (fighters[i].isPlayerControlled) {
					playerAlive = true;
				} else {
					enemyAlive = true;
				}
				if (playerAlive && enemyAlive) {
					return false;
				}
			}
			combatOver = true;
			// This boring message will certainly be replaced with something more dramatic, and game state will
			// alter in some scripted fashion. But for now, we just drop back to explore mode and everyone comes
			// back to life.
			Alert.show(playerAlive ? "You won." : "You have been taken out.", { callback:combatOverOk } );
			return true;
		}
		
		private function combatOverOk(button:String):void {
			room.changeModeTo(RoomExplore);
		}
		
	} // end class RoomCombat

}