package angel.game {
	import angel.common.Prop;
	import angel.common.Tileset;
	import angel.game.event.EntityQEvent;
	import angel.game.event.QEvent;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class EntityMovement {
		
		private static const PIXELS_FOR_ADJACENT_MOVE:int = Math.sqrt(Tileset.TILE_WIDTH * Tileset.TILE_WIDTH/4 + Tileset.TILE_HEIGHT * Tileset.TILE_HEIGHT/4);
		private static const PIXELS_FOR_VERT_MOVE:int = Tileset.TILE_HEIGHT;
		private static const PIXELS_FOR_HORZ_MOVE:int = Tileset.TILE_WIDTH;
		
		public static const GAIT_EXPLORE:int = 0;
		public static const GAIT_UNSPECIFIED:int = 0;
		//NOTE: if distance allows walking, gait can be walk/run/sprint; if distance allows running, can be run/sprint
		//NOTE: code depends on these being a zero-based enumeration, not just arbitrary ints
		public static const GAIT_NO_MOVE:int = 0;
		public static const GAIT_WALK:int = 1;
		public static const GAIT_RUN:int = 2;
		public static const GAIT_SPRINT:int = 3;
		public static const GAIT_TOO_FAR:int = 4;

		// This array maps from a one-tile movement (offset by one) to facing, with arbitrary "face camera" for center
		public static const neighborToFacing:Vector.<Vector.<int>> = Vector.<Vector.<int>>([
				Vector.<int>([5,4,3]), Vector.<int>([6,1,2]), Vector.<int>([7,0,1])
			]);
		public static const facingToNeighbor:Vector.<Point> = Vector.<Point>([
				new Point(1, 0), new Point(1, 1), new Point(0, 1), new Point( -1, 1),
				new Point( -1, 0), new Point( -1, -1), new Point(0, -1), new Point( -1, -1)
			]);
			
		private var me:ComplexEntity;
		
		private var combatMovePoints:int;
		public var unusedMovePoints:int;
		public var maxGait:int;
		public var minGait:int = GAIT_WALK;
		
		private var gaitRestrictedUntilMoveFinished:Boolean;
		private var realMaxGait:int;
		private var realMinGait:int;
		
		public var gaitSpeeds:Vector.<Number> = Vector.<Number>([Settings.exploreSpeed, Settings.walkSpeed, Settings.runSpeed, Settings.sprintSpeed]);
		private var gaitDistances:Vector.<int>;
		public var mostRecentGait:int = GAIT_WALK;	// gait for move in progress, or last move if none in progress
		
		private var moveGoal:Point; // the tile we're trying to get to
		private var path:Vector.<Point>; // the tiles we're trying to move through to get there
		private var movingTo:Point; // the tile we're immediately in the process of moving onto
		private var moveSpeed:Number;
		private var coordsForEachFrameOfMove:Vector.<Point>;
		private var depthChangePerFrame:Number;
		private var frameOfMove:int;
		private var interruptAfterThisTile:Boolean = false;
		
		public function EntityMovement(entity:ComplexEntity, movePoints:int, maxGait:int = GAIT_SPRINT) {
			me = entity;
			this.maxGait = maxGait;
			setMovePoints(movePoints);
			setSpeeds(false);
		}
		
		public function cleanup():void {
			Settings.gameEventQueue.removeListener(me.room, Room.ROOM_ENTER_UNPAUSED_FRAME, moveOneFrameAlongPath);
			me = null;
		}
		
		public function moving():Boolean {
			return (path != null);
		}
		
		public function setSpeeds(playerControlled:Boolean):void {
			if (playerControlled) {
				gaitSpeeds = Vector.<Number>([Settings.exploreSpeed, Settings.walkSpeed, Settings.runSpeed, Settings.sprintSpeed]);
			} else {
				gaitSpeeds = Vector.<Number>([Settings.exploreSpeed, Settings.walkSpeed * 2, Settings.runSpeed * 2, Settings.sprintSpeed * 2]);
			}
		}
		
		public function setMovePoints(points:int):void {		
			// Init file gives us settings for two of the three percents.  We want to set movement points for those
			// two speeds based on percent of total points, then give the third one whatever's left (so rounding
			// errors fall into the unspecified one).
			// Then, once that's figured out, convert them to totals.
			combatMovePoints = unusedMovePoints = points;
			var walkPoints:int = combatMovePoints * Settings.walkPercent/100;
			var runPoints:int = combatMovePoints * Settings.runPercent/100;
			var sprintPoints:int = combatMovePoints * Settings.sprintPercent/100;
			if (walkPoints + runPoints + sprintPoints == 0) {
				walkPoints = runPoints = combatMovePoints / 3;
			}
			
			if (walkPoints == 0) {
				walkPoints = combatMovePoints - runPoints - sprintPoints;
			}
			if (runPoints == 0) {
				runPoints = combatMovePoints - walkPoints - sprintPoints;
			}
			if (sprintPoints == 0) {
				sprintPoints = combatMovePoints - walkPoints - runPoints;
			}
			
			runPoints += walkPoints;
			sprintPoints += runPoints;
			gaitDistances = Vector.<int>( [0, walkPoints, runPoints, sprintPoints] );
		}
		
		public function restrictGaitUntilMoveFinished(gait:int):void {
			gaitRestrictedUntilMoveFinished = true;
			realMaxGait = maxGait;
			realMinGait = minGait;
			maxGait = minGait = gait;
		}
		
		public function gaitIsRestricted():Boolean {
			return gaitRestrictedUntilMoveFinished;
		}
		
		private function removeGaitRestriction():void {
			gaitRestrictedUntilMoveFinished = false;
			maxGait = realMaxGait;
			minGait = realMinGait;
		}
		
		//return true if moving, false if goal is unreachable or already there
		public function startFreeMovementToward(goal:Point, gait:int = GAIT_EXPLORE):Boolean {
			var newPath:Vector.<Point> = findPathTo(goal);
			if (newPath != null) {
				startMovingAlongPath(newPath, gait);
				return true;
			}
			return false;
		}
		
		public function initForCombatMove():void {
			unusedMovePoints = combatMovePoints;
		}
		
		public function get usedMovePoints():int {
			return combatMovePoints - unusedMovePoints;
		}
		
		public function startMovingAlongPath(newPath:Vector.<Point>, gait:int = GAIT_EXPLORE):void {
			// You'd think we could just call finishedMoving() here, if we're passed a null or empty path.
			// But if we do that, then the code that's listening for a FINISHED_MOVING event gets called
			// before we return from here, and it starts the next entity's move calculations before
			// the cleanup for this one has been done.  It's a terrible mess, because Actionscript's
			// dispatchEvent does an immediate call rather than putting the event into a queue.
			// So, we will pretend we have a path even if we don't, forcing that processing to happen
			// next time we get an ENTER_FRAME which is really asynchronous.
			interruptAfterThisTile = false;
			path = (newPath == null ? new Vector.<Point> : newPath);
			moveGoal = (path.length > 0 ? path[path.length - 1] : me.location);
			mostRecentGait = (path.length == 0 ? GAIT_NO_MOVE : Math.min(gait, maxGait));
			moveSpeed = gaitSpeeds[mostRecentGait];
			Settings.gameEventQueue.addListener(this, me.room, Room.ROOM_ENTER_UNPAUSED_FRAME, moveOneFrameAlongPath);
		}
		
		public function minGaitForDistance(distance:int):int {
			if (distance == 0) {
				return GAIT_NO_MOVE;
			}
			for (var gait:int = minGait; gait <= maxGait; ++gait) {
				if (distance <= gaitDistances[gait]) {
					return gait;
				}
			}
			return GAIT_TOO_FAR;
		}
		
		// call with no param returns max distance for max gait
		public function maxDistanceForGait(gait:int = GAIT_TOO_FAR):int {
			if (gait <= GAIT_NO_MOVE) {
				return 0;
			}
			if (gait > maxGait) {
				gait = maxGait;
			}
			return gaitDistances[gait];
		}
		
		// fills in coordsForEachFrameOfMove, depthChangePerFrame, and facing
		// This is a horrid name but I haven't been able to think of a better one or a better refactoring
		private function calculateStuffForMovementFrames():void {
			var tileMoveVector:Point = movingTo.subtract(me.location);
			me.turnToFacing(neighborToFacing[tileMoveVector.x + 1][tileMoveVector.y + 1]);
			
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
			var nextCoords:Point = new Point(me.x, me.y);
			for (var i:int = 0; i < frames - 1; i++) {
				nextCoords = nextCoords.add(pixelMoveVector);
				coordsForEachFrameOfMove[i] = nextCoords;
			}
			// plug the last location in directly to remove accumulated rounding errors
			coordsForEachFrameOfMove[i] = me.pixelLocStandingOnTile(movingTo);
		}
		
		protected function moveOneFrameAlongPath(event:QEvent):void {
			if (me.currentHealth <= 0) {
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
				changeLocationAsPartOfMove();
			}
			me.adjustImageForMove(frameOfMove, coordsForEachFrameOfMove.length);
			me.x = coordsForEachFrameOfMove[frameOfMove].x;
			me.y = coordsForEachFrameOfMove[frameOfMove].y;
			me.depth += depthChangePerFrame;
			me.adjustDrawOrder();
			
			if (me.room.mode is RoomExplore) {
				if (me.isReallyPlayer && (Settings.testExploreScroll > 0)) {
					scrollRoomToKeepPlayerWithinBox(Settings.testExploreScroll);
				}
			} else {
				if (me.isReallyPlayer || Settings.showEnemyMoves) {
					me.centerRoomOnMe();
				}
			}
			
			frameOfMove++;
			if (frameOfMove == coordsForEachFrameOfMove.length) {
				finishOneTileOfMove();
			}
		}
		
		private function finishOneTileOfMove():void {
			movingTo = null;
			coordsForEachFrameOfMove = null;
			me.adjustImageForMove(0, 0); // make sure we end up in "standing" posture even if move was ultra-fast
			Settings.gameEventQueue.dispatch(new EntityQEvent(me, EntityQEvent.FINISHED_ONE_TILE_OF_MOVE));
			if (interruptAfterThisTile) {
				finishedMoving(true);
			}
		}
		
		private function changeLocationAsPartOfMove():void {
			--unusedMovePoints;
			var oldLocation:Point = me.location;
			me.setLocationWithoutChangingDepth(movingTo);
			me.room.changeEntityLocation(me, oldLocation, movingTo);
			Settings.gameEventQueue.dispatch(new EntityQEvent(me, EntityQEvent.LOCATION_CHANGED_IN_MOVE));
		}		
		
		private function finishedMoving(wasInterrupted:Boolean = false):void {
			if (gaitRestrictedUntilMoveFinished) {
				removeGaitRestriction();
			}
			interruptAfterThisTile = false;
			movingTo = null;
			path = null;
			coordsForEachFrameOfMove = null;
			Settings.gameEventQueue.removeListener(me.room, Room.ROOM_ENTER_UNPAUSED_FRAME, moveOneFrameAlongPath);
			Settings.gameEventQueue.dispatch(new EntityQEvent(me, 
					(wasInterrupted ? EntityQEvent.MOVE_INTERRUPTED : EntityQEvent.FINISHED_MOVING)));
		}
		
		public function endMoveImmediately():void {
			if (path != null) {
				if (movingTo != null) {
					me.moveToCenterOfTile();
					interruptAfterThisTile = false; // we want this to end up as a move finished, not a move interrupted
					finishOneTileOfMove();
				}
				finishedMoving(false);
			}
		}
		
		//When animation to reach the tile we're currently moving onto finishes, if that wasn't the last tile in
		//the path, stop there and send MOVE_INTERRUPTED instead of FINISHED_MOVING.
		//Returns a clone of the part of the path that will be left uncompleted.
		public function interruptMovementAfterTileFinished():Vector.<Point> {
			if ((path != null) && (path.length > 0)) {
				if (movingTo == null) {
					finishedMoving(true);
					return null;
				} else {
					interruptAfterThisTile = true;
					return path.concat();
				}
			}
			return null;
		}
		
		// if from is null, find path from current location
		// NOTE: does not check whether the goal tile itself is occupied!
		// NOTE: path does not include the starting tile.
		// If ignoreInvisible is true, pretend anything invisible doesn't exist.
		public function findPathTo(goal:Point, from:Point = null, ignoreInvisible:Boolean = false):Vector.<Point> {
			if (from == null) {
				from = me.location;
			}
			var myPath:Vector.<Point> = new Vector.<Point>();
			
			if (!Pathfinder.findShortestPathTo(me, from, goal, myPath, ignoreInvisible)) {
				return null;
			}
			return myPath;
		}
		
		// If I'm not solid, I can go anywhere on map.  And I can always return to the tile I'm currently standing on
		// as part of the same move (even if I somehow got accidentally placed onto another solid object) -- this
		// avoids blocking my own move or getting stuck.
		// Other than that, if I'm solid I can't move into a solid tile.
		// If ignoreInvisible is true, pretend anything invisible doesn't exist.
		public function tileBlocked(loc:Point, ignoreInvisible:Boolean = false):Boolean {
			if (loc.equals(me.location)) {
				return false;
			}
			var room:Room = me.room;
			if (!(me.solidness & Prop.SOLID)) {
				return (loc.x < 0 || loc.x >= room.size.x || loc.y < 0 || loc.y >= room.size.y)
			}
			return (room.solidness(loc.x, loc.y, ignoreInvisible) & Prop.SOLID) != 0;
		}
		
		// step is a one-tile vector. Return from+step if legal, null if not
		// If ignoreInvisible is true, pretend anything invisible doesn't exist.
		public function checkBlockage(from:Point, step:Point, ignoreInvisible:Boolean = false):Point {
			var target:Point = from.add(step);
			if (tileBlocked(target, ignoreInvisible)) {
				return null;
			}
			if (!(me.solidness & Prop.SOLID)) { // if I'm ghost/hologram then hard corners don't bother me
				return target;
			}
			if (step.x == 0 || step.y == 0) { // if move isn't diagonal then hard corners are irrelevant
				return target;
			}
			if ( (me.room.solidness(from.x, from.y + step.y, ignoreInvisible) & Prop.HARD_CORNER) &&
				 (me.room.solidness(from.x + step.x, from.y, ignoreInvisible) & Prop.HARD_CORNER) ) {
				return null;
			}
			return target;
		}
		
		private function scrollRoomToKeepPlayerWithinBox(distanceFromEdge:int):void {
			var xOffset:int = 0;
			var yOffset:int = 0;
			var adjustedBox:Rectangle = new Rectangle(0, 0, Settings.STAGE_WIDTH, Settings.STAGE_HEIGHT);
			adjustedBox.inflate( -distanceFromEdge, -distanceFromEdge);
			adjustedBox.offset(-me.room.x, -me.room.y);
			if (me.x < adjustedBox.x) {
				xOffset = adjustedBox.x - me.x;
			}
			if (me.x + me.width > adjustedBox.right) {
				xOffset = adjustedBox.right - me.x - me.width;
			}
			if (me.y < adjustedBox.y) {
				yOffset = adjustedBox.y - me.y;
			}
			if (me.y + me.height > adjustedBox.bottom) {
				yOffset = adjustedBox.bottom - me.y - me.height;
			}

			me.room.x += xOffset;
			me.room.y += yOffset;
		}
		
		
		
	}

}