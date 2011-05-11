package angel.game.combat {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.FloorTile;
	import angel.common.Prop;
	import angel.common.Tileset;
	import angel.common.Util;
	import angel.game.brain.ICombatBrain;
	import angel.game.ComplexEntity;
	import angel.game.EntityEvent;
	import angel.game.Icon;
	import angel.game.Room;
	import angel.game.RoomExplore;
	import angel.game.RoomMode;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import angel.game.TimedSprite;
	import angel.game.Walker;
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	
	public class RoomCombat implements RoomMode {
		
		public var room:Room;
		public var augmentedReality:AugmentedReality;
		private var iFighterTurnInProgress:int;
		private var combatOver:Boolean = false;
		private var moveUi:CombatMoveUi;
		private var fireUi:CombatFireUi;
		public var mover:CombatMover;
		private var currentFighterHasOpportunityFireCoverFrom:Vector.<ComplexEntity> = new Vector.<ComplexEntity>();
		private var returnHereAfterFire:Point;
		
		// The entities who get combat turns. Everything else is just decoration/obstacles.
		public var fighters:Vector.<ComplexEntity>;
		
		private static const PLAYER_MOVE:String = "Move";
		private static const ENEMY_MOVE:String = "Enemy Action";
		private static const PLAYER_FIRE:String = "Attack";
		private static const ENEMY_FIRE:String = "Enemy Action";
		
		private static const PAUSE_TO_VIEW_MOVE_SECONDS:Number = 1;
		private static const PAUSE_TO_VIEW_FIRE_SECONDS:Number = 1;
		
		private var modeLabel:TextField;
		private var enemyTurnOverlay:Shape;

		public function RoomCombat(room:Room) {
			trace("***BEGINNING COMBAT***");
			this.room = room;
			
			createFighterList();
			
			augmentedReality = new AugmentedReality(this);

			// These listeners can only trigger in specific phases, and finishedMoving advances the phase.
			// I'm keeping them around throughout combat rather than adding and removing them as we flip
			// between phases because it seemed a little cleaner that way, but I'm not certain.
			room.addEventListener(EntityEvent.FINISHED_ONE_TILE_OF_MOVE, checkForOpportunityFire, false, 100);
			room.addEventListener(EntityEvent.FINISHED_MOVING, finishedMovingListener, false, 100);
			room.addEventListener(EntityEvent.DEATH, deathListener, false, 100);
			
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
			
			moveUi = new CombatMoveUi(room, this);
			fireUi = new CombatFireUi(room, this);
			mover = new CombatMover(this);
			
			beginTurnForCurrentFighter();
		}
		
		/****************** INTERFACE angel.game.RoomMode ****************/
		
		public function cleanup():void {
			trace("***ENDING COMBAT***");
			room.unpauseGameTimeAndDeleteCallback();
			
			room.disableUi();
			room.removeEventListener(EntityEvent.FINISHED_ONE_TILE_OF_MOVE, checkForOpportunityFire);
			room.removeEventListener(EntityEvent.FINISHED_MOVING, finishedMovingListener);
			room.removeEventListener(EntityEvent.DEATH, deathListener);
			
			augmentedReality.cleanup();
			
			mover.clearPath();
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
				entity.dispatchEvent(new EntityEvent(EntityEvent.JOINED_COMBAT, true, false, entity));
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
				entity.dispatchEvent(new EntityEvent(EntityEvent.JOINED_COMBAT, true, false, entity));
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
			
			if (entity.isPlayerControlled) {
				fighters.push(entity);
			} else if (entity.isEnemy()) {
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
				mover.clearPath();
				returnHereAfterFire = null;
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
		
		public function fireAndAdvanceToNextPhase(shooter:ComplexEntity, target:ComplexEntity):void {
			if (target == null) {
				trace(shooter.aaId, "reserve fire");
				if (shooter.isPlayerControlled || anyPlayerCanSeeLocation(shooter.location)) {
					displayReserveFireGraphic(shooter);
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
			
		public function throwGrenadeAndAdvanceToNextPhase(shooter:ComplexEntity, targetLocation:Point):void {
			trace(shooter.aaId, "throws grenade at", targetLocation);
			var grenade:Grenade = Grenade.getCopy();
			grenade.throwAt(shooter, targetLocation);
			
			// Give the player some time to gaze at the fire graphic before continuing with turn.
			room.pauseGameTimeForFixedDelay(PAUSE_TO_VIEW_FIRE_SECONDS, finishedFire);
		}
		
		public function setupFireFromCoverMove(mover:ComplexEntity):void {
			Assert.assertTrue(mover == currentFighter(), "wrong fighter");
			Assert.assertTrue(currentFighterHasOpportunityFireCoverFrom.length == 0, "cover list not cleared");
			var moverLocation:Point = mover.location;
			for each (var possibleShooter:ComplexEntity in fighters) {
				if (opposingFactions(possibleShooter, mover) && !Util.entityHasLineOfSight(possibleShooter, moverLocation)) {
					currentFighterHasOpportunityFireCoverFrom.push(possibleShooter);
				}
			}
			returnHereAfterFire = moverLocation;
		}
		
		/**************** opportunity fire ***********************/
		
		private function opposingFactions(fighterA:ComplexEntity, fighterB:ComplexEntity):Boolean {
			return (fighterA.isReallyPlayer != fighterB.isReallyPlayer);
		}
		
		private function checkForOpportunityFire(event:EntityEvent):void {
			var entityMoving:ComplexEntity = ComplexEntity(event.entity);
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
					if (currentFighterHasOpportunityFireCoverFrom.indexOf(shooter) >= 0) {
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
		
		private function deathListener(event:EntityEvent):void {
			var entity:ComplexEntity = ComplexEntity(event.entity);
			if (isFighter(entity)) {
				removeFighterFromCombat(entity);
				checkForCombatOver();
			}
		}
		
		private function displayReserveFireGraphic(shooter:ComplexEntity):void {
			var reserveFireBitmap:Bitmap = new Icon.ReserveFireFloater();
			var reserveFireSprite:TimedSprite = new TimedSprite(room.stage.frameRate);
			reserveFireSprite.addChild(reserveFireBitmap);
			reserveFireSprite.x = shooter.x;
			reserveFireSprite.y = shooter.y - reserveFireSprite.height;
			room.addChild(reserveFireSprite);
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
		private function finishedMovingListener(event:EntityEvent):void {
			trace(event.entity.aaId, "finished moving, iFighter", iFighterTurnInProgress);
			if (checkForCombatOver()) {
				// don't allow next enemy to fire, don't enable player UI, just wait for them to OK the message,
				// which will end combat mode.
				return;
			}
			
			currentFighterHasOpportunityFireCoverFrom.length = 0;
			
			//event.entity won't match currentFighter() if moving entity was killed by opportunity fire
			if (event.entity != currentFighter()) {
				trace(event.entity.aaId, "was killed, don't give them a fire phase");
				finishedFire();
				return;
			}
			currentFighter().actionsRemaining = 1; // everyone gets one action per turn, at least for now
			if (currentFighter().isPlayerControlled) {
				room.enableUi(fireUi, currentFighter());
				modeLabel.text = PLAYER_FIRE;
			} else {
				ICombatBrain(currentFighter().brain).doFire();
				modeLabel.text = ENEMY_FIRE;
			}
		}
		
		// Called each time the timer for gazing at the fire graphic expires, or when an entity was killed by
		// opportunity fire while moving and thus needs to skip their fire phase.
		private function finishedFire():void {
			trace("fighter", iFighterTurnInProgress, "(", currentFighter().aaId, ") finished fire");
			
			if (combatOver) {
				// don't allow next enemy to move, don't enable player UI, just wait for them to OK the message,
				// which will end combat mode.
				return;
			}
			
			if (returnHereAfterFire != null) {
				room.changeEntityLocation(currentFighter(), currentFighter().location, returnHereAfterFire);
				augmentedReality.adjustAllEnemyVisibility();
				returnHereAfterFire = null;
				mover.removeReturnMarker();
			}
				
			goToNextFighter();
			
			if (Settings.showEnemyMoves || currentFighter().isPlayerControlled) {
				currentFighter().centerRoomOnMe();
			} else {
				room.mainPlayerCharacter.centerRoomOnMe();
			}
			
			beginTurnForCurrentFighter();
		}
		
		// Called each time the timer for gazing at the enemy's move dots expires
		private function doPlottedEnemyMove():void {
			trace("enemyMoveTimerListener for fighter #", iFighterTurnInProgress, currentFighter().aaId);
			ICombatBrain(currentFighter().brain).doMove();
		}
		
		private function beginTurnForCurrentFighter():void {
			var fighter:ComplexEntity = currentFighter();
			fighter.dispatchEvent(new EntityEvent(EntityEvent.START_TURN, true, false, fighter));
			if (fighter.isPlayerControlled) {
				trace("Begin turn for PC", fighter.aaId);
				if (enemyTurnOverlay.parent != null) {
					enemyTurnOverlay.parent.removeChild(enemyTurnOverlay);
				}
				if (checkForCombatOver()) {
					// don't allow next enemy to move, don't enable player UI, just wait for them to OK the message,
					// which will end combat mode.
					return;
				}
				room.enableUi(moveUi, fighter);
				modeLabel.text = PLAYER_MOVE;
			} else {
				room.stage.addChild(enemyTurnOverlay);
				modeLabel.text = ENEMY_MOVE;
				trace("Begin turn for npc (pause timer will start before move calc)", fighter.aaId);
				
				// Give the player some time to gaze at the enemy's move dots before continuing with turn.
				// (The timer will be running while enemy calculates move, so if that takes a while once we
				// start complicating the AI, then there may be a delay before the move dots are drawn, but
				// the total time between enemy's turn starting and enemy beginning to follow dots should
				// stay at that time unless we're really slow.)
				room.pauseGameTimeForFixedDelay(PAUSE_TO_VIEW_MOVE_SECONDS, doPlottedEnemyMove);
				
				ICombatBrain(fighter.brain).chooseMoveAndDrawDots();
			}
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