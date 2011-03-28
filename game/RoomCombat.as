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
		private var dragging:Boolean = false;
		private var moveUi:CombatMoveUi;
		private var fireUi:CombatFireUi;
		
		// The entities who get combat turns. Everything else is just decoration/obstacles.
		private var fighters:Vector.<Entity>;
		
		private var pauseToViewMove:Timer;
		private var pauseToViewFire:Timer;
		
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


		// Trying to cleanup/organize this class, with possible refactoring on the horizon
		
		public function RoomCombat(room:Room) {
			this.room = room;
			drawCombatGrid(room.decorationsLayer.graphics);
			
			fighters = new Vector.<Entity>();
			room.forEachEntity(initEntityForCombat); // Add enemies to fighter list & init their combat brains
			Util.shuffle(fighters); // enemy turn order is randomized at start of combat and stays the same thereafter
			fighters.splice(0, 0, room.playerCharacter); // player always goes first
			iFighterTurnInProgress = 0;
			
			// These listeners can only trigger in specific phases, and most of them advance the phase.
			// I'm keeping them around throughout combat rather than adding and removing them as we flip
			// between phases because it seemed a little cleaner that way, but I'm not certain.
			room.addEventListener(Entity.MOVED, removeFirstDotOnPath);
			room.addEventListener(Entity.FINISHED_MOVING, finishedMovingListener);
			pauseToViewMove = new Timer(PAUSE_TO_VIEW_MOVE_TIME, 1);
			pauseToViewMove.addEventListener(TimerEvent.TIMER_COMPLETE, enemyMoveTimerListener);
			pauseToViewFire = new Timer(PAUSE_TO_VIEW_FIRE_TIME, 1);
			pauseToViewFire.addEventListener(TimerEvent.TIMER_COMPLETE, fireTimerListener);
			
			playerHealthDisplay = createPlayerHealthTextField();
			playerHealthDisplay.x = 10;
			playerHealthDisplay.y = 10;
			adjustPlayerHealthDisplay(room.playerCharacter.health);
			room.stage.addChild(playerHealthDisplay);
			
			moveUi = new CombatMoveUi(room, this);
			fireUi = new CombatFireUi(room, this);
			room.enableUi(moveUi);
		}

		public function cleanup():void {
			room.disableUi();
			room.removeEventListener(Entity.MOVED, removeFirstDotOnPath);
			room.removeEventListener(Entity.FINISHED_MOVING, finishedMovingListener);
			pauseToViewMove.removeEventListener(TimerEvent.TIMER_COMPLETE, enemyMoveTimerListener);
			
			room.decorationsLayer.graphics.clear(); // remove grid outlines
			clearDots();
			room.stage.removeChild(playerHealthDisplay);
			
			for (var i:int = 1; i < fighters.length; i++) { // player is fighters[0]
				cleanupEntityFromCombat(fighters[i]);
			}
		}
		
		private function initEntityForCombat(entity:Entity):void {
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
		
		private function createPlayerHealthTextField():TextField {
			var myTextField:TextField = Util.textBox("", 80, 20, TextFormatAlign.CENTER, false);
			myTextField.border = true;
			myTextField.background = true;
			myTextField.backgroundColor = 0xffffff;
			return myTextField;
		}
		
		private function adjustPlayerHealthDisplay(points:int):void {
			playerHealthDisplay.text = PLAYER_HEALTH_PREFIX + String(points);
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
		
		// Called by event listener each time an entity moves to a new tile during combat
		// The tile they're moving to should always be the one with the first dot on the path,
		// if everything is working right.
		// CONSIDER: If we create specialized EntityEvent and pass entity as part of event data,
		// then this could assert that entity.location equals dot location
		private function removeFirstDotOnPath(event:Event):void {
			Assert.assertTrue(dots.length > 0, "Entity.MOVED with no dots remaining");
			var dotToRemove:Shape = dots.shift();
			room.decorationsLayer.removeChild(dotToRemove);
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
		
		public function fire(shooter:Entity, target:Entity):void {
			if (target == null) {
				var reserveFireBitmap:Bitmap = new Icon.ReserveFireFloater();
				var reserveFireSprite:TimedSprite = new TimedSprite(room.stage.frameRate);
				reserveFireSprite.addChild(reserveFireBitmap);
				reserveFireSprite.x = shooter.x;
				reserveFireSprite.y = shooter.y - reserveFireSprite.height;
				room.addChild(reserveFireSprite);
				//UNDONE: Set whatever keeps track of reserved fire
				if (shooter.isPlayerControlled || Settings.showEnemyMoves) {
					shooter.centerRoomOnMe();
				}
			} else {
				damage(target);
				
				var uglyFireLineThatViolates3D:TimedSprite = new TimedSprite(room.stage.frameRate);
				uglyFireLineThatViolates3D.graphics.lineStyle(2, 0xff0000);
				uglyFireLineThatViolates3D.graphics.moveTo(shooter.center().x, shooter.center().y);
				uglyFireLineThatViolates3D.graphics.lineTo(target.center().x, target.center().y);
				room.addChild(uglyFireLineThatViolates3D);
				if (shooter.isPlayerControlled || Settings.showEnemyMoves) {
					target.centerRoomOnMe();
				}
			}
			
			
			// Give the player some time to gaze at the fire graphic before continuing with turn.
			// CONSIDER: For enemies, we may put up some sort of "enemy firing" overlay
			pauseToViewFire.reset();
			pauseToViewFire.start();
		}
		
		// To start, every hit deals 1 damage.  Later we'll complicate things; I don't know whether the
		// calculations will end up here or elsewhere.
		private function damage(entity:Entity):void {
			entity.health--;
			if (entity.isPlayerControlled) {
				adjustPlayerHealthDisplay(entity.health);
				if (entity.health <= 0) {
					Alert.show("You have been taken out.", { callback:playerDeathOk } );
				}
			}
		}

		public function lineOfSight(entity:Entity, target:Point):Boolean {
			var x0:int = entity.location.x;
			var y0:int = entity.location.y;
			var x1:int = target.x;
			var y1:int = target.y;
			var dx:int = Math.abs(x1 - x0);
			var dy:int = Math.abs(y1 - y0);
			
			// Ray-tracing on grid code, from http://playtechs.blogspot.com/2007/03/raytracing-on-grid.html
			// NOTE: "Finally: The code [] does not always return the same set of squares if you swap the endpoints.
			// When error is zero, the line is passing through a vertical grid line and a horizontal grid line
			// simultaneously. In this case, the code currently will always move vertically (the else clause), then
			// horizontally. If this is undesirable, you could make the if statement break ties differently when moving
			// up vs. down; or you could have a third clause for error == 0 which considers both moves
			// (horizontal-then-vertical and vertical-then-horizontal).
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
				if (tileBlocksSight(x, y)) {
					return false;
				}

				if (error > 0)
				{
					x += x_inc;
					error -= dy;
				}
				else
				{
					y += y_inc;
					error += dx;
				}
			}
			return true;
		} // end function lineOfSight
		
		public function tileBlocksSight(x:int, y:int):Boolean {
			return (room.solid(x,y) & Prop.TALL) != 0;
		}
		
		/*********** Turn-structure related **************/

		// Called each time an entity (player or NPC) finishes its combat move
		// (specifically, during ENTER_FRAME for last frame of movement)
		private function finishedMovingListener(event:Event = null):void {
			trace("fighter", iFighterTurnInProgress, "(", fighters[iFighterTurnInProgress].aaId, ") finished moving");
			if (iFighterTurnInProgress == 0) {
				room.enableUi(fireUi);
			} else {
				fighters[iFighterTurnInProgress].brain.doFire();
			}
		}
		
		// Called each time the timer for gazing at the fire graphic expires
		private function fireTimerListener(event:TimerEvent):void {
			trace("fighter", iFighterTurnInProgress, "(", fighters[iFighterTurnInProgress].aaId, ") finished fire");
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
			}
			
			// Give the player some time to gaze at the enemy's move dots before continuing with turn.
			// (The timer will be running while enemy calculates move, so if that takes a while once we
			// start complicating the AI, then there may be a delay before the move dots are drawn, but
			// the total time between enemy's turn starting and enemy beginning to follow dots should
			// stay at that time unless we're really slow.)
			// CONSIDER: We may put up some sort of "enemy moving" overlay
			pauseToViewMove.reset();
			pauseToViewMove.start();
			
			fighters[iFighterTurnInProgress].brain.chooseMoveAndDrawDots();
		}
		
		// Called each time the timer for gazing at the enemy's move dots expires
		private function enemyMoveTimerListener(event:TimerEvent):void {
			trace("enemyMoveTimerListener for fighter #", iFighterTurnInProgress);
			fighters[iFighterTurnInProgress].brain.doMove();
		}
		
		
	} // end class RoomCombat

}