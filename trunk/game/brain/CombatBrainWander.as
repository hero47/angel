package angel.game.brain {
	import angel.common.Assert;
	import angel.common.Util;
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.EntityMovement;
	import angel.game.Pathfinder;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainWander implements ICombatBrain {
		private var me:ComplexEntity;
		private var combat:RoomCombat;
		private var gait:int;
		
		// reachable[gait] will hold all points reachable by moving at that gait
		private var reachable:Vector.<Vector.<Point>> = new Vector.<Vector.<Point>>();
		
		public function CombatBrainWander(entity:ComplexEntity, combat:RoomCombat, param:String) {
			me = entity;
			this.combat = combat;
			for (var i:int = 0; i <= EntityMovement.GAIT_SPRINT; ++i) {
				reachable.push(new Vector.<Point>());
			}
		}
		
		public function cleanup():void {
			me = null;
		}

		
		public function chooseMoveAndDrawDots():void {
			if (!me.canMove()) {
				return;
			}
			trace(me.aaId, "Wander: Choose move and draw dots");
			
			var tiles:int = fillListWithReachableTiles();
			if (tiles == 0) {
				return;
			}
			var randomGait:int;
			do {
				randomGait = Math.floor(Math.random() * me.movement.maxGait) + 1;
			} while (reachable[randomGait].length == 0);
			var goal:Point = reachable[randomGait][Math.floor(Math.random() * reachable[randomGait].length)];
			
			var path:Vector.<Point> = me.movement.findPathTo(goal);
			trace(me.aaId, "chose path:", path);
			if (path != null) {
				gait = combat.mover.extendPath(me, path);
				Assert.assertTrue(gait == randomGait, "path didn't match planned gait");
			}
		}
		
		public function doMove():void {
			trace(me.aaId, "do move");
			//CONSIDER: can we skip this if !me.canMove(), or is it needed for turn phase flow? I think it's needed.
			combat.mover.startEntityFollowingPath(me, gait);
		}
		
		public function doFire():void {
			trace(me.aaId, "do fire (CombatBrainWander)");
			UtilBrain.fireAtFirstAvailableTarget(me, combat);
		}
		
		// return total number of reachable tiles
		private function fillListWithReachableTiles():int {
			for (var i:int = 0; i <= me.movement.maxGait; ++i) {
				reachable[i].length = 0;
			}
			var count:int = 0;
			var steps:Vector.<Vector.<int>> = Pathfinder.findReachableTiles(me, me.movement.maxDistanceForGait());
			for (var x:int = 0; x < combat.room.size.x; ++x) {
				for (var y:int = 0; y < combat.room.size.y; ++y) {
					if (steps[x][y] > 0) {
						reachable[me.movement.minGaitForDistance(steps[x][y] - 1)].push(new Point(x, y));
						++count;
					}
				}
			}
			return count;
		}
		
	}

}