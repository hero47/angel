package angel.game {
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.Prop;
	import angel.common.PropImage;
	import angel.common.Tileset;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	// A physical object in the game world -- we aren't yet distinguishing between pc/npc/mobile/immobile.
	
	public class Entity extends Prop {
		// Events
		public static const MOVED:String = "entityMoved";
		public static const FINISHED_MOVING:String = "entityFinishedMoving";
		
		private static const PIXELS_FOR_ADJACENT_MOVE:int = Math.sqrt(Tileset.TILE_WIDTH * Tileset.TILE_WIDTH/4 + Tileset.TILE_HEIGHT * Tileset.TILE_HEIGHT/4);
		private static const PIXELS_FOR_VERT_MOVE:int = Tileset.TILE_HEIGHT;
		private static const PIXELS_FOR_HORZ_MOVE:int = Tileset.TILE_WIDTH;
		
		public static const GAIT_EXPLORE:int = 0;
		public static const GAIT_WALK:int = 1;
		public static const GAIT_RUN:int = 2;
		public static const GAIT_SPRINT:int = 3;

		// Facing == rotation/45 if we were in a top-down view.
		// This will make it convenient if we ever want to determine facing from actual angles
		public static const FACE_CAMERA:int = 1;
		
		
		// This array maps from a one-tile movement to facing, with arbitrary "face camera" for center
		public static const neighborToFacing:Vector.<Vector.<int>> = Vector.<Vector.<int>>([
				Vector.<int>([5,4,3]), Vector.<int>([6,FACE_CAMERA,2]), Vector.<int>([7,0,1])
			]);
		public static const facingToNeighbor:Vector.<Point> = Vector.<Point>([
				new Point(1, 0), new Point(1, 1), new Point(0, 1), new Point( -1, 1),
				new Point( -1, 0), new Point( -1, -1), new Point(0, -1), new Point( -1, -1)
			]);

		// check neighbor tiles in this order when choosing path, so we'll prefer "straight" moves
		private static const neighborCheck:Vector.<Point> = Vector.<Point>([
				new Point(1, 0), new Point(0, 1), new Point(0, -1), new Point( -1, 0),
				new Point(1, 1), new Point(1, -1), new Point( -1, -1), new Point( -1, 1)
			]);

		// Entity stats!  Eventually these will be initialized from data files.  They may go in a separate object.
		public var gaitSpeeds:Vector.<Number> = Vector.<Number>([Settings.exploreSpeed, Settings.walkSpeed, Settings.runSpeed, Settings.sprintSpeed]);
		public var combatMovePoints:int = Settings.combatMovePoints;
		public var exploreBrainClass:Class;
		// This has no type yet because we aren't doing anything with it yet.  Eventually it will probably be an interface.
		public var brain:Object;
		
		public var isPlayerControlled:Boolean;

		private var room:Room;
		private var moveGoal:Point; // the tile we're trying to get to
		private var path:Vector.<Point>; // the tiles we're trying to move through to get there
		private var movingTo:Point; // the tile we're immediately in the process of moving onto
		private var moveSpeed:Number;
		protected var coordsForEachFrameOfMove:Vector.<Point>;
		private var depthChangePerFrame:Number;
		protected var frameOfMove:int;
		protected var facing:int;
		
		public function Entity(bitmap:Bitmap = null) {
			super(bitmap);
		}
		
		public static function createFromPropImage(propImage:PropImage):Entity {
			return new Entity(new Bitmap(propImage.imageData));
		}
		
		public function addToRoom(room:Room, newLocation:Point = null):void {
			this.room = room;
			if (newLocation != null) {
				this.location = newLocation;
			}
		}
		
		//return true if moving, false if goal is unreachable or already there
		public function startMovingToward(goal:Point, gait:int=GAIT_EXPLORE):Boolean {
			moveGoal = goal;
			moveSpeed = gaitSpeeds[gait];
			path = findPathTo(goal);
			if (path != null) {
				room.addEventListener(Room.UNPAUSED_ENTER_FRAME, moveOneFrameAlongPath);
				return true;
			}
			return false;
		}
		
		public function startMovingAlongPath(newPath:Vector.<Point>, gait:int = GAIT_EXPLORE):void {
			Assert.assertTrue(newPath != null, "Attempt to follow null path");
			path = newPath;
			moveGoal = path[path.length - 1];
			moveSpeed = gaitSpeeds[gait];
			room.addEventListener(Room.UNPAUSED_ENTER_FRAME, moveOneFrameAlongPath);
		}
		
		protected function adjustImageForMove():void {
			// Does nothing in the case of a basic single-image entity
		}
		
		public function turnToFacing(newFacing:int):void {
			facing = newFacing;
		}
		
		// fills in coordsForEachFrameOfMove, depthChangePerFrame, and facing
		// This is a horrid name but I haven't been able to think of a better one or a better refactoring
		private function calculateStuffForMovementFrames():void {
			var tileMoveVector:Point = movingTo.subtract(myLocation);
			facing = neighborToFacing[tileMoveVector.x + 1][tileMoveVector. y + 1];
			
			var totalPixels:int;
			if ((tileMoveVector.x == 0) || (tileMoveVector.y == 0)) {
				totalPixels = PIXELS_FOR_ADJACENT_MOVE;
			} else if (tileMoveVector.x == tileMoveVector.y) {
				totalPixels = PIXELS_FOR_VERT_MOVE;
			} else {
				totalPixels = PIXELS_FOR_HORZ_MOVE;
			}
			var pixelsPerFrame:int = moveSpeed * totalPixels / Settings.FRAMES_PER_SECOND;
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
			coordsForEachFrameOfMove[i] = pixelLocStandingOnTile(movingTo);
		}
		
		protected function moveOneFrameAlongPath(event:Event):void {
			if (movingTo == null) {
				movingTo = path.shift();
				// Someone may have moved onto my path in the time since I plotted it.  If so, abort move.
				// If my brain wants to do something special in this case, it will need to remember its goal,
				// listen for FINISHED_MOVING event, compare location to goal, and take appropriate action.
				if (tileBlocked(movingTo)) {
					finishedMoving();
					return;
				}
				calculateStuffForMovementFrames();
				frameOfMove = 0;
				// Change the "real" location to the next tile.  Doing this on first frame of move rather than
				// halfway through the move circumvents a whole host of problems!
				room.changePropLocation(this, movingTo);
				dispatchEvent(new Event(MOVED));
				myLocation = movingTo;
			}
			adjustImageForMove();
			x = coordsForEachFrameOfMove[frameOfMove].x;
			y = coordsForEachFrameOfMove[frameOfMove].y;
			myDepth += depthChangePerFrame;
			adjustDrawOrder();
			
			if (isPlayerControlled && (Settings.testExploreScroll > 0) && (room.mode is RoomExplore)) {
				scrollRoomToKeepPlayerWithinBox(Settings.testExploreScroll);
			}
			
			frameOfMove++;
			if (frameOfMove == coordsForEachFrameOfMove.length) {
				movingTo = null;
				coordsForEachFrameOfMove = null;
				if (path.length == 0) {
					finishedMoving();
				}
			}
		}
		
		private function finishedMoving():void {
			path = null;
			room.removeEventListener(Room.UNPAUSED_ENTER_FRAME, moveOneFrameAlongPath);
			dispatchEvent(new Event(FINISHED_MOVING));
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
				if (tileBlocked(nextStep)) {
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
		
		// If I'm not solid, I can go anywhere.  And I can always return to the tile I'm currently standing on
		// as part of the same move (even if I somehow got accidentally placed onto another solid object) -- this
		// avoids blocking my own move or getting stuck.
		// Other than that, if I'm solid I can't move into a solid tile.
		public function tileBlocked(loc:Point):Boolean {
			if (loc.x < 0 || loc.x >= room.size.x || loc.y < 0 || loc.y >= room.size.y) {
				return true;
			}
			if (!solid || loc.equals(myLocation)) {
				return false;
			}
			return room.solid(loc);
		}
		
		// Fill in path.  Return false if there is no path
		private function findShortestPathTo(from:Point, goal:Point, path:Vector.<Point>):Boolean {
			// 0 = unvisited. -1 = blocked.  other number = steps to reach goal, counting goal itself as 1.
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
				if (stepsFromGoal == 0) { // blocked cell
					continue;
				}
				for (i = 0; i < neighborCheck.length; i++) {
					var nextNeighbor:Point = neighborCheck[i];
					var xNext:int = current.x + nextNeighbor.x;
					var yNext:int = current.y + nextNeighbor.y;
					if ((xNext < 0) || (xNext > room.size.x - 1) || (yNext < 0) || (yNext > room.size.y - 1)) {
						continue;
					}
					if (steps[xNext][yNext] != 0) {
						continue;
					}
					var neighbor:Point = new Point(xNext, yNext);
					steps[xNext][yNext] = tileBlocked(neighbor) ? -1 : stepsFromGoal;
					edge.push(neighbor);
					
					if (xNext == from.x && yNext == from.y) {
						extractPathFromStepGrid(from, goal, steps, path);
						return true;
					}
				}

			} // end while edge.length > 0
			return false;
		}
		
		private function extractPathFromStepGrid(from:Point, goal:Point, steps:Vector.<Vector.<int>>, path:Vector.<Point>):void {
			//traceStepGrid(steps);
			path.length = 0;
			var current:Point = from.clone();
			var lookingFor:int = steps[current.x][current.y] - 1;
			while (lookingFor > 1) {
				for (var i:int = 0; i < neighborCheck.length; i++) {
					var nextNeighbor:Point = neighborCheck[i];
					var xNext:int = current.x + nextNeighbor.x;
					var yNext:int = current.y + nextNeighbor.y;
					if ((xNext < 0) || (xNext > room.size.x - 1) || (yNext < 0) || (yNext > room.size.y - 1)) {
						continue;
					}
					if (steps[xNext][yNext] == lookingFor) {
						current = new Point(xNext, yNext);
						path.push(current);
						--lookingFor;
						break;
					}
				} // end for
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