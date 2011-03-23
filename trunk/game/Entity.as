package angel.game {
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.Prop;
	import angel.common.PropImage;
	import angel.common.Tileset;
	import angel.common.Util;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.GlowFilter;
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
		public static const GAIT_UNSPECIFIED:int = 0;
		//NOTE: if distance allows walking, gait can be walk/run/sprint; if distance allows running, can be run/sprint
		public static const GAIT_WALK:int = 1;
		public static const GAIT_RUN:int = 2;
		public static const GAIT_SPRINT:int = 3;
		public static const GAIT_TOO_FAR:int = 4;

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
		public var combatBrainClass:Class;
		// This has no type yet because we aren't doing anything with it yet.  Eventually it will probably be an interface.
		public var brain:Object;
		
		// I'm not terribly happy about this as a UI feature, but Wm wants "enemies" to have their tiles outlined
		// in red during combat.  In the first implementation, I'm going to completely ignore the fact that this
		// will overwrite or be overwritten by the mouse-movement tile outlines.  If we end up keeping the feature,
		// and if the mouse conflict becomes a problem, then I'll have to hack in some sort of multiple-filter-tracking.
		public var personalTileHilight:GlowFilter;
		
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
		
		public var aaId:String; // catalog id + arbitrary index, for debugging, at top of alphabet for easy seeing!
		private static var totalEntitiesCreated:int = 0;
		
		// id is for debugging use only
		public function Entity(bitmap:Bitmap = null, id:String = "") {
			super(bitmap);
			
			totalEntitiesCreated++;
			aaId = id + "-" + String(totalEntitiesCreated);
		}
		
		public static function createFromPropImage(propImage:PropImage, id:String = ""):Entity {
			var entity:Entity = new Entity(new Bitmap(propImage.imageData), id);
			entity.solid = propImage.solid;
			return entity;
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
			// You'd think we could just call finishedMoving() here, if we're passed a null or empty path.
			// But if we do that, then the code that's listening for a FINISHED_MOVING event gets called
			// before we return from here, and it starts the next entity's move calculations before
			// the cleanup for this one has been done.  It's a terrible mess, because Actionscript's
			// dispatchEvent does an immediate call rather than putting the event into a queue.
			// So, we will pretend we have a path even if we don't, forcing that processing to happen
			// next time we get an ENTER_FRAME which is really asynchronous.
			path = (newPath == null ? new Vector.<Point> : newPath);
			moveGoal = (path.length > 0 ? path[path.length - 1] : myLocation);
			gait = Math.min(gait, GAIT_SPRINT);
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
			facing = neighborToFacing[tileMoveVector.x + 1][tileMoveVector.y + 1];
			
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
				if (movingTo == null || tileBlocked(movingTo)) {
					finishedMoving();
					return;
				}
				calculateStuffForMovementFrames();
				frameOfMove = 0;
				// Change the "real" location to the next tile.  Doing this on first frame of move rather than
				// halfway through the move circumvents a whole host of problems!
				room.changeEntityLocation(this, movingTo);
				dispatchEvent(new Event(MOVED, true));
				myLocation = movingTo;
			}
			adjustImageForMove();
			x = coordsForEachFrameOfMove[frameOfMove].x;
			y = coordsForEachFrameOfMove[frameOfMove].y;
			myDepth += depthChangePerFrame;
			adjustDrawOrder();
			
			if (room.mode is RoomExplore) {
				if (isPlayerControlled && (Settings.testExploreScroll > 0)) {
					scrollRoomToKeepPlayerWithinBox(Settings.testExploreScroll);
				}
			} else {
				if (isPlayerControlled || Settings.showEnemyMoves) {
					centerRoomOnMe();
				}
			}
			
			frameOfMove++;
			if (frameOfMove == coordsForEachFrameOfMove.length) {
				movingTo = null;
				coordsForEachFrameOfMove = null;
				adjustImageForMove(); // make sure we end up in "standing" posture even if move was ultra-fast
				if (path.length == 0) {
					finishedMoving();
				}
			}
		}
		
		private function finishedMoving():void {
			trace(aaId, "Finished moving");
			movingTo = null;
			path = null;
			coordsForEachFrameOfMove = null;
			room.removeEventListener(Room.UNPAUSED_ENTER_FRAME, moveOneFrameAlongPath);
			dispatchEvent(new Event(FINISHED_MOVING, true));
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
				var step:Point = new Point(Util.sign(goal.x - nextStep.x), Util.sign(goal.y - nextStep.y));
				nextStep = checkBlockage(nextStep, step);
				if (nextStep == null) {
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
			if (!(solid & Prop.SOLID) || loc.equals(myLocation)) {
				return false;
			}
			return (room.solid(loc) & Prop.SOLID) != 0;
		}
		
		// step is a one-tile vector. Return from+step if legal, null if not
		public function checkBlockage(from:Point, step:Point):Point {
			var target:Point = from.add(step);
			if (tileBlocked(target)) {
				return null;
			}
			if (step.x == 0 || step.y == 0) {
				return target;
			}
			if ( (room.solid(new Point(from.x, from.y + step.y)) & Prop.HARD_CORNER) &&
				 (room.solid(new Point(from.x + step.x, from.y)) & Prop.HARD_CORNER) ) {
				return null;
			}
			return target;
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
				Assert.assertTrue(stepsFromGoal != 0, "Edge contains blocked cell");
				for (i = 0; i < neighborCheck.length; i++) {
					var stepToNextNeighbor:Point = neighborCheck[i];
					var xNext:int = current.x + stepToNextNeighbor.x;
					var yNext:int = current.y + stepToNextNeighbor.y;
					if ((xNext < 0) || (xNext >= room.size.x) || (yNext < 0) || (yNext >= room.size.y)) {
						continue;
					}
					if (steps[xNext][yNext] != 0) {
						continue;
					}
					
					var neighbor:Point = checkBlockage(current, stepToNextNeighbor);
					if (neighbor == null) {
						if (tileBlocked(new Point(xNext, yNext))) {
							steps[xNext][yNext] = -1;
						}
					} else {
						steps[xNext][yNext] = stepsFromGoal;
						edge.push(neighbor);
					
						if ((xNext == from.x) && (yNext == from.y)) {
							extractPathFromStepGrid(from, goal, steps, path);
							//trace(path);
							return true;
						}
					}
				}

			} // end while edge.length > 0
			//trace("tile", goal, "unreachable");
			return false;
		}
		
		private function extractPathFromStepGrid(from:Point, goal:Point, steps:Vector.<Vector.<int>>, path:Vector.<Point>):void {
			//traceStepGrid(steps);
			path.length = 0;
			var current:Point = from.clone();
			var lookingFor:int = steps[current.x][current.y] - 1;
			while (lookingFor > 1) {
				for (var i:int = 0; i < neighborCheck.length; i++) {
					var stepToNextNeighbor:Point = neighborCheck[i];
					var xNext:int = current.x + stepToNextNeighbor.x;
					var yNext:int = current.y + stepToNextNeighbor.y;
					if ((xNext < 0) || (xNext > room.size.x - 1) || (yNext < 0) || (yNext > room.size.y - 1)) {
						continue;
					}
					if (steps[xNext][yNext] == lookingFor) {
						var neighbor:Point = checkBlockage(current, stepToNextNeighbor);
						if (neighbor != null) {
							current = neighbor;
							path.push(current);
							--lookingFor;
							break;
						}
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
		
		public function centerRoomOnMe():void {
			room.x = (stage.stageWidth / 2) - this.x - this.width/2;
			room.y = (stage.stageHeight / 2) - this.y - this.height/2;
		}
		
		// NOTE: At some point entities will probably have their own individual move points & gait percentages.
		public function gaitForDistance(distance:int):int {
			if (distance<= Settings.walkPoints) {
				return Entity.GAIT_WALK;
			} else if (distance <= Settings.runPoints) {
				return Entity.GAIT_RUN;
			} else if (distance <= Settings.sprintPoints) {
				return Entity.GAIT_SPRINT;
			} else {
				return Entity.GAIT_TOO_FAR;
			}
		}
		

		
	} // end class Entity

}
