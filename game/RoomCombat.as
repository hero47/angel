package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.FloorTile;
	import angel.common.Util;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
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
		
		private var room:Room;
		private var playerMoveInProgress:Boolean = false;
		private var iFighterTurnInProgress:int;
		private var dragging:Boolean = false;
		private var ui:IUi;
		private var moveUi:CombatMoveUi;
		private var fireUi:CombatFireUi;
		
		// The entities who get combat turns. Everything else is just decoration/obstacles.
		private var fighters:Vector.<Entity>;
		
		private var pauseBetweenMoves:Timer;
		
		// public because they're accessed by the CombatMoveUi and/or entity combat brains
		public var dots:Vector.<Shape> = new Vector.<Shape>();
		public var endIndexes:Vector.<int> = new Vector.<int>();
		public var path:Vector.<Point> = new Vector.<Point>();
		
		// Colors for movement dots/hilights
		private static const walkColor:uint = 0x00ff00;
		private static const runColor:uint = 0xffd800;
		private static const sprintColor:uint = 0xff0000;
		private static const outOfRangeColor:uint = 0x888888;

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
			pauseBetweenMoves = new Timer(2000, 1);
			pauseBetweenMoves.addEventListener(TimerEvent.TIMER_COMPLETE, enemyMoveTimerListener);
			
			moveUi = new CombatMoveUi(this, room);
			fireUi = new CombatFireUi(this, room);
			enableUi(moveUi);
		}

		public function cleanup():void {
			ui.disable();
			room.removeEventListener(Entity.MOVED, removeFirstDotOnPath);
			room.removeEventListener(Entity.FINISHED_MOVING, finishedMovingListener);
			pauseBetweenMoves.removeEventListener(TimerEvent.TIMER_COMPLETE, enemyMoveTimerListener);
			
			room.decorationsLayer.graphics.clear(); // remove grid outlines
			clearDots();
			for each (var entity:Entity in fighters) {
				cleanupEntityFromCombat(entity);
			}
		}
		
		private function initEntityForCombat(entity:Entity):void {
			if (entity.combatBrainClass != null) {
				fighters.push(entity);
				entity.brain = new entity.combatBrainClass(entity, this);
				
				var enemyMarker:Shape = new Shape();
				enemyMarker.graphics.lineStyle(4, 0xff0000);
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
			graphics.lineStyle(0, 0xff0000, 1);
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
		
		/********** Player UI-related -- Refactoring with IUi ****************/

		
		// call this when player-controlled part of the turn begins, to allow player to enter move
		private function enableUi(newUi:IUi):void {
			ui = newUi;
			room.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
			room.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveListener);
			room.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			room.addEventListener(MouseEvent.CLICK, mouseClickListener);
			//Right-button mouse events are only supported in AIR.  For now, while we're using Flash Projector,
			//we're substituting ctrl-click.
			//room.addEventListener(MouseEvent.RIGHT_CLICK, rightClickListener);
			
			newUi.enable();
		}
		
		public function disableUi():void {
			room.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
			room.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveListener);
			room.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			room.removeEventListener(MouseEvent.CLICK, mouseClickListener);
			//room.removeEventListener(MouseEvent.RIGHT_CLICK, rightClickListener);
			
			room.removeEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			room.stopDrag();
			
			ui.disable();
		}
		
		// For God-only-knows what reason, the version of Keyboard class for Flex compilation is missing all
		// of the letter-key constants.  The version in CS5 has them.  ?????
		public static const KEYBOARD_C:uint = 67;
		public static const KEYBOARD_V:uint = 86;
		private function keyDownListener(event:KeyboardEvent):void {
			switch (event.keyCode) {
				case KEYBOARD_C:
					room.changeModeTo(RoomExplore);
				break;
				
				case KEYBOARD_V:
					room.toggleVisibility();
				break;
				
				default:
					ui.keyDown(event.keyCode);
				break;
			}
		}
		
		private function mouseMoveListener(event:MouseEvent):void {
			ui.mouseMove(event.localX, event.localY, event.target as FloorTile);
		}

		private function mouseDownListener(event:MouseEvent):void {
			if (event.shiftKey) {
				room.addEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
				room.startDrag();
				dragging = true;
			} else {
				dragging = false;
			}
		}

		private function mouseUpListener(event:MouseEvent):void {
			room.removeEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			room.stopDrag();
		}
		
		private function mouseClickListener(event:MouseEvent):void {
			if (event.ctrlKey) {
				// Temporary since Flash Projector doesn't support right-button events.
				// If/when we switch to AIR this will be replaced with a real right click listener.
				rightClickListener(event);
				return;
			}
			if (!dragging && (event.target is FloorTile)) {
				ui.mouseClick(event.target as FloorTile);
			}
		}
		
		private function rightClickListener(event:MouseEvent):void {
			if (!(event.target is FloorTile)) {
				return;
			}
			var tile:FloorTile = event.target as FloorTile;
			var slices:Vector.<PieSlice> = ui.pieMenuForTile(tile);
			
			if (slices != null && slices.length > 0) {
				var tileCenterOnStage:Point = room.floor.localToGlobal(Floor.centerOf(tile.location));
				room.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
				var pie:PieMenu = new PieMenu(tileCenterOnStage.x, tileCenterOnStage.y, slices, pieDismissed);
				room.stage.addChild(pie);
			}
		}
		
		private function pieDismissed():void {
			room.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
		}
		
		/****************** Used by both player & NPCs during combat turns -- move segment *******************/
		
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
					return walkColor;
				break;
				case Entity.GAIT_RUN:
					return runColor;
				break;
				case Entity.GAIT_SPRINT:
					return sprintColor;
				break;
			}
			return outOfRangeColor;
		}

		/*********** Turn-structure related **************/

		// Called each time an entity (player or NPC) finishes its combat move
		// (specifically, during ENTER_FRAME for last frame of movement)
		private function finishedMovingListener(event:Event = null):void {
			trace("fighter", iFighterTurnInProgress, "(", fighters[iFighterTurnInProgress].aaId, ") finished moving");
			if (iFighterTurnInProgress == 0) {
				enableUi(fireUi);
			} else {
				//UNDONE: enemy fire
				finishedFire();
			}
		}
		
		// This will change to a listener if we want to hang around for a moment allowing player to see results
		// of each shot before going to the next entity's move phase; Wm hasn't said that yet but it seems likely.
		public function finishedFire():void {
			trace("fighter", iFighterTurnInProgress, "(", fighters[iFighterTurnInProgress].aaId, ") finished fire");
			++iFighterTurnInProgress;
			if (iFighterTurnInProgress >= fighters.length) {
				trace("All enemy turns have been processed, go back to player");
				iFighterTurnInProgress = 0;
				if (Settings.showEnemyMoves) {
					room.playerCharacter.centerRoomOnMe();
				}
				
				enableUi(moveUi);
				return;
			}
			
			if (Settings.showEnemyMoves) {
				fighters[iFighterTurnInProgress].centerRoomOnMe();
			}
			
			// Give the player 2 seconds to gaze at the enemy's move dots before continuing with turn.
			// (The timer will be running while enemy calculates move, so if that takes a while once we
			// start complicating the AI, then there may be a delay before the move dots are drawn, but
			// the total time between enemy's turn starting and enemy beginning to follow dots should
			// stay at 2 seconds.)
			// CONSIDER: We may put up some sort of "enemy processing turn" overlay
			pauseBetweenMoves.reset();
			pauseBetweenMoves.start();
			
			fighters[iFighterTurnInProgress].brain.chooseMoveAndDrawDots();
		}
		
		// Called each time the timer for gazing at the enemy's move dots expires
		private function enemyMoveTimerListener(event:TimerEvent):void {
			trace("enemyMoveTimerListener for fighter #", iFighterTurnInProgress);
			fighters[iFighterTurnInProgress].brain.doMove();
		}
		
	} // end class RoomCombat

}