package angel.game {
	import angel.common.Assert;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainWander {
		private var me:Entity;
		private var combat:RoomCombat;
		private var gait:int;
		
		// reachable[gait] will hold all points reachable by moving at that gait
		private var reachable:Vector.<Vector.<Point>> = new Vector.<Vector.<Point>>();
		
		public function CombatBrainWander(entity:Entity, combat:RoomCombat) {
			me = entity;
			this.combat = combat;
			for (var i:int = 0; i <= Entity.GAIT_SPRINT; ++i) {
				reachable.push(new Vector.<Point>());
			}
		}
		
		public function chooseMoveAndDrawDots():void {
			trace(me.aaId, "Choose move and draw dots");
			
			var tiles:int = fillListWithReachableTiles();
			if (tiles == 0) {
				return;
			}
			var randomGait:int;
			do {
				randomGait = Math.floor(Math.random() * Entity.GAIT_SPRINT) + 1;
			} while (reachable[randomGait].length == 0);
			var goal:Point = reachable[randomGait][Math.floor(Math.random() * reachable[randomGait].length)];
			
			var path:Vector.<Point> = me.findPathTo(goal);
			trace(me.aaId, "chose path:", path);
			if (path != null) {
				gait = combat.extendPath(me, path);
				Assert.assertTrue(gait == randomGait, "path didn't match planned gait");
			}
		}
		
		public function doMove():void {
			trace(me.aaId, "do move");
			combat.startEntityFollowingPath(me, gait);
		}
		
		public function doFire():void {
			trace(me.aaId, "do fire");
			if (combat.lineOfSight(me, combat.room.playerCharacter.location)) {
				combat.fireAndAdvanceToNextPhase(me, combat.room.playerCharacter);
			} else {
				combat.fireAndAdvanceToNextPhase(me, null);
			}
			
		}
		
		// return total number of reachable tiles
		private function fillListWithReachableTiles():int {
			for (var i:int = 0; i <= Entity.GAIT_SPRINT; ++i) {
				reachable[i].length = 0;
			}
			var count:int = 0;
			var steps:Vector.<Vector.<int>> = me.findReachableTiles(me.location, me.gaitSpeeds[Entity.GAIT_SPRINT]);
			for (var x:int = 0; x < combat.room.size.x; ++x) {
				for (var y:int = 0; y < combat.room.size.y; ++y) {
					if (steps[x][y] > 0) {
						reachable[me.gaitForDistance(steps[x][y] - 1)].push(new Point(x, y));
						++count;
					}
				}
			}
			return count;
		}
		
	}

}