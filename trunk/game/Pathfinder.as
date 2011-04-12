package angel.game {
	import angel.common.Assert;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Pathfinder {
		
		public function Pathfinder() {
			
		}
		
		// check neighbor tiles in this order when choosing path, so we'll prefer "straight" moves
		private static const neighborCheck:Vector.<Point> = Vector.<Point>([
				new Point(1, 0), new Point(0, 1), new Point(0, -1), new Point( -1, 0),
				new Point(1, 1), new Point(1, -1), new Point( -1, -1), new Point( -1, 1)
			]);
		
		// Fill in path.  Return false if there is no path.
		// NOTE: Does not check whether the goal tile itself is blocked!
		public static function findShortestPathTo(entity:ComplexEntity, from:Point, goal:Point, path:Vector.<Point>):Boolean {
			var room:Room = entity.room;
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
					
					var neighbor:Point = entity.checkBlockage(current, stepToNextNeighbor);
					if (neighbor == null) {
						if (entity.tileBlocked(new Point(xNext, yNext))) {
							steps[xNext][yNext] = -1;
						}
					} else {
						steps[xNext][yNext] = stepsFromGoal;
						edge.push(neighbor);
					
						if ((xNext == from.x) && (yNext == from.y)) {
							extractPathFromStepGrid(entity, from, goal, steps, path);
							//trace(path);
							return true;
						}
					}
				}

			} // end while edge.length > 0
			//trace("tile", goal, "unreachable");
			return false;
		}
		
		private static function extractPathFromStepGrid(entity:ComplexEntity, from:Point, goal:Point, steps:Vector.<Vector.<int>>, path:Vector.<Point>):void {
			//traceStepGrid(steps);
			path.length = 0;
			var current:Point = from.clone();
			var lookingFor:int = steps[current.x][current.y] - 1;
			while (lookingFor > 1) {
				for (var i:int = 0; i < neighborCheck.length; i++) {
					var stepToNextNeighbor:Point = neighborCheck[i];
					var xNext:int = current.x + stepToNextNeighbor.x;
					var yNext:int = current.y + stepToNextNeighbor.y;
					if ((xNext < 0) || (xNext >= steps.length) || (yNext < 0) || (yNext >= steps[0].length)) {
						continue;
					}
					if (steps[xNext][yNext] == lookingFor) {
						var neighbor:Point = entity.checkBlockage(current, stepToNextNeighbor);
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
		
		private static function traceStepGrid(steps:Vector.<Vector.<int>>):void {
			trace("Grid:");
			for (var y:int = 0; y < steps[0].length; ++y) {
				var foo:String = "";
				for (var x:int = 0; x < steps.length; ++x) {
					foo += (steps[x][y] == -1 ? "X" : String(steps[x][y]));
				}
				trace(foo);
			}
		}
		
		// Fill a grid with the number of steps to all reachable points within a given range
		// (Used by NPC brains when choosing move)
		// Mostly matches findShortestPathTo(), just different enough to make them tough to merge ;)
		public static function findReachableTiles(entity:ComplexEntity):Vector.<Vector.<int>> {
			var room:Room = entity.room;
			var from:Point = entity.location;
			var range:int = entity.combatMovePoints;
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
					
					var neighbor:Point = entity.checkBlockage(current, stepToNextNeighbor);
					if (neighbor == null) {
						if (entity.tileBlocked(new Point(xNext, yNext))) {
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
		
		
	}

}