package angel.game {
	import angel.common.Assert;
	import angel.common.Floor;
	import flash.display.Shape;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	/* Standard movement - move points, distance divided into walk, run, sprint ranges by percentages in Settings */
	
	public class CombatMover {
		private var entity:ComplexEntity;
		
		// public because they're accessed by the CombatMoveUi and/or entity combat brains
		public var dots:Vector.<Shape> = new Vector.<Shape>(); // The dots on screen representing movement path
		public var endIndexes:Vector.<int> = new Vector.<int>(); // indexes into path[] marking segment ends (aka waypoints)
		public var path:Vector.<Point> = new Vector.<Point>(); // The tiles entity intends to move through, in sequence
		
		private static const WALK_COLOR:uint = 0x00ff00;
		private static const RUN_COLOR:uint = 0xffd800;
		private static const SPRINT_COLOR:uint = 0xff0000;
		private static const OUT_OF_RANGE_COLOR:uint = 0x888888;
		
		public function CombatMover(entity:ComplexEntity) {
			this.entity = entity;
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
		
		public function clearDots():void {
			for (var i:int = 0; i < dots.length; i++) {
				entity.room.decorationsLayer.removeChild(dots[i]);
			}
			dots.length = 0;
		}
		
		public function adjustDisplayAsEntityLeavesATile():void {
			Assert.assertTrue(dots.length > 0, "adjustDisplayAsEntityLeavesATile with no dots remaining");
			var dotToRemove:Shape = dots.shift();
			entity.room.decorationsLayer.removeChild(dotToRemove);
		}
		
		// Color of path dot, and of tile hilight that follows mouse in Move ui
		public static function colorForGait(gait:int):uint {
			switch (gait) {
				case ComplexEntity.GAIT_WALK:
					return WALK_COLOR;
				break;
				case ComplexEntity.GAIT_RUN:
					return RUN_COLOR;
				break;
				case ComplexEntity.GAIT_SPRINT:
					return SPRINT_COLOR;
				break;
			}
			return OUT_OF_RANGE_COLOR;
		}
		
		public function endOfCurrentPath():Point {
			return (path.length == 0 ? entity.location : path[path.length - 1]);
		}
		
		public function dotColorIfExtendPathTo(location:Point):uint {
			var distance:int = 1000;
			if (!entity.tileBlocked(location) && (path.length < entity.combatMovePoints)) {
				var nextSegment:Vector.<Point> = entity.findPathTo(location, endOfCurrentPath() );
				if (nextSegment != null) {
					distance = path.length + nextSegment.length;
				}
			}
			return colorForGait(gaitForDistance(distance));
		}
		
		public function minimumGaitForPath():int {
			return gaitForDistance(path.length);
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
		
		/******** Routines sharing elements of actual movement & visual elements **********/
		
		
		// Add a segment to the end of current path. Calculate minimum gait for this path; redraw movement dots
		// in that color (using entity's movement points/percentages to determine gait & color) and return gait.
		// If extension is null, just calculate gait, redraw movement dots in appropriate color, and return gait
		public function extendPath(pathFromCurrentEndToNewEnd:Vector.<Point>):int {
			clearDots();
			if (pathFromCurrentEndToNewEnd != null) {
				path = path.concat(pathFromCurrentEndToNewEnd);
				endIndexes.push(path.length - 1);
			}
			dots.length = path.length;
			var endIndexIndex:int = 0;
			var gait:int = gaitForDistance(path.length);
			for (var i:int = 0; i < path.length; i++) {
				var isEnd:Boolean = (i == endIndexes[endIndexIndex]);
				dots[i] = dot(colorForGait(gait), Floor.centerOf(path[i]), isEnd );
				entity.room.decorationsLayer.addChild(dots[i]);
				if (isEnd) {
					++endIndexIndex;
				}
				if (!entity.isPlayerControlled) {
					// This makes me wince.  It works, but this whole movement dot thing is getting messier and uglier.
					var combat:RoomCombat = RoomCombat(entity.room.mode);
					if (combat.losFromAnyPlayer(path[i])) {
						dots[i].visible = false;
					}
				}
			}
			return gait;
		}
		
		public function extendPathIfLegalMove(location:Point):void {
			if (!entity.tileBlocked(location)) {
				var currentEnd:Point = endOfCurrentPath();
				if (!location.equals(currentEnd)) {
					var nextSegment:Vector.<Point> = entity.findPathTo(location, currentEnd);
					if ((nextSegment != null) && (path.length + nextSegment.length <= entity.combatMovePoints)) {
						extendPath(nextSegment);
					}
				}
			}
		}
		
		public function clearPath():void {
			clearDots();
			path.length = 0;
		}
		
		public function removeLastPathSegment():void {
			if (path.length > 0) {
				endIndexes.pop();
				var ends:int = endIndexes.length;
				path.length = (ends == 0 ? 0 : endIndexes[ends - 1] + 1);
				extendPath(null); // clear dots; redraw the ones that should still be there in appropriate color for current length
			}
		}
		
		/******** Actual movement routines, separate from the visual elements *************/
		
		public function unusedMovePoints():int {
			return entity.combatMovePoints - path.length;
		}
		
		public function startEntityFollowingPath(gait:int):void {
			entity.startMovingAlongPath(path, gait); //CAUTION: this path now belongs to entity!
			path = new Vector.<Point>();
			endIndexes.length = 0;
		}
		
		
	} // end class CombatMover

}