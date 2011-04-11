package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.FloorTile;
	import angel.common.Prop;
	import angel.common.Util;
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
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;
	import flash.utils.Timer;

	
	public class RoomCombat implements RoomMode {
		
		public var room:Room;
		private var iFighterTurnInProgress:int;
		private var combatOver:Boolean = false;
		private var moveUi:CombatMoveUi;
		private var fireUi:CombatFireUi;
		
		// The entities who get combat turns. Everything else is just decoration/obstacles.
		public var fighters:Vector.<ComplexEntity>;
		
		// public because they're accessed by the CombatMoveUi and/or entity combat brains
		public var dots:Vector.<Shape> = new Vector.<Shape>();
		public var endIndexes:Vector.<int> = new Vector.<int>();
		public var path:Vector.<Point> = new Vector.<Point>();
		
		// Colors for movement dots/hilights
		private static const WALK_COLOR:uint = 0x00ff00;
		private static const RUN_COLOR:uint = 0xffd800;
		private static const SPRINT_COLOR:uint = 0xff0000;
		private static const OUT_OF_RANGE_COLOR:uint = 0x888888;
		private static const ENEMY_MARKER_COLOR:uint = 0xff0000;
		private static const PLAYER_MARKER_COLOR:uint = 0x0000ff;
		private static const GRID_COLOR:uint = 0xff0000;
		
		private static const PLAYER_MOVE:String = "Move";
		private static const ENEMY_MOVE:String = "Enemy Action";
		private static const PLAYER_FIRE:String = "Attack";
		private static const ENEMY_FIRE:String = "Enemy Action";
		
		private static const PAUSE_TO_VIEW_MOVE_TIME:int = 1000;
		private static const PAUSE_TO_VIEW_FIRE_TIME:int = 1000;
		
		public var statDisplay:CombatStatDisplay;
		private var modeLabel:TextField;
		private var enemyTurnOverlay:Shape;
		
		private var enemyHealthDisplay:TextField;
		private static const ENEMY_HEALTH_PREFIX:String = "Enemy: ";

		public function RoomCombat(room:Room) {
			trace("***BEGINNING COMBAT***");
			this.room = room;
			drawCombatGrid(room.decorationsLayer.graphics);
			
			fighters = new Vector.<ComplexEntity>();
			room.forEachComplexEntity(initEntityForCombat); // init health; add enemies to fighter list & init their combat brains
			Util.shuffle(fighters); // enemy turn order is randomized at start of combat and stays the same thereafter
			
			makeMainPlayerGoFirst();
			adjustAllEnemyVisibility();

			// These listeners can only trigger in specific phases, and finishedMoving advances the phase.
			// I'm keeping them around throughout combat rather than adding and removing them as we flip
			// between phases because it seemed a little cleaner that way, but I'm not certain.
			room.addEventListener(EntityEvent.MOVED, entityMovingToNewTile);
			room.addEventListener(EntityEvent.FINISHED_ONE_TILE_OF_MOVE, entityStandingOnNewTile);
			room.addEventListener(EntityEvent.FINISHED_MOVING, finishedMovingListener);
			
			statDisplay = new CombatStatDisplay();
			room.stage.addChild(statDisplay);
			
			enemyTurnOverlay = new Shape();
			enemyTurnOverlay.graphics.beginFill(0x4E7DB1, 0.3); // color to match alert, no clue where that number came from, heh
			enemyTurnOverlay.graphics.drawRect(0, 0, room.stage.stageWidth, room.stage.stageHeight);
			enemyTurnOverlay.graphics.endFill();
			
			enemyHealthDisplay = CombatStatDisplay.createHealthTextField();
			enemyHealthDisplay.x = room.stage.stageWidth - enemyHealthDisplay.width - 10;
			enemyHealthDisplay.y = 10;
			adjustEnemyHealthDisplay(-1);
			room.stage.addChild(enemyHealthDisplay);
			
			modeLabel = Util.textBox("", 300, 60, TextFormatAlign.CENTER, false, 0xffffff);
			modeLabel.mouseEnabled = false;
			//modeLabel.background = true;
			modeLabel.x = (room.stage.stageWidth - modeLabel.width) / 2;
			modeLabel.y = 5;
			room.stage.addChild(modeLabel);
			
			moveUi = new CombatMoveUi(room, this);
			fireUi = new CombatFireUi(room, this);
			
			beginTurnForCurrentFighter();
		}

		private function makeMainPlayerGoFirst():void {			
			// Move room.mainPlayerCharacter to the front of the fighters list
			fighters.splice(fighters.indexOf(room.mainPlayerCharacter), 1);
			fighters.splice(0, 0, room.mainPlayerCharacter);
		}
		
		public function cleanup():void {
			trace("***ENDING COMBAT***");
			Assert.assertTrue(!room.paused, "Closing down combat ui while pause timer active");
			
			room.disableUi();
			room.removeEventListener(EntityEvent.MOVED, entityMovingToNewTile);
			room.removeEventListener(EntityEvent.FINISHED_ONE_TILE_OF_MOVE, entityStandingOnNewTile);
			room.removeEventListener(EntityEvent.FINISHED_MOVING, finishedMovingListener);
			
			room.decorationsLayer.graphics.clear(); // remove grid outlines
			clearDots();
			room.stage.removeChild(statDisplay);
			room.stage.removeChild(modeLabel);
			if (enemyTurnOverlay.parent != null) {
				enemyTurnOverlay.parent.removeChild(enemyTurnOverlay);
			}
			
			for (var i:int = 0; i < fighters.length; i++) {
				cleanupEntityFromCombat(fighters[i]);
			}
		}
		
		private function initEntityForCombat(entity:ComplexEntity):void {
			entity.initHealth();
			entity.actionsRemaining = 0;

			entity.setTextOverHead(String(entity.currentHealth));
			
			if (entity.isPlayerControlled) {
				fighters.push(entity);
				createCombatMarker(entity, PLAYER_MARKER_COLOR);
			} else if (entity.isEnemy()) {
				fighters.push(entity);
				entity.joinCombat(this);
				createCombatMarker(entity, ENEMY_MARKER_COLOR);
			}
		}
		
		private function createCombatMarker(entity:ComplexEntity, color:uint):void {
			var marker:Shape = new Shape();
			marker.graphics.lineStyle(4, color, 0.7);
			marker.graphics.drawCircle(0, 0, 15);
			marker.graphics.drawCircle(0, 0, 30);
			marker.graphics.drawCircle(0, 0, 45);
			// TAG tile-width-is-twice-height: aspect will be off if tiles no longer follow this rule!
			marker.scaleY = 0.5;
			room.decorationsLayer.addChild(marker);
			
			entity.marker = marker;
			room.moveMarkerIfNeeded(entity);
		}
		
		
		private function cleanupEntityFromCombat(entity:ComplexEntity):void {
			entity.exitCurrentMode();
			if (entity.marker != null) {
				room.decorationsLayer.removeChild(entity.marker);
				entity.marker = null;
			}

			entity.setTextOverHead(null);
			entity.visible = true;
		}
		
		//NOTE: grid lines are tweaked up by one pixel because the tile image bitmaps actually extend one pixel outside the
		//tile boundaries, overlapping the previous row.
		private function drawCombatGrid(graphics:Graphics):void {
			graphics.lineStyle(0, GRID_COLOR, 1);
			var startPoint:Point = Floor.topCornerOf(new Point(0, 0));
			var endPoint:Point = Floor.topCornerOf(new Point(0, room.size.y));
			for (var i:int = 0; i <= room.size.x; i++) {
				graphics.moveTo(startPoint.x + (i * Floor.FLOOR_TILE_X), startPoint.y + (i * Floor.FLOOR_TILE_Y) - 1);
				graphics.lineTo(endPoint.x + (i * Floor.FLOOR_TILE_X), endPoint.y + (i * Floor.FLOOR_TILE_Y) - 1);
			}
			endPoint = Floor.topCornerOf(new Point(room.size.x, 0));
			for (i = 0; i <= room.size.y; i++) {
				graphics.moveTo(startPoint.x - (i * Floor.FLOOR_TILE_X), startPoint.y + (i * Floor.FLOOR_TILE_Y) - 1);
				graphics.lineTo(endPoint.x - (i * Floor.FLOOR_TILE_X), endPoint.y + (i * Floor.FLOOR_TILE_Y) - 1);
			}
		}		
		
		public function adjustEnemyHealthDisplay(points:int):void {
			if (points < 0) {
				enemyHealthDisplay.visible = false;
			} else {
				enemyHealthDisplay.text = ENEMY_HEALTH_PREFIX + String(points);
				enemyHealthDisplay.visible = true;
			}	
		}
		
		private function combatOverOk(button:String):void {
			room.changeModeTo(RoomExplore);
		}
		
		/****************** Used by both player & NPCs during combat turns *******************/
		
		public function startEntityFollowingPath(entity:ComplexEntity, gait:int):void {
			entity.startMovingAlongPath(path, gait); //CAUTION: this path now belongs to entity!
			path = new Vector.<Point>();
			endIndexes.length = 0;
		}
		
		// Remove dots at the end of the path, starting from index startFrom (default == remove all)
		public function clearDots(startFrom:int = 0):void {
			for (var i:int = startFrom; i < dots.length; i++) {
				room.decorationsLayer.removeChild(dots[i]);
			}
			dots.length = startFrom;
		}
		
		// TAG tile-width-is-twice-height: dots will not have correct aspect if tiles no longer follow this rule!
		private static const DOT_X_RADIUS:int = 12;
		private static const DOT_Y_RADIUS:int = 6;
		private function dot(color:uint, center:Point, isEnd:Boolean = false):Shape {
			var dotShape:Shape = new Shape;
			if (isEnd) {
				dotShape.graphics.lineStyle(2, 0x0000ff)
			}
			dotShape.graphics.beginFill(color, 1);
			dotShape.graphics.drawEllipse(center.x - DOT_X_RADIUS, center.y - DOT_Y_RADIUS, DOT_X_RADIUS * 2, DOT_Y_RADIUS * 2);
			return dotShape;
		}
		
		// entity's move settings are used to determine dot color
		// return minimum gait required for this path length
		public function extendPath(entity:ComplexEntity, pathFromCurrentEndToNewEnd:Vector.<Point>):int {
			clearDots();
			path = path.concat(pathFromCurrentEndToNewEnd);
			endIndexes.push(path.length - 1);
			dots.length = path.length;
			var endIndexIndex:int = 0;
			var gait:int = entity.gaitForDistance(path.length);
			var color:uint = colorForGait(gait);
			for (var i:int = 0; i < path.length; i++) {
				var isEnd:Boolean = (i == endIndexes[endIndexIndex]);
				dots[i] = dot(color, Floor.centerOf(path[i]), isEnd );
				room.decorationsLayer.addChild(dots[i]);
				if (isEnd) {
					++endIndexIndex;
				}
				if (!entity.isPlayerControlled && !losFromAnyPlayer(path[i])) {
					// This is a major kludge and makes me wince.  It works, but this whole movement dot thing
					// is getting messier and uglier.
					dots[i].visible = false;
				}
			}
			return gait;
		}
		
		// Called by event listener each time an entity begins moving to a new tile during combat.
		// (entity's location will have already changed to the new tile)
		// The tile they're moving to should always be the one with the first dot on the path,
		// if everything is working right.
		private function entityMovingToNewTile(event:EntityEvent):void {
			Assert.assertTrue(dots.length > 0, "Entity.MOVED with no dots remaining");
			Assert.assertTrue(event.entity == currentFighter(), "Wrong entity moving");
			var dotToRemove:Shape = dots.shift();
			room.decorationsLayer.removeChild(dotToRemove);
			
			var entity:ComplexEntity = (event.entity as ComplexEntity);
			if (entity.isPlayerControlled) {
				adjustAllEnemyVisibility();
			} else {
				adjustVisibilityOfEnemy(entity);
			}
		}
		
		private function entityStandingOnNewTile(event:EntityEvent):void {
			checkForOpportunityFire(event.entity as ComplexEntity);
		}
		
		public static function colorForGait(gait:int):uint {
			switch (gait) {
				case ComplexEntity.GAIT_WALK:
					return WALK_COLOR;
				break;
				case ComplexEntity.GAIT_RUN:
					return RUN_COLOR;
				break;
				case ComplexEntity.GAIT_SPRINT:
					return SPRINT_COLOR;
				break;
			}
			return OUT_OF_RANGE_COLOR;
		}
		
		public function fireAndAdvanceToNextPhase(shooter:ComplexEntity, target:ComplexEntity):void {
			fire(shooter, target);
			if (shooter.isPlayerControlled || Settings.showEnemyMoves) {
				shooter.centerRoomOnMe();
			}
			
			// Give the player some time to gaze at the fire graphic before continuing with turn.
			room.pause(PAUSE_TO_VIEW_FIRE_TIME, finishedFire);
		}
		
		public function fire(shooter:ComplexEntity, target:ComplexEntity):void {
			if (target == null) {
				trace(shooter.aaId, "reserve fire");
				if (shooter.isPlayerControlled || losFromAnyPlayer(shooter.location)) {
					displayReserveFireGraphic(shooter);
				}
			} else {
				trace(shooter.aaId, "firing at", target.aaId, target.location);
				
				shooter.turnToFaceTile(target.location);
				
				--shooter.actionsRemaining;
				damage(target, shooter.weaponDamage() - target.defense());
				
				var uglyFireLineThatViolates3D:TimedSprite = new TimedSprite(room.stage.frameRate);
				uglyFireLineThatViolates3D.graphics.lineStyle(2, (shooter.isPlayerControlled ? 0xff0000 : 0xffa500));
				uglyFireLineThatViolates3D.graphics.moveTo(shooter.center().x, shooter.center().y);
				uglyFireLineThatViolates3D.graphics.lineTo(target.center().x, target.center().y);
				room.addChild(uglyFireLineThatViolates3D);
				
				if (!shooter.isPlayerControlled) {
					target.centerRoomOnMe();
				}
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
		
		
		private function damage(entity:ComplexEntity, points:int):void {
			entity.currentHealth -= points;
			entity.setTextOverHead(String(entity.currentHealth));

			trace(entity.aaId, "damaged, health now", entity.currentHealth);
			
			//Current stat display is an ugly grab-bag of misc. bits with no coherence
			if (entity.isPlayerControlled && (entity == currentFighter())) {
				statDisplay.adjustCombatStatDisplay(entity);
			}
			
			if (entity.currentHealth <= 0) {
				entity.solidness ^= Prop.TALL; // Dead entities are short, by fiat.
				entity.startDeathAnimation();
				if (entity == room.mainPlayerCharacter) {
					combatOver = true;
					Alert.show("You have been taken out.", { callback:combatOverOk } );
				} else {
					removeFighterFromCombat(entity);
					if (allEnemiesAreDead()) {
						combatOver = true;
						Alert.show("You won.", { callback:combatOverOk } );
					}
					if (entity.isPlayerControlled) {
						adjustAllEnemyVisibility();
					}
				}
			}
		}
		
		public function checkForOpportunityFire(entityMoving:ComplexEntity):void {
			Assert.assertTrue(currentFighter() == entityMoving, "Wrong entity moving");
			var someoneDidOpportunityFire:Boolean = false;
			
			//NOTE: This assumes only two factions. If we add civilians and want the enemy NPCs
			//to be able to shoot them (or the PCs to avoid shooting them) it will need revision.
			for (var i:int = 0; i < fighters.length; ++i) {
				if (fighters[i].isPlayerControlled != entityMoving.isPlayerControlled) {
					// WARNING: using ||= prevents it from executing the function if it's already true!
					someoneDidOpportunityFire = (opportunityFire(fighters[i], entityMoving) || someoneDidOpportunityFire);
					if (entityMoving.currentHealth <= 0) {
						// If the target is dead, it will have been removed from fighters
						// and this loop is no longer valid!
						break;
					}
				}
			}
			
			if (someoneDidOpportunityFire) {
				room.pause(PAUSE_TO_VIEW_FIRE_TIME, null);
			}
				
		}
		
		// return true if shooter fired, false if not
		private function opportunityFire(shooter:ComplexEntity, target:ComplexEntity):Boolean {
			trace("Checking", shooter.aaId, "for opportunity fire");
			if (shooter.actionsRemaining > 0) {
				if (isGoodTarget(shooter, target) && lineOfSight(shooter, target.location)) {
					fire(shooter, target);
					return true;
				}
			}
			return false;
		}
		
		private function isGoodTarget(shooter:ComplexEntity, target:ComplexEntity):Boolean {
			/*
			var distance:int = Util.chessDistance(shooter.location, target.location);
			var minDistance:int;
			switch (target.mostRecentGait) {
				case Entity.GAIT_SPRINT:
					minDistance = 6;
				break;
				case Entity.GAIT_RUN:
					minDistance = 8;
				break;
				default:
					minDistance = 10;
				break;
			}
			return (distance <= minDistance);
			*/
			var expectedDamage:int = shooter.weaponDamage() - target.defense();
			return (expectedDamage >= Settings.minForOpportunity);
		}
		
		/*********** Line of sight / fog of war, I don't know where I want to put this stuff *************/
		
		public function losFromAnyPlayer(target:Point):Boolean {
			for (var i:int = 0; i < fighters.length; i++) {
				if (fighters[i].isPlayerControlled && lineOfSight(fighters[i], target)) {
					return true;
				}
			}
			return false;
		}

//Outdented lines are for debugging, delete them eventually
private var debugLOS:Boolean = false;
private var lastTarget:Point = new Point(-1,-1);
		public function lineOfSight(entity:ComplexEntity, target:Point):Boolean {
			var x0:int = entity.location.x;
			var y0:int = entity.location.y;
			var x1:int = target.x;
			var y1:int = target.y;
			var dx:int = Math.abs(x1 - x0);
			var dy:int = Math.abs(y1 - y0);
			
var traceIt:Boolean = debugLOS && !target.equals(lastTarget);
var path:Array = new Array();
lastTarget = target;
			// Ray-tracing on grid code, from http://playtechs.blogspot.com/2007/03/raytracing-on-grid.html
			var x:int = x0;
			var y:int = y0;
			var n:int = 1 + dx + dy;
			var x_inc:int = (x1 > x0) ? 1 : -1;
			var y_inc:int = (y1 > y0) ? 1 : -1;
			var error:int = dx - dy;
			dx *= 2;
			dy *= 2;
			
			// original code looped for (; n>0; --n) -- I changed it so the shooter & target don't block themselves
			for (; n > 2; --n) {
path.push(new Point(x, y));

				if (error > 0) {
					x += x_inc;
					error -= dy;
				}
				else if (error < 0) {
					y += y_inc;
					error += dx;
				} else { // special case when passing directly through vertex -- do a diagonal move, hitting one less tile
					//CONSIDER: we may want to call this blocked if the tiles we're going between have "hard corners"
					x += x_inc;
					y += y_inc;
					error = error - dy + dx;
					--n;
					if (n <= 2) {
						break;
					}
				}
				// moved this check to end of loop so we're not checking the shooter's own tile
				if (tileBlocksSight(x, y)) {
if (traceIt) { trace("Blocked; path", path);}
					return false;
				}
			}
if (traceIt) { path.push(new Point(x, y));  trace("LOS clear; path", path); }
			return true;
		} // end function lineOfSight
		
		public function tileBlocksSight(x:int, y:int):Boolean {
			return (room.solid(x,y) & Prop.TALL) != 0;
		}
		
		private function adjustAllEnemyVisibility():void {
			for (var i:int = 0; i < fighters.length; i++) {
				var target:ComplexEntity = fighters[i];
				if (!target.isPlayerControlled) {
					adjustVisibilityOfEnemy(target);
				}
			}
		}
		
		private function adjustVisibilityOfEnemy(enemy:ComplexEntity):void {
			enemy.visible = enemy.marker.visible = losFromAnyPlayer(enemy.location);
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
			if (combatOver) {
				// don't allow next enemy to fire, don't enable player UI, just wait for them to OK the message,
				// which will end combat mode.
				return;
			}
			
			//event.entity won't match currentFighter() if moving entity was killed by opportunity fire
			if (event.entity != currentFighter()) {
				trace("fighter", iFighterTurnInProgress, "was killed, don't give them a fire phase");
				finishedFire();
				return;
			}
			trace("fighter", iFighterTurnInProgress, "(", currentFighter().aaId, ") finished moving");
			currentFighter().actionsRemaining = 1; // everyone gets one action per turn, at least for now
			if (currentFighter().isPlayerControlled) {
				room.enableUi(fireUi, currentFighter());
				modeLabel.text = PLAYER_FIRE;
			} else {
				currentFighter().brain.doFire();
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
			currentFighter().brain.doMove();
		}
		
		private function beginTurnForCurrentFighter():void {
			var fighter:ComplexEntity = currentFighter();
			if (fighter.isPlayerControlled) {
				if (enemyTurnOverlay.parent != null) {
					enemyTurnOverlay.parent.removeChild(enemyTurnOverlay);
				}
				statDisplay.adjustCombatStatDisplay(fighter);
				room.enableUi(moveUi, fighter);
				modeLabel.text = PLAYER_MOVE;
			} else {
				room.stage.addChild(enemyTurnOverlay);
				statDisplay.adjustCombatStatDisplay(null);
				modeLabel.text = ENEMY_MOVE;
				
				// Give the player some time to gaze at the enemy's move dots before continuing with turn.
				// (The timer will be running while enemy calculates move, so if that takes a while once we
				// start complicating the AI, then there may be a delay before the move dots are drawn, but
				// the total time between enemy's turn starting and enemy beginning to follow dots should
				// stay at that time unless we're really slow.)
				room.pause(PAUSE_TO_VIEW_MOVE_TIME, doPlottedEnemyMove);
				
				fighter.brain.chooseMoveAndDrawDots();
			}
		}
		
		private function currentFighter():ComplexEntity {
			return fighters[iFighterTurnInProgress];
		}
		
		private function goToNextFighter():void {
			++iFighterTurnInProgress;
			if (iFighterTurnInProgress >= fighters.length) {
				trace("All turns have been processed, go back to first player");
				iFighterTurnInProgress = 0;
			}
		}
		
		private function removeFighterFromCombat(deadFighter:ComplexEntity):void {
			var indexOfDeadFighter:int = fighters.indexOf(deadFighter);
			Assert.assertTrue(indexOfDeadFighter >= 0, "Removing fighter that's already removed: " + deadFighter.aaId);
			if (indexOfDeadFighter == iFighterTurnInProgress) {
				clearDots();
			}
			if (indexOfDeadFighter <= iFighterTurnInProgress) {
				--iFighterTurnInProgress;
			}
			fighters.splice(indexOfDeadFighter, 1);
			cleanupEntityFromCombat(deadFighter);
		}
		
		private function allEnemiesAreDead():Boolean {
			for (var i:int = 0; i < fighters.length; i++) {
				if (!fighters[i].isPlayerControlled) {
					return false;
				}
			}
			return true;
		}
		
	} // end class RoomCombat

}