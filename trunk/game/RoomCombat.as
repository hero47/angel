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
		private var fighters:Vector.<Entity>;
		
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
		private static const GRID_COLOR:uint = 0xff0000;
		
		private static const PAUSE_TO_VIEW_MOVE_TIME:int = 1000;
		private static const PAUSE_TO_VIEW_FIRE_TIME:int = 1000;
		
		private var playerHealthDisplay:TextField;
		private static const PLAYER_HEALTH_PREFIX:String = "Health: ";		
		private var enemyHealthDisplay:TextField;
		private static const ENEMY_HEALTH_PREFIX:String = "Enemy: ";


		// Trying to cleanup/organize this class, with possible refactoring on the horizon
		
		public function RoomCombat(room:Room) {
			trace("***BEGINNING COMBAT***");
			this.room = room;
			drawCombatGrid(room.decorationsLayer.graphics);
			
			fighters = new Vector.<Entity>();
			room.forEachEntity(initEntityForCombat); // init health; add enemies to fighter list & init their combat brains
			Util.shuffle(fighters); // enemy turn order is randomized at start of combat and stays the same thereafter
			room.playerCharacter.initHealth();
			fighters.splice(0, 0, room.playerCharacter); // player always goes first
			iFighterTurnInProgress = 0;
			
			// These listeners can only trigger in specific phases, and finishedMoving advances the phase.
			// I'm keeping them around throughout combat rather than adding and removing them as we flip
			// between phases because it seemed a little cleaner that way, but I'm not certain.
			room.addEventListener(EntityEvent.MOVED, entityMovingToNewTile);
			room.addEventListener(EntityEvent.FINISHED_ONE_TILE_OF_MOVE, entityStandingOnNewTile);
			room.addEventListener(EntityEvent.FINISHED_MOVING, finishedMovingListener);
			
			playerHealthDisplay = createHealthTextField();
			playerHealthDisplay.x = 10;
			playerHealthDisplay.y = 10;
			adjustPlayerHealthDisplay(room.playerCharacter.health);
			room.stage.addChild(playerHealthDisplay);
			
			enemyHealthDisplay = createHealthTextField();
			enemyHealthDisplay.x = room.stage.stageWidth - enemyHealthDisplay.width - 10;
			enemyHealthDisplay.y = 10;
			adjustEnemyHealthDisplay(-1);
			room.stage.addChild(enemyHealthDisplay);
			
			moveUi = new CombatMoveUi(room, this);
			fireUi = new CombatFireUi(room, this);
			room.enableUi(moveUi);
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
			room.stage.removeChild(playerHealthDisplay);
			
			for (var i:int = 1; i < fighters.length; i++) { // player is fighters[0]
				cleanupEntityFromCombat(fighters[i]);
			}
		}
		
		private function initEntityForCombat(entity:Entity):void {
			entity.initHealth();
			if (entity.isEnemy()) {
				fighters.push(entity);
				entity.brain = new entity.combatBrainClass(entity, this);
				
				var enemyMarker:Shape = new Shape();
				enemyMarker.graphics.lineStyle(4, ENEMY_MARKER_COLOR, 0.7);
				enemyMarker.graphics.drawCircle(0, 0, 15);
				enemyMarker.graphics.drawCircle(0, 0, 30);
				enemyMarker.graphics.drawCircle(0, 0, 45);
				// TAG tile-width-is-twice-height: aspect will be off if tiles no longer follow this rule!
				enemyMarker.scaleY = 0.5;
				room.decorationsLayer.addChild(enemyMarker);
				
				entity.enemyMarker = enemyMarker;
				room.moveEnemyMarkerIfNeeded(entity);
			}
		}
		
		private function cleanupEntityFromCombat(entity:Entity):void {
			entity.brain = null;
			room.decorationsLayer.removeChild(entity.enemyMarker);
			entity.enemyMarker = null;
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
		
		private function createHealthTextField():TextField {
			var myTextField:TextField = Util.textBox("", 100, 20, TextFormatAlign.CENTER, false);
			myTextField.border = true;
			myTextField.background = true;
			myTextField.backgroundColor = 0xffffff;
			return myTextField;
		}
		
		private function adjustPlayerHealthDisplay(points:int):void {
			playerHealthDisplay.text = PLAYER_HEALTH_PREFIX + String(points);
		}
		
		public function adjustEnemyHealthDisplay(points:int):void {
			if (points < 0) {
				enemyHealthDisplay.visible = false;
			} else {
				enemyHealthDisplay.text = ENEMY_HEALTH_PREFIX + String(points);
				enemyHealthDisplay.visible = true;
			}	
		}
		
		private function playerDeathOk(button:String):void {
			room.changeModeTo(RoomExplore);
		}
		
		/****************** Used by both player & NPCs during combat turns *******************/
		
		public function startEntityFollowingPath(entity:Entity, gait:int):void {
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
		public function extendPath(entity:Entity, pathFromCurrentEndToNewEnd:Vector.<Point>):int {
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
			}
			return gait;
		}
		
		// Called by event listener each time an entity begins moving to a new tile during combat.
		// (entity's location will have already changed to the new tile)
		// The tile they're moving to should always be the one with the first dot on the path,
		// if everything is working right.
		private function entityMovingToNewTile(event:EntityEvent):void {
			Assert.assertTrue(dots.length > 0, "Entity.MOVED with no dots remaining");
			Assert.assertTrue(event.entity == fighters[iFighterTurnInProgress], "Wrong entity moving");
			var dotToRemove:Shape = dots.shift();
			room.decorationsLayer.removeChild(dotToRemove);
		}
		
		private function entityStandingOnNewTile(event:EntityEvent):void {
			checkForOpportunityFire(event.entity);
		}
		
		public static function colorForGait(gait:int):uint {
			switch (gait) {
				case Entity.GAIT_WALK:
					return WALK_COLOR;
				break;
				case Entity.GAIT_RUN:
					return RUN_COLOR;
				break;
				case Entity.GAIT_SPRINT:
					return SPRINT_COLOR;
				break;
			}
			return OUT_OF_RANGE_COLOR;
		}
		
		public function fireAndAdvanceToNextPhase(shooter:Entity, target:Entity):void {
			fire(shooter, target);
			if (shooter.isPlayerControlled || Settings.showEnemyMoves) {
				shooter.centerRoomOnMe();
			}
			
			// Give the player some time to gaze at the fire graphic before continuing with turn.
			// CONSIDER: For enemies, we may put up some sort of "enemy firing" overlay
			room.pause(PAUSE_TO_VIEW_FIRE_TIME, finishedFire);
		}
		
		public function fire(shooter:Entity, target:Entity):void {
			if (target == null) {
				trace(shooter.aaId, "reserve fire");
				var reserveFireBitmap:Bitmap = new Icon.ReserveFireFloater();
				var reserveFireSprite:TimedSprite = new TimedSprite(room.stage.frameRate);
				reserveFireSprite.addChild(reserveFireBitmap);
				reserveFireSprite.x = shooter.x;
				reserveFireSprite.y = shooter.y - reserveFireSprite.height;
				room.addChild(reserveFireSprite);
			} else {
				trace(shooter.aaId, "firing at", target.aaId, target.location);
				--shooter.actionsRemaining;
				damage(target, shooter.weaponDamage() - target.defense());
				
				var uglyFireLineThatViolates3D:TimedSprite = new TimedSprite(room.stage.frameRate);
				uglyFireLineThatViolates3D.graphics.lineStyle(2, (shooter.isPlayerControlled ? 0xff0000 : 0xffa500));
				uglyFireLineThatViolates3D.graphics.moveTo(shooter.center().x, shooter.center().y);
				uglyFireLineThatViolates3D.graphics.lineTo(target.center().x, target.center().y);
				room.addChild(uglyFireLineThatViolates3D);
			}
		}
		
		private function damage(entity:Entity, points:int):void {
			entity.health -= points;
			trace(entity.aaId, "damaged, health now", entity.health);
			if (entity.isPlayerControlled) {
				adjustPlayerHealthDisplay(entity.health);
			}
			
			if (entity.health <= 0) {
				entity.startDeathAnimation();
				if (entity.isPlayerControlled) {
					combatOver = true;
					Alert.show("You have been taken out.", { callback:playerDeathOk } );
				} else {
					cleanupEntityFromCombat(entity);
					var iFighter:int = fighters.indexOf(entity);
					Assert.assertTrue(iFighterTurnInProgress == 0 || iFighterTurnInProgress == iFighter,
							"Enemy died during a different enemy's turn");
					if (iFighter == iFighterTurnInProgress) {
						clearDots();
						--iFighterTurnInProgress;
					}
					fighters.splice(iFighter, 1);
				}
			}
		}

//private static var lastTarget:Point = new Point(-1,-1);
		public function lineOfSight(entity:Entity, target:Point):Boolean {
			var x0:int = entity.location.x;
			var y0:int = entity.location.y;
			var x1:int = target.x;
			var y1:int = target.y;
			var dx:int = Math.abs(x1 - x0);
			var dy:int = Math.abs(y1 - y0);
			
			
//var traceIt:Boolean = !target.equals(lastTarget);
//var path:Array = new Array();
//lastTarget = target;
			// Ray-tracing on grid code, from http://playtechs.blogspot.com/2007/03/raytracing-on-grid.html
			var x:int = x0;
			var y:int = y0;
			var n:int = 1 + dx + dy;
			var x_inc:int = (x1 > x0) ? 1 : -1;
			var y_inc:int = (y1 > y0) ? 1 : -1;
			var error:int = dx - dy;
			dx *= 2;
			dy *= 2;
			
			// original code went to n>0; I changed that so the target we're trying to shoot doesn't block itself
			for (; n > 1; --n) {
//path.push(new Point(x, y));
				if (tileBlocksSight(x, y)) {
//if (traceIt) { trace("Blocked; path", path);}
					return false;
				}

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
				}
			}
//if (traceIt) { path.push(new Point(x, y));  trace("LOS clear; path", path); }
			return true;
		} // end function lineOfSight
		
		public function tileBlocksSight(x:int, y:int):Boolean {
			return (room.solid(x,y) & Prop.TALL) != 0;
		}
		
		public function checkForOpportunityFire(entityMoving:Entity):void {
			Assert.assertTrue(fighters[iFighterTurnInProgress] == entityMoving, "Wrong entity moving");
			var someoneDidOpportunityFire:Boolean = false;
			
			if (entityMoving.isPlayerControlled) { // player just moved to a new tile, enemies might shoot
				for (var i:int = 1; i < fighters.length; ++i) {
					someoneDidOpportunityFire ||= opportunityFire(fighters[i], room.playerCharacter);
				}
			} else { // an enemy just moved to a new tile, player might shoot
				someoneDidOpportunityFire = opportunityFire(room.playerCharacter, fighters[iFighterTurnInProgress]);
			}
			
			if (someoneDidOpportunityFire) {
				room.pause(PAUSE_TO_VIEW_FIRE_TIME, finishedOpportunityFirePause);
			}
				
		}
		
		// return true if shooter fired, false if not
		private function opportunityFire(shooter:Entity, target:Entity):Boolean {
			trace("Checking", shooter.aaId, "for opportunity fire");
			if (shooter.actionsRemaining > 0) {
				if (isGoodTarget(shooter, target) && lineOfSight(shooter, target.location)) {
					fire(shooter, target);
					return true;
				}
			}
			return false;
		}
		
		private function isGoodTarget(shooter:Entity, target:Entity):Boolean {
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
			//event.entity won't match fighters[iFighterTurnInProgress] if moving entity was killed by opportunity fire
			if (event.entity != fighters[iFighterTurnInProgress]) {
				trace("fighter", iFighterTurnInProgress, "was killed, don't give them a fire phase");
				finishedFire();
				return;
			}
			trace("fighter", iFighterTurnInProgress, "(", fighters[iFighterTurnInProgress].aaId, ") finished moving");
			fighters[iFighterTurnInProgress].actionsRemaining = 1; // everyone gets one action per turn, at least for now
			if (iFighterTurnInProgress == 0) {
				room.enableUi(fireUi);
			} else {
				fighters[iFighterTurnInProgress].brain.doFire();
			}
		}
		
		// Called each time the timer for gazing at the fire graphic expires, or when an entity was killed by
		// opportunity fire while moving and thus needs to skip their fire phase.
		private function finishedFire():void {
			trace("fighter", iFighterTurnInProgress, "(", fighters[iFighterTurnInProgress].aaId, ") finished fire");
			
			if (combatOver) {
				// don't allow next enemy to move, don't enable player UI, just wait for them to OK the message,
				// which will end combat mode.
				return;
			}
			
			++iFighterTurnInProgress;
			if (iFighterTurnInProgress >= fighters.length) {
				trace("All enemy turns have been processed, go back to player move");
				iFighterTurnInProgress = 0;
				room.playerCharacter.centerRoomOnMe();
				room.enableUi(moveUi);
				return;
			}
			
			if (Settings.showEnemyMoves) {
				fighters[iFighterTurnInProgress].centerRoomOnMe();
			} else {
				room.playerCharacter.centerRoomOnMe();
			}
			
			// Give the player some time to gaze at the enemy's move dots before continuing with turn.
			// (The timer will be running while enemy calculates move, so if that takes a while once we
			// start complicating the AI, then there may be a delay before the move dots are drawn, but
			// the total time between enemy's turn starting and enemy beginning to follow dots should
			// stay at that time unless we're really slow.)
			// CONSIDER: We may put up some sort of "enemy moving" overlay
			room.pause(PAUSE_TO_VIEW_MOVE_TIME, finishedEnemyMove);
			
			fighters[iFighterTurnInProgress].brain.chooseMoveAndDrawDots();
		}
		
		// Called each time the timer for gazing at the enemy's move dots expires
		private function finishedEnemyMove():void {
			trace("enemyMoveTimerListener for fighter #", iFighterTurnInProgress, fighters[iFighterTurnInProgress].aaId);
			fighters[iFighterTurnInProgress].brain.doMove();
		}
		
		// Called each time the timer for gazing at opportunity fire
		private function finishedOpportunityFirePause():void {
			//Usually this doesn't need to do anything, the entity that was moving will automatically continue
			//moving once the room unpauses.
			//Maybe now it never needs to do anything, let's see if this works
		}
		
	} // end class RoomCombat

}