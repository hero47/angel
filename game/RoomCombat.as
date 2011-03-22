package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.FloorTile;
	import angel.roomedit.Icon;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;

	
	public class RoomCombat implements RoomMode {
		
		private var room:Room;
		private var playerMoveInProgress:Boolean = false;
		private var path:Vector.<Point> = new Vector.<Point>();
		private var dots:Vector.<Shape> = new Vector.<Shape>();
		private var endIndexes:Vector.<int> = new Vector.<int>();
		private var movePointsDisplay:TextField;
		private var dragging:Boolean = false;
		
		private static const walkColor:uint = 0x00ff00;
		private static const runColor:uint = 0xffd800;
		private static const sprintColor:uint = 0xff0000;
		private static const outOfRangeColor:uint = 0x888888;

		public function RoomCombat(room:Room) {
			this.room = room;
			room.addEventListener(MouseEvent.MOUSE_DOWN, combatModeMouseDownListener);
			room.addEventListener(MouseEvent.MOUSE_MOVE, combatModeMouseMoveListener);
			room.addEventListener(MouseEvent.CLICK, combatModeClickListener);
			//Right-button mouse events are only supported in AIR.  For now, while we're using Flash Projector,
			//we're substituting ctrl-click.
			//room.addEventListener(MouseEvent.RIGHT_CLICK, launchPieMenu);
			room.stage.addEventListener(KeyboardEvent.KEY_DOWN, combatModeKeyDownListener);
			drawCombatGrid(room.decorationsLayer.graphics);
			movePointsDisplay = createMovePointsTextField();
			movePointsDisplay.text = String(room.playerCharacter.combatMovePoints);
			movePointsDisplay.x = 10;
			movePointsDisplay.y = 10;
			room.parent.addChild(movePointsDisplay);
			room.forEachEntity(initEntityBrain);
		}

		public function cleanup():void {
			room.removeEventListener(MouseEvent.CLICK, combatModeClickListener);
			room.removeEventListener(MouseEvent.MOUSE_DOWN, combatModeMouseDownListener);
			room.removeEventListener(MouseEvent.MOUSE_DOWN, combatModeMouseUpListener);
			room.removeEventListener(MouseEvent.MOUSE_MOVE, combatModeMouseMoveListener);
			room.stage.removeEventListener(KeyboardEvent.KEY_DOWN, combatModeKeyDownListener);
			room.playerCharacter.removeEventListener(Entity.MOVED, playerMoved);
			room.playerCharacter.removeEventListener(Entity.FINISHED_MOVING, playerFinishedMoving);
			room.decorationsLayer.graphics.clear();
			room.parent.removeChild(movePointsDisplay);
			clearDots();
			room.moveHilight(null, 0);
			room.forEachEntity(endEntityBrain);
		}
		
		private function initEntityBrain(entity:Entity):void {
			if (entity.combatBrainClass != null) {
				entity.brain = new entity.combatBrainClass(entity, this);
				entity.personalTileHilight = new GlowFilter(0xff0000, 1, 15, 15, 10, 1, true, false);
				room.updatePersonalTileHilight(entity);
			}
		}
		
		private function endEntityBrain(entity:Entity):void {
			entity.brain = null;
			if (entity.combatBrainClass != null) {
				entity.personalTileHilight = null;
				room.updatePersonalTileHilight(entity);
			}
		}
		
		// For God-only-knows what reason, the version of Keyboard class for Flex compilation is missing all
		// of the letter-key constants.  The version in CS5 has them.  ?????
		public static const KEYBOARD_C:uint = 67;
		public static const KEYBOARD_V:uint = 86;
		private function combatModeKeyDownListener(event:KeyboardEvent):void {
			if (playerMoveInProgress) {
				Alert.show("No commands allowed until move finishes.");
				return;
			}
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
					doMove();
				break;
			}
			
		}
		
		private function doMove(gaitChoice:int = Entity.GAIT_UNSPECIFIED):void {
			if (path.length > 0) {
				playerMoveInProgress = true;
				movePointsDisplay.visible = false;
				
				//room.scrollToCenter(room.playerCharacter.location, true); // snap to current location
				//room.scrollToCenter(path[path.length - 1]); // begin gradual scroll to final location
				
				if (gaitChoice == Entity.GAIT_UNSPECIFIED) {
					gaitChoice = gaitForDistance(path.length);
				}
				room.playerCharacter.addEventListener(Entity.MOVED, playerMoved);
				room.playerCharacter.addEventListener(Entity.FINISHED_MOVING, playerFinishedMoving);
				room.playerCharacter.startMovingAlongPath(path, gaitChoice); //CAUTION: this vector now belongs to entity!
				path = new Vector.<Point>();
				endIndexes.length = 0;
			}
		
		}
		
		private function doMoveWalk():void {
			doMove(Entity.GAIT_WALK);
		}
		
		private function doMoveRun():void {
			doMove(Entity.GAIT_RUN);
		}
		
		private function doMoveSprint():void {
			doMove(Entity.GAIT_SPRINT);
		}
		

		private function combatModeMouseDownListener(event:MouseEvent):void {
			if (event.shiftKey) {
				room.addEventListener(MouseEvent.MOUSE_UP, combatModeMouseUpListener);
				room.startDrag();
				dragging = true;
			} else {
				dragging = false;
			}
		}

		private function combatModeMouseUpListener(event:MouseEvent):void {
			room.removeEventListener(MouseEvent.MOUSE_UP, combatModeMouseUpListener);
			room.stopDrag();
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
		
		private function combatModeClickListener(event:MouseEvent):void {
			if (event.ctrlKey) {
				// Temporary since Flash Projector doesn't support right-button events.
				// If/when we switch to AIR this will be replaced with a real right click listener.
				launchPieMenu(event);
				return;
			}
			if (!dragging && event.target is FloorTile) {
				if (playerMoveInProgress) {
					Alert.show("No commands allowed until move finishes.");
					return;
				}
				var loc:Point = (event.target as FloorTile).location;
				if (!room.playerCharacter.tileBlocked(loc)) {
					var currentEnd:Point = (path.length == 0 ? room.playerCharacter.location : path[path.length - 1]);
					if (!loc.equals(currentEnd)) {
						var pathToMouse:Vector.<Point> = room.playerCharacter.findPathTo(loc, currentEnd);
						if (pathToMouse != null && pathToMouse.length <= room.playerCharacter.combatMovePoints - path.length) {
							extendPath(pathToMouse);
						}
					}
				}
			}
		}
		
		private function extendPath(pathToMouse:Vector.<Point>):void {
			clearDots();
			path = path.concat(pathToMouse);
			endIndexes.push(path.length - 1);
			dots.length = path.length;
			var endIndexIndex:int = 0;
			for (var i:int = 0; i < path.length; i++) {
				var color:uint;
				var isEnd:Boolean = (i == endIndexes[endIndexIndex]);
				dots[i] = dot(colorForDistance(path.length), Floor.centerOf(path[i]), isEnd );
				room.decorationsLayer.addChild(dots[i]);
				if (isEnd) {
					++endIndexIndex;
				}
			}
			movePointsDisplay.text = String(room.playerCharacter.combatMovePoints - path.length);
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
		
		private function colorForDistance(distance:int):uint {
			if (distance<= Settings.walkPoints) {
				return walkColor;
			} else if (distance <= Settings.runPoints) {
				return runColor;
			} else if (distance <= Settings.sprintPoints) {
				return sprintColor;
			} else {
				return outOfRangeColor;
			}
		}
		
		private function gaitForDistance(distance:int):int {
			if (distance<= Settings.walkPoints) {
				return Entity.GAIT_WALK;
			} else if (distance <= Settings.runPoints) {
				return Entity.GAIT_RUN;
			} else {
				return Entity.GAIT_SPRINT;
			}
		}
		
		private function combatModeMouseMoveListener(event:MouseEvent):void {
			if (!playerMoveInProgress && event.target is FloorTile) {
				var tile:FloorTile = event.target as FloorTile;
				var distance:int = 1000;
				if (!room.playerCharacter.tileBlocked(tile.location) && (path.length < room.playerCharacter.combatMovePoints)) {
					var pathToMouse:Vector.<Point> = room.playerCharacter.findPathTo(tile.location, 
							(path.length == 0 ? null : path[path.length-1]) );
					if (pathToMouse != null) {
						distance = path.length + pathToMouse.length;
					}
				}
				room.moveHilight(tile, colorForDistance(distance));
			}
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
		
		
		private function playerMoved(event:Event):void {
			var dotToRemove:Shape = dots.shift();
			room.decorationsLayer.removeChild(dotToRemove);
		}		

		private function playerFinishedMoving(event:Event):void {
			room.playerCharacter.removeEventListener(Entity.MOVED, playerMoved);
			room.playerCharacter.removeEventListener(Entity.FINISHED_MOVING, playerFinishedMoving);
			playerMoveInProgress = false;
			movePointsDisplay.visible = true;
			movePointsDisplay.text = String(room.playerCharacter.combatMovePoints);
		}	
		
		private function launchPieMenu(event:MouseEvent):void {
			if (!playerMoveInProgress && event.target is FloorTile) {
				var tile:FloorTile = event.target as FloorTile;
				var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
				
				if (path.length > 0) {
					if (tile.location.equals(room.playerCharacter.location) ||
							tile.location.equals(path[path.length - 1])) {
						combatMovePie(slices);
					}
				}
				
				if (slices.length > 0) {
					var tileCenterOnStage:Point = room.floor.localToGlobal(Floor.centerOf(tile.location));
					room.stage.removeEventListener(KeyboardEvent.KEY_DOWN, combatModeKeyDownListener);
					var pie:PieMenu = new PieMenu(tileCenterOnStage.x, tileCenterOnStage.y, slices, pieMenuDismissed);
					room.stage.addChild(pie);
				}
			}
		}
		
		private function combatMovePie(slices:Vector.<PieSlice>):void {
			// Pie-menu demo code, will be replaced once we have real functionality to put here
			slices.push(new PieSlice(Icon.bitmapData(Icon.CancelMove), removePath));
			var minGait:int = gaitForDistance(path.length);
			if (minGait <= Entity.GAIT_WALK) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.Walk), doMoveWalk));
			}
			if (minGait <= Entity.GAIT_RUN) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.Run), doMoveRun));
			}
			slices.push(new PieSlice(Icon.bitmapData(Icon.Sprint), doMoveSprint));
		}
		
		private function pieMenuDismissed():void {
			room.stage.addEventListener(KeyboardEvent.KEY_DOWN, combatModeKeyDownListener);
		}
		
	} // end class RoomCombat

}