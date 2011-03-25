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
		private var path:Vector.<Point> = new Vector.<Point>();
		private var dots:Vector.<Shape> = new Vector.<Shape>();
		private var endIndexes:Vector.<int> = new Vector.<int>();
		private var movePointsDisplay:TextField;
		private var dragging:Boolean = false;
		
		private var pauseBetweenMoves:Timer = new Timer(2000, 1);;
		
		// The entities who get combat turns. Everything else is just decoration/obstacles.
		private var fighters:Vector.<Entity> = new Vector.<Entity>();
		
		private static const walkColor:uint = 0x00ff00;
		private static const runColor:uint = 0xffd800;
		private static const sprintColor:uint = 0xff0000;
		private static const outOfRangeColor:uint = 0x888888;

		// Trying to cleanup/organize this class, with possible refactoring on the horizon
		
		public function RoomCombat(room:Room) {
			this.room = room;
			drawCombatGrid(room.decorationsLayer.graphics);
			movePointsDisplay = createMovePointsTextField();
			movePointsDisplay.text = String(room.playerCharacter.combatMovePoints);
			movePointsDisplay.x = 10;
			movePointsDisplay.y = 10;
			room.parent.addChild(movePointsDisplay);
			
			room.addEventListener(Entity.MOVED, removeFirstDotOnPath);
			room.addEventListener(Entity.FINISHED_MOVING, finishedMovingListener);
			pauseBetweenMoves.addEventListener(TimerEvent.TIMER_COMPLETE, enemyMoveTimerListener);
			
			room.forEachEntity(initEntityForCombat); // Add enemies to fighter list & init their combat brains
			Util.shuffle(fighters); // enemy turn order is randomized at start of combat and stays the same thereafter
			fighters.splice(0, 0, room.playerCharacter); // player always goes first
			iFighterTurnInProgress = 0;
			
			enableCombatMoveUi();
		}

		public function cleanup():void {
			disableCombatMoveUi();
			room.removeEventListener(MouseEvent.MOUSE_DOWN, combatSharedMouseUpListener);
			room.removeEventListener(Entity.MOVED, removeFirstDotOnPath);
			room.removeEventListener(Entity.FINISHED_MOVING, finishedMovingListener);
			pauseBetweenMoves.removeEventListener(TimerEvent.TIMER_COMPLETE, enemyMoveTimerListener);
			room.decorationsLayer.graphics.clear(); // remove grid outlines
			clearDots();
			room.parent.removeChild(movePointsDisplay);
			for each (var entity:Entity in fighters) {
				cleanupEntityFromCombat(entity);
			}
		}
		
		private function initEntityForCombat(entity:Entity):void {
			if (entity.combatBrainClass != null) {
				fighters.push(entity);
				entity.brain = new entity.combatBrainClass(entity, this);
				entity.personalTileHilight = new GlowFilter(0xff0000, 1, 15, 15, 10, 1, true, false);
				room.updatePersonalTileHilight(entity);
			}
		}
		
		private function cleanupEntityFromCombat(entity:Entity):void {
			entity.brain = null;
			entity.personalTileHilight = null;
			room.updatePersonalTileHilight(entity);
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
		
		private function createMovePointsTextField():TextField {
			var myTextField:TextField = new TextField();
			myTextField.selectable = false;
			myTextField.width = 40;
			myTextField.height = 20;
			var myTextFormat:TextFormat = new TextFormat();
			myTextFormat.size = 16;
			myTextFormat.align = TextFormatAlign.CENTER;
			myTextField.defaultTextFormat = myTextFormat;
			myTextField.type = TextFieldType.DYNAMIC;
			myTextField.border = true;
			myTextField.background = true;
			myTextField.backgroundColor = 0xffffff;
			myTextField.textColor = 0x0;
			return myTextField;
		}
		
		/********** Player UI-related -- Shared by Move & Fire segments ****************/

		private function combatSharedMouseDownListener(event:MouseEvent):void {
			if (event.shiftKey) {
				room.addEventListener(MouseEvent.MOUSE_UP, combatSharedMouseUpListener);
				room.startDrag();
				dragging = true;
			} else {
				dragging = false;
			}
		}

		private function combatSharedMouseUpListener(event:MouseEvent):void {
			room.removeEventListener(MouseEvent.MOUSE_UP, combatSharedMouseUpListener);
			room.stopDrag();
		}
		
		/********** Player UI-related -- Move segment ****************/
		
		// call this when player-controlled part of the turn begins, to allow player to enter move
		private function enableCombatMoveUi():void {
			trace("entering player move phase");
			room.addEventListener(MouseEvent.MOUSE_DOWN, combatSharedMouseDownListener);
			room.addEventListener(MouseEvent.MOUSE_MOVE, combatMoveMouseMoveListener);
			room.addEventListener(MouseEvent.CLICK, combatMoveClickListener);
			//Right-button mouse events are only supported in AIR.  For now, while we're using Flash Projector,
			//we're substituting ctrl-click.
			//room.addEventListener(MouseEvent.RIGHT_CLICK, launchPieMenu);
			room.stage.addEventListener(KeyboardEvent.KEY_DOWN, combatMoveKeyDownListener);
			movePointsDisplay.visible = true;
			movePointsDisplay.text = String(room.playerCharacter.combatMovePoints);
		}
		
		// call this when computer-controlled part of the turn begins, to prevent player from mucking around
		private function disableCombatMoveUi():void {
			trace("ending player move phase");
			movePointsDisplay.visible = false;
			room.moveHilight(null, 0);
			room.removeEventListener(MouseEvent.CLICK, combatMoveClickListener);
			room.removeEventListener(MouseEvent.MOUSE_DOWN, combatSharedMouseDownListener);
			room.removeEventListener(MouseEvent.MOUSE_MOVE, combatMoveMouseMoveListener);
			room.stage.removeEventListener(KeyboardEvent.KEY_DOWN, combatMoveKeyDownListener);
		}
		
		// For God-only-knows what reason, the version of Keyboard class for Flex compilation is missing all
		// of the letter-key constants.  The version in CS5 has them.  ?????
		public static const KEYBOARD_C:uint = 67;
		public static const KEYBOARD_V:uint = 86;
		private function combatMoveKeyDownListener(event:KeyboardEvent):void {
			switch (event.keyCode) {
				case KEYBOARD_C:
					room.changeModeTo(RoomExplore);
				break;
				
				case KEYBOARD_V:
					room.toggleVisibility();
				break;
					
				case Keyboard.BACKSPACE:
					removeLastPathSegment();
				break;
				
				case Keyboard.ENTER:
					doPlayerMove();
				break;
			}
			
		}
		
		private function combatMoveMouseMoveListener(event:MouseEvent):void {
			if (event.target is FloorTile) {
				var tile:FloorTile = event.target as FloorTile;
				var distance:int = 1000;
				if (!room.playerCharacter.tileBlocked(tile.location) && (path.length < room.playerCharacter.combatMovePoints)) {
					var pathToMouse:Vector.<Point> = room.playerCharacter.findPathTo(tile.location, 
							(path.length == 0 ? null : path[path.length-1]) );
					if (pathToMouse != null) {
						distance = path.length + pathToMouse.length;
					}
				}
				room.moveHilight(tile, colorForGait(room.playerCharacter.gaitForDistance(distance)));
			}
		}
		
		private function combatMoveClickListener(event:MouseEvent):void {
			if (event.ctrlKey) {
				// Temporary since Flash Projector doesn't support right-button events.
				// If/when we switch to AIR this will be replaced with a real right click listener.
				launchCombatMovePieMenu(event);
				return;
			}
			if (!dragging && event.target is FloorTile) {
				var loc:Point = (event.target as FloorTile).location;
				if (!room.playerCharacter.tileBlocked(loc)) {
					var currentEnd:Point = (path.length == 0 ? room.playerCharacter.location : path[path.length - 1]);
					if (!loc.equals(currentEnd)) {
						var pathToMouse:Vector.<Point> = room.playerCharacter.findPathTo(loc, currentEnd);
						if (pathToMouse != null && pathToMouse.length <= room.playerCharacter.combatMovePoints - path.length) {
							extendPath(room.playerCharacter, pathToMouse);
						}
					}
				}
			}
		}
		
		private function launchCombatMovePieMenu(event:MouseEvent):void {
			if (event.target is FloorTile) {
				var tile:FloorTile = event.target as FloorTile;
				var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
				
				if (tile.location.equals(room.playerCharacter.location) ||
							(path.length > 0 && tile.location.equals(path[path.length - 1]))) {
					combatMovePie(slices);
				}
				
				if (slices.length > 0) {
					var tileCenterOnStage:Point = room.floor.localToGlobal(Floor.centerOf(tile.location));
					room.stage.removeEventListener(KeyboardEvent.KEY_DOWN, combatMoveKeyDownListener);
					var pie:PieMenu = new PieMenu(tileCenterOnStage.x, tileCenterOnStage.y, slices, combatMovePieDismissed);
					room.stage.addChild(pie);
				}
			}
		}
		
		private function combatMovePie(slices:Vector.<PieSlice>):void {
			if (path.length > 0) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.CancelMove), removePath));
			}
			slices.push(new PieSlice(Icon.bitmapData(Icon.Stay), doPlayerMoveStay));
			if (path.length > 0) {
				var minGait:int = room.playerCharacter.gaitForDistance(path.length);
				if (minGait <= Entity.GAIT_WALK) {
					slices.push(new PieSlice(Icon.bitmapData(Icon.Walk), doPlayerMoveWalk));
				}
				if (minGait <= Entity.GAIT_RUN) {
					slices.push(new PieSlice(Icon.bitmapData(Icon.Run), doPlayerMoveRun));
				}
				slices.push(new PieSlice(Icon.bitmapData(Icon.Sprint), doPlayerMoveSprint));
			}
		}
		
		private function combatMovePieDismissed():void {
			room.stage.addEventListener(KeyboardEvent.KEY_DOWN, combatMoveKeyDownListener);
		}
		
		private function doPlayerMove(gaitChoice:int = Entity.GAIT_UNSPECIFIED):void {
			Assert.assertTrue(iFighterTurnInProgress == 0, "doPlayerMove with iFighter " + iFighterTurnInProgress);
			disableCombatMoveUi();
			
			if (gaitChoice == Entity.GAIT_UNSPECIFIED) {
				gaitChoice = room.playerCharacter.gaitForDistance(path.length);
			}
			room.playerCharacter.centerRoomOnMe();
			startEntityFollowingPath(room.playerCharacter, gaitChoice);
		}
		
		private function doPlayerMoveStay():void {
			removePath();
			doPlayerMove(Entity.GAIT_WALK);
		}
		
		private function doPlayerMoveWalk():void {
			doPlayerMove(Entity.GAIT_WALK);
		}
		
		private function doPlayerMoveRun():void {
			doPlayerMove(Entity.GAIT_RUN);
		}
		
		private function doPlayerMoveSprint():void {
			doPlayerMove(Entity.GAIT_SPRINT);
		}
		
		/********** Player UI-related -- Fire segment ****************/
		
		// call this when player-controlled part of the turn begins, to allow player to enter move
		private function enableCombatFireUi():void {
			trace("entering player fire phase");
			room.addEventListener(MouseEvent.MOUSE_DOWN, combatSharedMouseDownListener);
			room.addEventListener(MouseEvent.MOUSE_MOVE, combatFireMouseMoveListener);
			room.addEventListener(MouseEvent.CLICK, combatFireClickListener);
			//Right-button mouse events are only supported in AIR.  For now, while we're using Flash Projector,
			//we're substituting ctrl-click.
			//room.addEventListener(MouseEvent.RIGHT_CLICK, launchPieMenu);
			room.stage.addEventListener(KeyboardEvent.KEY_DOWN, combatFireKeyDownListener);
			//UNDONE: hide cursor, display combat cursor icon
		}
		
		// call this when computer-controlled part of the turn begins, to prevent player from mucking around
		private function disableCombatFireUi():void {
			trace("ending player fire phase");
			room.moveHilight(null, 0);
			room.removeEventListener(MouseEvent.MOUSE_DOWN, combatSharedMouseDownListener);
			room.removeEventListener(MouseEvent.MOUSE_MOVE, combatFireMouseMoveListener);
			room.removeEventListener(MouseEvent.CLICK, combatFireClickListener);
			room.stage.removeEventListener(KeyboardEvent.KEY_DOWN, combatFireKeyDownListener);
		}
		
		private function combatFireKeyDownListener(event:KeyboardEvent):void {
			switch (event.keyCode) {
				case KEYBOARD_C:
					room.changeModeTo(RoomExplore);
				break;
				
				case KEYBOARD_V:
					room.toggleVisibility();
				break;
					
				case Keyboard.BACKSPACE:
					//UNDONE: cancel target selection
				break;
				
				case Keyboard.ENTER:
					finishedFire();
					//UNDONE: fire or reserve fire
				break;
			}
			
		}
		
		private function combatFireMouseMoveListener(event:MouseEvent):void {
			if (event.target is FloorTile) {
				var tile:FloorTile = event.target as FloorTile;
				room.moveHilight(tile, 0xffffff);
				//UNDONE: hilight enemy on tile
			}
			//UNDONE: move combat cursor icon
		}
		
		private function combatFireClickListener(event:MouseEvent):void {
			if (event.ctrlKey) {
				// Temporary since Flash Projector doesn't support right-button events.
				// If/when we switch to AIR this will be replaced with a real right click listener.
				launchCombatFirePieMenu(event);
				return;
			}
			if (!dragging && event.target is FloorTile) {
				var loc:Point = (event.target as FloorTile).location;
				//UNDONE handle click
			}
		}
		
		private function launchCombatFirePieMenu(event:MouseEvent):void {
			if (event.target is FloorTile) {
				var tile:FloorTile = event.target as FloorTile;
				var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
				
				combatFirePie(slices);
					
				if (slices.length > 0) {
					var tileCenterOnStage:Point = room.floor.localToGlobal(Floor.centerOf(tile.location));
					room.stage.removeEventListener(KeyboardEvent.KEY_DOWN, combatFireKeyDownListener);
					var pie:PieMenu = new PieMenu(tileCenterOnStage.x, tileCenterOnStage.y, slices, combatFirePieDismissed);
					room.stage.addChild(pie);
				}
			}
		}
		
		private function combatFirePie(slices:Vector.<PieSlice>):void {
			//UNDONE build pie menu
		}
		
		private function combatFirePieDismissed():void {
			room.stage.addEventListener(KeyboardEvent.KEY_DOWN, combatFireKeyDownListener);
		}

		
		/****************** Used by both player & NPCs during combat turns -- move segment *******************/
		
		public function startEntityFollowingPath(entity:Entity, gait:int):void {
			entity.startMovingAlongPath(path, gait); //CAUTION: this path now belongs to entity!
			path = new Vector.<Point>();
			endIndexes.length = 0;
		}
		
		// Remove dots at the end of the path, starting from index startFrom (default == remove all)
		private function clearDots(startFrom:int = 0):void {
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
			movePointsDisplay.text = String(room.playerCharacter.combatMovePoints - path.length);
			return gait;
		}
		
		private function removeLastPathSegment():void {
			if (dots.length > 0) {
				endIndexes.pop();
				var clearFrom:int = (endIndexes.length == 0 ? 0 : endIndexes[endIndexes.length - 1] + 1);
				clearDots(clearFrom);
				path.length = dots.length;
				movePointsDisplay.text = String(room.playerCharacter.combatMovePoints - path.length);
			}
		}
		
		private function removePath():void {
			clearDots(0);
			path.length = 0;
			movePointsDisplay.text = String(room.playerCharacter.combatMovePoints);
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
		
		private function colorForGait(gait:int):uint {
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
				enableCombatFireUi();
			} else {
				//UNDONE: enemy fire
				finishedFire();
			}
		}
		
		private function finishedFire():void {
			trace("fighter", iFighterTurnInProgress, "(", fighters[iFighterTurnInProgress].aaId, ") finished fire");
			++iFighterTurnInProgress;
			if (iFighterTurnInProgress >= fighters.length) {
				trace("All enemy turns have been processed, go back to player");
				iFighterTurnInProgress = 0;
				if (Settings.showEnemyMoves) {
					room.playerCharacter.centerRoomOnMe();
				}
				enableCombatMoveUi();
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