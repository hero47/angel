package angel.game {
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.Tileset;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	// A physical object in the game world -- we aren't yet distinguishing between pc/npc/mobile/immobile.
	
	public class Entity extends Sprite {
		// Size of art assets for entities
		public static const WIDTH:int = 64;
		public static const HEIGHT:int = 128;
		
		// offsets from top corner of a tile's bounding box, to top corner of entity's bounding box when standing on it
		private static const OFFSET_X:int = 0;
		private static const OFFSET_Y:int = -96;
		
		private static const PIXELS_FOR_ADJACENT_MOVE:int = Math.sqrt(Tileset.TILE_WIDTH * Tileset.TILE_WIDTH/4 + Tileset.TILE_HEIGHT * Tileset.TILE_HEIGHT/4);
		private static const PIXELS_FOR_VERT_MOVE:int = Tileset.TILE_HEIGHT;
		private static const PIXELS_FOR_HORZ_MOVE:int = Tileset.TILE_WIDTH;

		// Facing == rotation/45 if we were in a top-down view.
		// This will make it convenient if we ever want to determine facing from actual angles
		
		// This array maps from a one-tile movement to facing, with arbitrary "face camera" for center
		private static const facingMap:Vector.<Vector.<int>> = Vector.<Vector.<int>>([
				Vector.<int>([5,4,3]), Vector.<int>([6,2,2]), Vector.<int>([7,0,1])
			]);		
		
		// Entity stats!  Eventually these will be initialized from data files.  They may go in a separate object.
		public var moveSpeed:Number = Settings.DEFAULT_MOVE_SPEED;
		public var adjacentTilesPerFrame:Number = moveSpeed / Settings.FRAMES_PER_SECOND;
		public var combatMovePoints:int = Settings.combatMovePoints;
		public var solid:Boolean = false;
		
		public var isPlayerControlled:Boolean;
		
		private var image:Bitmap;
		private var room:Room;
		private var myLocation:Point = null;
		// Depth represents distance to the "camera" plane, in our orthogonal view
		// The fractional part of depth indicates distance away from that line of cell-centers
		private var myDepth:Number = -Infinity;
		
		private var moveGoal:Point; // the tile we're trying to get to
		private var path:Vector.<Point>; // the tiles we're trying to move through to get there
		private var moveTo:Point; // the tile we're immediately in the process of moving onto
		protected var coordsForEachFrameOfMove:Vector.<Point>;
		private var depthChangePerFrame:Number;
		protected var frameOfMove:int;
		protected var facing:int;
		
		public function Entity(bitmap:Bitmap = null) {
			image = bitmap;
			if (bitmap != null) {
				addChild(image);
			}
		}
		
		public function addToRoom(room:Room, newLocation:Point = null):void {
			this.room = room;
			if (newLocation != null) {
				this.location = newLocation;
			}
		}
		
		public function get location():Point {
			Assert.assertTrue(parent != null, "Getting location of an entity not on stage");
			return myLocation;
		}
		
		public function set location(newLocation:Point):void {
			myLocation = newLocation;
			myDepth = newLocation.x + newLocation.y;
			var pixels:Point = pixelLocStandingOnTile(newLocation);
			this.x = pixels.x;
			this.y = pixels.y;
			Assert.assertTrue(parent != null, "Setting location of an entity not on stage");
			if (parent != null) {
				adjustDrawOrder();
			}
		}
		
		private function pixelLocStandingOnTile(tileLoc:Point):Point {
			var tilePixelLoc:Point = Floor.tileBoxCornerOf(tileLoc);
			return new Point(tilePixelLoc.x + OFFSET_X, tilePixelLoc.y + OFFSET_Y);
		}
		
		//UNDONE deal with changing goal partway through move
		//return true if moving, false if goal is unreachable or already there
		public function startMovingToward(goal:Point):Boolean {
			//room.changeEntityLocation(this, goal); // teleport directly there
			if (path == null) {
				moveGoal = goal;
				path = findPathTo(goal);
				if (path != null) {
					room.addEventListener(Room.UNPAUSED_ENTER_FRAME, moveOneFrameAlongPath);
					return true;
				}
				return false;
			}
			return true
		}
		
		public function startMovingAlongPath(newPath:Vector.<Point>):void {
			Assert.assertTrue(newPath != null, "Attempt to follow null path");
			path = newPath;
			moveGoal = path[path.length - 1];
			room.addEventListener(Room.UNPAUSED_ENTER_FRAME, moveOneFrameAlongPath);
		}
		
		protected function adjustImage():void {
			// Does nothing in the case of a basic single-image entity
		}
		
		// fills in coordsForEachFrameOfMove, depthChangePerFrame, and facing
		// This is a horrid name but I haven't been able to think of a better one or a better refactoring
		private function calculateStuffForMovementFrames():void {
			var tileMoveVector:Point = moveTo.subtract(myLocation);
			facing = facingMap[tileMoveVector.x + 1][tileMoveVector. y + 1];
			
			var totalPixels:int;
			if ((tileMoveVector.x == 0) || (tileMoveVector.y == 0)) {
				totalPixels = PIXELS_FOR_ADJACENT_MOVE;
			} else if (tileMoveVector.x == tileMoveVector.y) {
				totalPixels = PIXELS_FOR_VERT_MOVE;
			} else {
				totalPixels = PIXELS_FOR_HORZ_MOVE;
			}
			var pixelsPerFrame:int = adjacentTilesPerFrame * totalPixels;
			var depthChange:int = (tileMoveVector.x + tileMoveVector.y)
			var frames:int = Math.ceil(totalPixels / pixelsPerFrame);
			depthChangePerFrame = depthChange / frames;

			// TAG tile-width-is-twice-height: this will break if tiles no longer follow this rule!
			var pixelMoveVector:Point = new Point((tileMoveVector.x - tileMoveVector.y)*2, tileMoveVector.x + tileMoveVector.y);
			pixelMoveVector.normalize(pixelsPerFrame);
			
			coordsForEachFrameOfMove = new Vector.<Point>(frames);
			var nextCoords:Point = new Point(x, y);
			for (var i:int = 0; i < frames - 1; i++) {
				nextCoords = nextCoords.add(pixelMoveVector);
				coordsForEachFrameOfMove[i] = nextCoords;
			}
			// plug the last location in directly to remove accumulated rounding errors
			coordsForEachFrameOfMove[i] = pixelLocStandingOnTile(moveTo);
		}
		
		//UNDONE once we have obstacles, recalculate path each tile in case obstacles change
		//NOTE: once we're animating steps, animation may need to continue past arrival to get both feet on ground
		protected function moveOneFrameAlongPath(event:Event):void {
			if (moveTo == null) {
				moveTo = path.shift();
				calculateStuffForMovementFrames();
				frameOfMove = 0;
			}
			if (frameOfMove == Math.floor(coordsForEachFrameOfMove.length/2)) {
				room.changeEntityLocation(this, moveTo);
				myLocation = moveTo;
			}
			adjustImage();
			x = coordsForEachFrameOfMove[frameOfMove].x;
			y = coordsForEachFrameOfMove[frameOfMove].y;
			myDepth += depthChangePerFrame;
			adjustDrawOrder();
			
			if (isPlayerControlled && (Settings.testExploreScroll > 0) && (room.mode is RoomExplore)) {
				scrollRoomToKeepPlayerWithinBox(Settings.testExploreScroll);
			}
			
			frameOfMove++;
			if (frameOfMove == coordsForEachFrameOfMove.length) {
				moveTo = null;
				coordsForEachFrameOfMove = null;
				if (path.length == 0) {
					path = null;
					room.removeEventListener(Room.UNPAUSED_ENTER_FRAME, moveOneFrameAlongPath);
					room.playerFinishedMoving();
				}
			}
		}
		
		// if from is null, find path from current location
		public function findPathTo(goal:Point, from:Point = null):Vector.<Point> {
			if (from == null) {
				from = new Point(myLocation.x, myLocation.y);
			}
			var myPath:Vector.<Point> = new Vector.<Point>();
			var nextStep:Point = from;
			var blocked:Boolean = false;
			
			// First, see if we can just take the default path without hitting an obstacle
			while (!nextStep.equals(goal)) {
				nextStep = new Point(nextStep.x + sign(goal.x - nextStep.x), nextStep.y + sign(goal.y - nextStep.y));
				if (room.solid(nextStep)) {
					blocked = true;
					break;
				}
				myPath.push(nextStep);
			}
			
			if (blocked) {
				myPath.length = 0;
				if (!findShortestPathTo(from, goal, myPath)) {
					return null;
				}
			}
			
			return myPath;
		}
		
		// Fill in path.  Return false if there is no path
		private function findShortestPathTo(from:Point, goal:Point, path:Vector.<Point>):Boolean {
			// 0 = unvisited. -1 = solid.  other number = steps to reach goal, counting goal itself as 1.
			var steps:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(room.size.x);
			for (var i:int = 0; i < room.size.x; i++) {
				steps[i] = new Vector.<int>(room.size.y);
			}
			var edge:Vector.<Point> = new Vector.<Point>();
			edge.push(goal);
			steps[goal.x][goal.y] = 1;

			while (edge.length > 0) {
				var current:Point = edge.shift();
				var stepsFromGoal:int = steps[current.x][current.y] + 1;
				if (stepsFromGoal == 0) { // solid cell
					continue;
				}
				for (var xNext:int = Math.min(room.size.x-1, current.x + 1); xNext >= Math.max(0, current.x - 1); --xNext) {
					for (var yNext:int = Math.min(room.size.y-1, current.y + 1); yNext >= Math.max(0, current.y - 1); --yNext) {
						if (steps[xNext][yNext] != 0) {
							continue;
						}
						if (xNext == from.x && yNext == from.y) {
							extractPathFromStepGrid(goal, steps, path, current);
							return true;
						}
						var neighbor:Point = new Point(xNext, yNext);
						steps[xNext][yNext] = room.solid(neighbor) ? -1 : stepsFromGoal;
						edge.push(neighbor);
					}
				}

				//traceStepGrid(steps);

			} // end while edge.length > 0
			return false;
		}
		
		private function extractPathFromStepGrid(goal:Point, steps:Vector.<Vector.<int>>, path:Vector.<Point>, firstStep:Point):void {
			path.length = 0;
			var current:Point = firstStep.clone();
			path.push(current);
			var lookingFor:int = steps[firstStep.x][firstStep.y] - 1;
			while (lookingFor > 1) {
				var foundStep:Boolean = false;
				//favor the higher-numbered tiles, they're closer to camera
				for (var xNext:int = Math.min(room.size.x-1, current.x + 1); xNext >= Math.max(0, current.x - 1); --xNext) {
					for (var yNext:int = Math.min(room.size.y-1, current.y + 1); yNext >= Math.max(0, current.y - 1); --yNext) {
						if (steps[xNext][yNext] == lookingFor) {
							current = new Point(xNext, yNext);
							path.push(current);
							--lookingFor;
							foundStep = true;
							break;
						}
					} // end for yNext
					if (foundStep) {
						break;
					}
				} // end for xNext
			}
			path.push(goal);
		}
		
		private function traceStepGrid(steps:Vector.<Vector.<int>>):void {
			trace("Grid:");
			for (var y:int = 0; y < room.size.y; ++y) {
				var foo:String = "";
				for (var x:int = 0; x < room.size.x; ++x) {
					foo += (steps[x][y] == -1 ? "X" : String(steps[x][y]));
				}
				trace(foo);
			}
		}
		
		protected function get depth():Number {
			return myDepth;
		}

		// CAUTION: Depends on all children in content layer being Entity
		private function adjustDrawOrder():void {
			var index:int = parent.getChildIndex(this);
			var correctIndex:int;
			var other:Entity = null;
			// Assuming depth is currently correct or too low, find index I should move to
			for (correctIndex = index; correctIndex > 0; correctIndex--) {
				other = Entity(parent.getChildAt(correctIndex - 1));
				if (other.depth < myDepth) {
					break;
				}
			}
			if (correctIndex == index) {
				//That didn't find a move, so depth must be correct or too high.
				for (correctIndex = index; correctIndex < parent.numChildren-1; correctIndex++) {
					other = Entity(parent.getChildAt(correctIndex + 1));
					if (other.depth > myDepth) {
						break;
					}
				}
			}
			
			if (correctIndex != index) {
				parent.setChildIndex(this, correctIndex);
			}

		}

		private function scrollRoomToKeepPlayerWithinBox(distanceFromEdge:int):void {
			var xOffset:int = 0;
			var yOffset:int = 0;
			var adjustedBox:Rectangle = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
			adjustedBox.inflate( -distanceFromEdge, -distanceFromEdge);
			adjustedBox.offset(-room.x, -room.y);
			if (this.x < adjustedBox.x) {
				xOffset = adjustedBox.x - this.x;
			}
			if (this.x + this.width > adjustedBox.right) {
				xOffset = adjustedBox.right - this.x - this.width;
			}
			if (this.y < adjustedBox.y) {
				yOffset = adjustedBox.y - this.y;
			}
			if (this.y + this.height > adjustedBox.bottom) {
				yOffset = adjustedBox.bottom - this.y - this.height;
			}

			room.x += xOffset;
			room.y += yOffset;
		}		
		
		public static function sign(foo:int):int {
			return (foo < 0 ? -1 : (foo > 0 ? 1 : 0));
		}
		

		
	} // end class Entity

}