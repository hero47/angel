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
	import angel.game.IRoomMode;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import angel.game.TimedSprite;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;

	
	public class RoomCombat implements IRoomMode {
		
		public var room:Room;
		public var augmentedReality:AugmentedReality;
		private var iFighterTurnInProgress:int;
		private var combatOver:Boolean = false;
		private var fireUi:CombatFireUi;
		public var mover:CombatMover;
		
		// The entities who get combat turns. Everything else is just decoration/obstacles.
		public var fighters:Vector.<ComplexEntity>;
		
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
			Settings.gameEventQueue.addListener(this, room, EntityQEvent.DEATH, deathListener);
			
			augmentedReality = new AugmentedReality(this);
			
			enemyTurnOverlay = new Shape();
			enemyTurnOverlay.graphics.beginFill(0x4E7DB1, 0.3); // color to match alert, no clue where that number came from, heh
			enemyTurnOverlay.graphics.drawRect(0, 0, room.stage.stageWidth, room.stage.stageHeight);
			enemyTurnOverlay.graphics.endFill();
			
			modeLabel = Util.textBox("", 400, 60, TextFormatAlign.CENTER, false, 0xffffff);
			modeLabel.mouseEnabled = false;
			//modeLabel.background = true;
			modeLabel.x = (room.stage.stageWidth - modeLabel.width) / 2;
			modeLabel.y = 5;
			room.stage.addChild(modeLabel);
			
			fireUi = new CombatFireUi(room, this);
			mover = new CombatMover(this);
			
			if (!checkForCombatOver()) {
				beginTurnForCurrentFighter();
			}
		}
		
		/****************** INTERFACE angel.game.RoomMode ****************/
		
		public function cleanup():void {
			trace("***ENDING COMBAT***");
			
			room.disableUi();
			Settings.gameEventQueue.removeAllListenersOwnedBy(this);
			room.unpauseAndDeleteAllOwnedBy(this);
			
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
			if (entity is ComplexEntity) {
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
			if (entity.isAlive()) {
				augmentedReality.removeFighter(entity);
				augmentedReality.addFighter(entity);
			}
			// NOTE: I did have checkForCombatOver() here, but decided that room scripts should be free to
			// manipulate entities without regard to whether an intermediate state leaves no enemies in the room.
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
			if (entity.inventory.mainWeapon() != null) {
				entity.inventory.mainWeapon().resetCooldown();
			}
			if (entity.inventory.offWeapon() != null) {
				entity.inventory.offWeapon().resetCooldown();
			}
			
			fighters.push(entity);
			entity.adjustBrainForRoomMode(this);
		}
		
		private function removeFighterFromCombat(deadFighter:ComplexEntity):void {
			deadFighter.adjustBrainForRoomMode(null); // NOTE: If it's this fighter's turn, brain will tidy up and end turn
			
			var indexOfDeadFighter:int = fighters.indexOf(deadFighter);
			Assert.assertTrue(indexOfDeadFighter >= 0, "Removing fighter that's already removed: " + deadFighter.aaId);
			fighters.splice(indexOfDeadFighter, 1);
			
			if (indexOfDeadFighter <= iFighterTurnInProgress) {
				--iFighterTurnInProgress;
				if (iFighterTurnInProgress < 0) {
					iFighterTurnInProgress = fighters.length - 1;
				}
			}
			
			augmentedReality.removeFighter(deadFighter); // do this after it's out of list so the dead one won't "see" stuff
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
		
		/**************** opportunity fire ***********************/
		
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
				if (entityMoving.isEnemyOf(fighters[i])) {
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
				room.pauseGameTimeForFixedDelay(PAUSE_TO_VIEW_FIRE_SECONDS, this, null);
			}
				
		}
		
		// return true if shooter fired, false if not
		private function doOpportunityFireIfLegal(shooter:ComplexEntity, target:ComplexEntity):Boolean {
			trace("Checking", shooter.aaId, "for opportunity fire");
			if ((shooter.actionsRemaining > 0)) {
				if (fireIfLegal(shooter, target, shooter.inventory.mainWeapon())) {
					return true;
				}
				if (fireIfLegal(shooter, target, shooter.inventory.offWeapon())) {
					return true;
				}
			}
			return false;
		}
		
		private function fireIfLegal(shooter:ComplexEntity, target:ComplexEntity, weapon:SingleTargetWeapon):Boolean {
			if ((weapon != null) && (weapon.readyToFire()) &&
						(weapon.expectedDamage(shooter, target) >= Settings.minForOpportunity) &&
						weapon.inRange(shooter, target.location) &&
						Util.entityHasLineOfSight(shooter, target.location)) {
				var coverDamageReductionPercent:int = 0;
				if (target.hasCoverFrom.indexOf(shooter) >= 0) {
					coverDamageReductionPercent = Settings.fireFromCoverDamageReduction;
				}
				trace(shooter.aaId, "opportunity fire at", target.aaId, "coverDamageReductionPercent=", coverDamageReductionPercent);
				weapon.fire(shooter, target, coverDamageReductionPercent);
				return true;
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
					augmentedReality.adjustAllNonPlayerVisibility();
				}
			}
		}

		/*********** Turn-structure related **************/


		// Called each time an entity (player or NPC) finishes its combat move
		// (specifically, during ENTER_FRAME for last frame of movement)
		// Advance to that entity's fire phase.
		
		
		private function beginTurnForCurrentFighter():void {
			CombatBrainUiMeld(currentFighter().brain).startTurn();
		}
		
		private function endTurnListener(event:EntityQEvent):void {
			if (checkForCombatOver()) {
				// don't do anything, just wait for them to OK the message, which will end combat mode.
				return;
			}
			
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
				} else if (fighters[i].faction == ComplexEntity.FACTION_ENEMY) {
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