package angel.game.combat {
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.EntityMovement;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	/* Standard movement - move points, distance divided into walk, run, sprint ranges by percentages in Settings */
	
	public class CombatMover {
		
		// public because they're accessed by the CombatMoveUi and/or entity combat brains
		private var dots:Vector.<Shape> = new Vector.<Shape>(); // The dots on screen representing movement path
		private var endIndexes:Vector.<int> = new Vector.<int>(); // indexes into path[] marking segment ends (aka waypoints)
		private var path:Vector.<Point> = new Vector.<Point>(); // The tiles entity intends to move through, in sequence
																// NOTE: path does not include the starting tile.
		private var returnMarker:Shape;
		
		private var combat:RoomCombat;
		private var decorationsLayer:Sprite;
		
		private static const WALK_COLOR:uint = 0x00ff00;
		private static const RUN_COLOR:uint = 0xffd800;
		private static const SPRINT_COLOR:uint = 0xff0000;
		private static const OUT_OF_RANGE_COLOR:uint = 0x888888;
		private static const RETURN_COLOR:uint = 0xffffff;
		
		public function CombatMover(combat:RoomCombat) {
			this.combat = combat;
			decorationsLayer = combat.room.decorationsLayer;
		}
		
		/***** Dots -- drawn on screen to represent movement path:
		 *             * for players, as they are choosing move in ui; can be extended, un-extended, cleared, or committed
		 *             * for NPCs, displayed for a pause between NPC choosing move and carrying out that move
		 *               only visible on tiles that are in LOS of a player
		 *             * In both cases, removed from screen one dot at a time as the character moves along path
		 */
		
		// TAG tile-width-is-twice-height: dots will not have correct aspect if tiles no longer follow this rule!
		private static const DOT_X_RADIUS:int = 12;
		private static const DOT_Y_RADIUS:int = 6;
		private function dot(color:uint, center:Point, isEnd:Boolean = false):Shape {
			var dotShape:Shape = new Shape();
			if (isEnd) {
				dotShape.graphics.lineStyle(2, 0x0000ff)
			}
			dotShape.graphics.beginFill(color, 1);
			dotShape.graphics.drawEllipse(center.x - DOT_X_RADIUS, center.y - DOT_Y_RADIUS, DOT_X_RADIUS * 2, DOT_Y_RADIUS * 2);
			return dotShape;
		}
		
		private function splitDot(color1:uint, color2:uint, center:Point, isEnd:Boolean = false):Shape {
			var dotShape:Shape = new Shape();
			if (isEnd) {
				dotShape.graphics.lineStyle(2, 0x0000ff)
			}
			// TAG tile-width-is-twice-height: aspect will be off if tiles no longer follow this rule!
			dotShape.graphics.beginFill(color1, 1);
			Util.halfCircle(dotShape.graphics, center.x, center.y * 2, DOT_X_RADIUS, 90);
			dotShape.graphics.beginFill(color2, 1);
			Util.halfCircle(dotShape.graphics, center.x, center.y * 2, DOT_X_RADIUS, 270);
			dotShape.height /= 2;
			return dotShape;
		}
		
		public function clearDots():void {
			for (var i:int = 0; i < dots.length; i++) {
				decorationsLayer.removeChild(dots[i]);
			}
			dots.length = 0;
		}
		
		 //CONSIDER: should mover listen for move and do this in a listener rather than being called?
		public function adjustDisplayAsEntityLeavesATile():void {
			Assert.assertTrue(dots.length > 0, "adjustDisplayAsEntityLeavesATile with no dots remaining");
			var dotToRemove:Shape = dots.shift();
			decorationsLayer.removeChild(dotToRemove);
		}
		
		// Color of path dot, and of tile hilight that follows mouse in Move ui
		public static function colorForGait(gait:int):uint {
			switch (gait) {
				case EntityMovement.GAIT_NO_MOVE:
				case EntityMovement.GAIT_WALK:
					return WALK_COLOR;
				break;
				case EntityMovement.GAIT_RUN:
					return RUN_COLOR;
				break;
				case EntityMovement.GAIT_SPRINT:
					return SPRINT_COLOR;
				break;
			}
			return OUT_OF_RANGE_COLOR;
		}
		
		public function endOfCurrentPath():Point {
			return (path.length == 0 ? null : path[path.length - 1]);
		}
		
		public function dotColorIfExtendPathTo(entity:ComplexEntity, location:Point):uint {
			var distance:int = 1000;
			if (!entity.movement.tileBlocked(location, true) && (path.length < entity.movement.unusedMovePoints)) {
				var nextSegment:Vector.<Point> = entity.movement.findPathTo(location, endOfCurrentPath(), true );
				if (nextSegment != null) {
					distance = path.length + nextSegment.length;
				}
			}
			if (shootFromCoverValid(entity, distance)) {
				return RETURN_COLOR;
			}
			return colorForGait(entity.movement.minGaitForDistance(distance + entity.movement.usedMovePoints));
		}
		
		public function minimumGaitForPath(entity:ComplexEntity):int {
			return entity.movement.minGaitForDistance(path.length);
		}
		
		/******** Routines sharing elements of actual movement & visual elements **********/
		
		
		// Add a segment to the end of current path. Calculate minimum gait for this path; redraw movement dots
		// in that color (using entity's movement points/percentages to determine gait & color) and return gait.
		// If extension is null, just calculate gait, redraw movement dots in appropriate color, and return gait
		public function extendPath(entity:ComplexEntity, pathFromCurrentEndToNewEnd:Vector.<Point>):int {
			clearDots();
			if (pathFromCurrentEndToNewEnd != null) {
				path = path.concat(pathFromCurrentEndToNewEnd);
				endIndexes.push(path.length - 1);
			}
			dots.length = path.length;
			var endIndexIndex:int = 0;
			var gait:int = entity.movement.minGaitForDistance(path.length);
			for (var i:int = 0; i < path.length; i++) {
				var isEnd:Boolean = (i == endIndexes[endIndexIndex]);
				if (path.length == 1 && shootFromCoverValidForCurrentLocationAndPath(entity)) {
					dots[i] = splitDot(RETURN_COLOR, colorForGait(gait), Floor.centerOf(path[i]), isEnd );
				} else {
					dots[i] = dot(colorForGait(gait), Floor.centerOf(path[i]), isEnd );
				}
				decorationsLayer.addChild(dots[i]);
				if (isEnd) {
					++endIndexIndex;
				}
				if (!entity.isPlayerControlled && !combat.anyPlayerCanSeeLocation(path[i])) {
					// This makes me wince.  It works, but this whole movement dot thing is getting messier and uglier.
					dots[i].visible = false;
				}
			}
			return gait;
		}
		
		public function extendPathIfLegalMove(entity:ComplexEntity, location:Point):void {
			if (!entity.movement.tileBlocked(location, true)) {
				var currentEnd:Point = endOfCurrentPath();
				if ((currentEnd == null) || !location.equals(currentEnd)) {
					var nextSegment:Vector.<Point> = entity.movement.findPathTo(location, currentEnd, true);
					if ((nextSegment != null) && (path.length + nextSegment.length + entity.movement.usedMovePoints <= 
										entity.movement.maxDistanceForGait())) {
						extendPath(entity, nextSegment);
					}
				}
			}
		}
		
		public function clearPath():void {
			clearDots();
			path.length = 0;
			removeReturnMarker();
		}
		
		public function removeLastPathSegment(entity:ComplexEntity):void {
			if (path.length > 0) {
				endIndexes.pop();
				var ends:int = endIndexes.length;
				path.length = (ends == 0 ? 0 : endIndexes[ends - 1] + 1);
				extendPath(entity, null); // clear dots; redraw the ones that should still be there in appropriate color for current length
			}
		}
		
		public function displayReturnMarker(location:Point):void {
			returnMarker = dot(RETURN_COLOR, Floor.centerOf(location));
			decorationsLayer.addChild(returnMarker);
		}
		
		public function removeReturnMarker():void {
			if (returnMarker != null) {
				decorationsLayer.removeChild(returnMarker);
				returnMarker = null;
			}
		}
		
		/******** Actual movement routines, separate from the visual elements *************/
		
		public function unusedMovePoints(entity:ComplexEntity):int {
			return entity.movement.unusedMovePoints - path.length;
		}
		
		public function hasPath():Boolean {
			return path.length > 0;
		}
		
		public function startEntityFollowingPath(entity:ComplexEntity, gait:int):void {
			Assert.assertTrue(gait >= minimumGaitForPath(entity), "Bad gait for this path");
			entity.movement.startMovingAlongPath(path, gait); //CAUTION: this path now belongs to entity.movement!
			path = new Vector.<Point>();
			endIndexes.length = 0;
		}
		
		/*************** I don't know how to classify this or even if it belongs in this class ***************/
		
		public function shootFromCoverValid(entity:ComplexEntity, pathLength:int):Boolean {
			return ((pathLength == 1) && !entity.movement.gaitIsRestricted() && entity.hasCover());
		}
		
		public function shootFromCoverValidForCurrentLocationAndPath(entity:ComplexEntity):Boolean {
			return shootFromCoverValid(entity, path.length);
		}
		
	} // end class CombatMover

}