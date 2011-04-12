package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.Prop;
	import angel.common.PropImage;
	import angel.common.Tileset;
	import angel.common.Util;
	import angel.common.WalkerImage;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	// A physical object in the game world -- we aren't yet distinguishing between pc/npc/mobile/immobile.
	
	public class ComplexEntity extends SimpleEntity {
		
		private static const PIXELS_FOR_ADJACENT_MOVE:int = Math.sqrt(Tileset.TILE_WIDTH * Tileset.TILE_WIDTH/4 + Tileset.TILE_HEIGHT * Tileset.TILE_HEIGHT/4);
		private static const PIXELS_FOR_VERT_MOVE:int = Tileset.TILE_HEIGHT;
		private static const PIXELS_FOR_HORZ_MOVE:int = Tileset.TILE_WIDTH;
		
		private static const TEXT_OVER_HEAD_HEIGHT:int = 20;
		
		public static const GAIT_EXPLORE:int = 0;
		//NOTE: if distance allows walking, gait can be walk/run/sprint; if distance allows running, can be run/sprint
		//NOTE: code depends on these being a zero-based enumeration, not just arbitrary ints
		public static const GAIT_UNSPECIFIED:int = 0;
		public static const GAIT_WALK:int = 1;
		public static const GAIT_RUN:int = 2;
		public static const GAIT_SPRINT:int = 3;
		public static const GAIT_TOO_FAR:int = 4;

		// This array maps from a one-tile movement (offset by one) to facing, with arbitrary "face camera" for center
		public static const neighborToFacing:Vector.<Vector.<int>> = Vector.<Vector.<int>>([
				Vector.<int>([5,4,3]), Vector.<int>([6,WalkerImage.FACE_CAMERA,2]), Vector.<int>([7,0,1])
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
		public var maxHealth:int = 1;
		public var currentHealth:int;
		public var actionsRemaining:int;
		public var mostRecentGait:int = GAIT_WALK;	// gait for move in progress, or last move if none in progress
		public var exploreBrainClass:Class;
		public var combatBrainClass:Class;
		// This has no type yet because we aren't doing anything with it yet.  Eventually it will probably be an interface.
		public var brain:Object;
		
		private var playerControlled:Boolean;
		public var bestFriend:ComplexEntity; // for use by brain, persists through mode transitions

		// if non-null, drawn on decorations layer
		public var marker:Shape;
		
		private var textOverHead:TextField;
		
		private var moveGoal:Point; // the tile we're trying to get to
		private var path:Vector.<Point>; // the tiles we're trying to move through to get there
		private var movingTo:Point; // the tile we're immediately in the process of moving onto
		private var moveSpeed:Number;
		protected var coordsForEachFrameOfMove:Vector.<Point>;
		private var depthChangePerFrame:Number;
		protected var frameOfMove:int;
		protected var facing:int;
		
		// id is for debugging use only
		public function ComplexEntity(image:Bitmap, id:String = "") {
			super(image, Prop.DEFAULT_SOLIDITY, id);
			gaitSpeeds = Vector.<Number>([Settings.exploreSpeed, Settings.walkSpeed *2, Settings.runSpeed*2, Settings.sprintSpeed*2]);
		}
		
		public function makePlayerControlled():void {
			playerControlled = true;
			gaitSpeeds = Vector.<Number>([Settings.exploreSpeed, Settings.walkSpeed, Settings.runSpeed, Settings.sprintSpeed]);
		}
		
		public function get isPlayerControlled():Boolean {
			return playerControlled;
		}
						
		public function isEnemy():Boolean {
			//CONSIDER: is this true, or will we want to have civilians with combat behavior that are untargetable?
			return (combatBrainClass != null && currentHealth > 0);
		}
		
		public function joinCombat(roomCombat:RoomCombat):void {
			brain = new combatBrainClass(this, roomCombat);
		}
		
		public function exitCurrentMode():void {
			brain = null;
		}
		
		public function joinExplore(roomExplore:RoomExplore):void {
			if (exploreBrainClass != null) {
				brain = new exploreBrainClass(this, roomExplore);
			}
		}
		
		public function weaponDamage():int {
			var speedPenalty:int = 0;
			switch (mostRecentGait) {
				case GAIT_SPRINT:
					speedPenalty = 4;
				break;
				case GAIT_RUN:
					speedPenalty = 3;
				break;
				case GAIT_WALK:
					speedPenalty = 2;
				break;
			}
			return Settings.baseDamage - speedPenalty;
		}
		
		// This number is subtracted from any damage this entity receives
		public function defense():int {
			// These numbers are currently the same as speedPenalty to damage, but are unlikely to remain the same
			// Also, we'll probably have armor or other defense at some point.
			var speedBonus:int = 0;
			switch (mostRecentGait) {
				case GAIT_SPRINT:
					speedBonus = 4;
				break;
				case GAIT_RUN:
					speedBonus = 3;
				break;
				case GAIT_WALK:
					speedBonus = 2;
				break;
			}
			return speedBonus;
		}
		
		// Reset health at start and end of combat.
		public function initHealth():void {
			currentHealth = maxHealth;
		}
		
		public function setTextOverHead(value:String):void {
			if ((value == null) && (textOverHead != null)) {
				textOverHead.visible = false;
			} else if (value != null) {
				if (textOverHead == null) {
					textOverHead = Util.textBox("", Prop.WIDTH, TEXT_OVER_HEAD_HEIGHT, TextFormatAlign.CENTER);
					textOverHead.background = true;
					textOverHead.autoSize = TextFieldAutoSize.CENTER;
					textOverHead.y = imageBitmap.y - TEXT_OVER_HEAD_HEIGHT - 2;
					addChild(textOverHead);
				}
				textOverHead.visible = true;
				textOverHead.text = value;
			}
		}
				
		public function startDeathAnimation():void {
			// Does nothing for standard entity
		}
		
		//return true if moving, false if goal is unreachable or already there
		public function startMovingToward(goal:Point, gait:int = GAIT_EXPLORE):Boolean {
			var newPath:Vector.<Point> = findPathTo(goal);
			if (newPath != null) {
				startMovingAlongPath(newPath, gait);
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
			mostRecentGait = Math.min(gait, GAIT_SPRINT);
			moveSpeed = gaitSpeeds[mostRecentGait];
			room.addEventListener(Room.UNPAUSED_ENTER_FRAME, moveOneFrameAlongPath);
		}
		
		protected function adjustImageForMove():void {
			// Does nothing in the case of a basic single-image entity
		}
		
		public function turnToFacing(newFacing:int):void {
			facing = newFacing;
		}
		
		// Turn to the facing that closest approximates that direction
		public function turnToFaceTile(loc:Point):void {
			var angle:int = Util.findRotFacingVector(loc.subtract(myLocation)) + 360 + 22;
			turnToFacing((angle / 45) % 8);
		}
		
		// NOTE: At some point entities will probably have their own individual move points & gait percentages;
		// when that happens this will need to reference entity stats rather than Settings
		public function gaitForDistance(distance:int):int {
			if (distance<= Settings.walkPoints) {
				return ComplexEntity.GAIT_WALK;
			} else if (distance <= Settings.runPoints) {
				return ComplexEntity.GAIT_RUN;
			} else if (distance <= Settings.sprintPoints) {
				return ComplexEntity.GAIT_SPRINT;
			} else {
				return ComplexEntity.GAIT_TOO_FAR;
			}
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
			if (currentHealth <= 0) {
				finishedMoving();
				return;
			}
			
			if (movingTo == null) {
				movingTo = path.shift();
				// If path was empty, movingTo will still be null; in that case we're finished moving.
				// Someone may have moved onto my path in the time since I plotted it.  If so, abort move.
				// (If my brain wants to do something special in this case, it will need to remember its goal,
				// listen for FINISHED_MOVING event, compare location to goal, and take appropriate action.)
				if (movingTo == null || tileBlocked(movingTo)) {
					finishedMoving();
					return;
				}
				calculateStuffForMovementFrames();
				frameOfMove = 0;
				// Change the "real" location to the next tile.  Doing this on first frame of move rather than
				// halfway through the move circumvents a whole host of problems!
				room.changeEntityLocation(this, movingTo);
				myLocation = movingTo;
				dispatchEvent(new EntityEvent(EntityEvent.MOVED, true, false, this));
			}
			adjustImageForMove();
			x = coordsForEachFrameOfMove[frameOfMove].x;
			y = coordsForEachFrameOfMove[frameOfMove].y;
			myDepth += depthChangePerFrame;
			adjustDrawOrder();
			
			if (room.mode is RoomExplore) {
				if (playerControlled && (Settings.testExploreScroll > 0)) {
					scrollRoomToKeepPlayerWithinBox(Settings.testExploreScroll);
				}
			} else {
				if (playerControlled || Settings.showEnemyMoves) {
					centerRoomOnMe();
				}
			}
			
			frameOfMove++;
			if (frameOfMove == coordsForEachFrameOfMove.length) {
				movingTo = null;
				coordsForEachFrameOfMove = null;
				adjustImageForMove(); // make sure we end up in "standing" posture even if move was ultra-fast
				dispatchEvent(new EntityEvent(EntityEvent.FINISHED_ONE_TILE_OF_MOVE, true, false, this));
			}
		}
		
		private function finishedMoving():void {
			movingTo = null;
			path = null;
			coordsForEachFrameOfMove = null;
			room.removeEventListener(Room.UNPAUSED_ENTER_FRAME, moveOneFrameAlongPath);
			dispatchEvent(new EntityEvent(EntityEvent.FINISHED_MOVING, true, false, this));
		}
		
		public function get moving():Boolean {
			return (path != null);
		}
		
		// if from is null, find path from current location
		// NOTE: does not check whether the goal tile itself is occupied!
		public function findPathTo(goal:Point, from:Point = null):Vector.<Point> {
			if (from == null) {
				from = new Point(myLocation.x, myLocation.y);
			}
			var myPath:Vector.<Point> = new Vector.<Point>();
			
			if (!findShortestPathTo(from, goal, myPath)) {
				return null;
			}
			
			return myPath;
		}
		
		// If I'm not solid, I can go anywhere on map.  And I can always return to the tile I'm currently standing on
		// as part of the same move (even if I somehow got accidentally placed onto another solid object) -- this
		// avoids blocking my own move or getting stuck.
		// Other than that, if I'm solid I can't move into a solid tile.
		public function tileBlocked(loc:Point):Boolean {
			if (loc.equals(myLocation)) {
				return false;
			}
			if (!(solidness & Prop.SOLID)) {
				return (loc.x < 0 || loc.x >= room.size.x || loc.y < 0 || loc.y >= room.size.y)
			}
			return (room.solid(loc.x,loc.y) & Prop.SOLID) != 0;
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
			if ( (room.solid(from.x, from.y + step.y) & Prop.HARD_CORNER) &&
				 (room.solid(from.x + step.x, from.y) & Prop.HARD_CORNER) ) {
				return null;
			}
			return target;
		}
		
		// Fill in path.  Return false if there is no path
		// NOTE: Does not check whether the goal tile itself is blocked!
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
		
		// Fill a grid with the number of steps to all reachable points within a given range
		// (Used by NPC brains when choosing move)
		// Mostly matches findShortestPathTo(), just different enough to make them tough to merge ;)
		public function findReachableTiles(from:Point, range:int):Vector.<Vector.<int>> {
			// 0 = unvisited. -1 = blocked.  other number = distance counting start point as 1
			var steps:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(room.size.x);
			for (var i:int = 0; i < room.size.x; i++) {
				steps[i] = new Vector.<int>(room.size.y);
			}
			var edge:Vector.<Point> = new Vector.<Point>();
			edge.push(from);
			steps[from.x][from.y] = 1;

			while (edge.length > 0) {
				var current:Point = edge.shift();
				var stepsFromStart:int = steps[current.x][current.y] + 1;
				if (stepsFromStart == range + 1) {
					return steps;
				}
				Assert.assertTrue(stepsFromStart != 0, "Edge contains blocked cell");
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
						steps[xNext][yNext] = stepsFromStart;
						edge.push(neighbor);
					}
				}

			} // end while edge.length > 0
			return steps;
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
		

		
	} // end class ComplexEntity

}
