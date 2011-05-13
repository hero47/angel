package angel.game.brain {
	import angel.common.Assert;
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	 // NOTE: this is NOT directly a combat brain. It doesn't have the right constructor signature.
	 // Rather, it is the guts for the different movement speed versions of combat patrol.
	public class CombatBrainPatrol implements ICombatBrain {
		private var me:ComplexEntity;
		private var combat:RoomCombat;
		private var gait:int;
		private var goals:Vector.<Point>;
		private var currentGoalIndex:int = 0;
		
		public function CombatBrainPatrol(entity:ComplexEntity, combat:RoomCombat, param:String, gait:int) {
			me = entity;
			this.combat = combat;
			this.gait = gait;
			if ((param != null) && (param != "")) {
				goals = UtilBrain.pointsFromCommaSeparatedSpots(entity.room, param, " in combat patrol route for " + entity.id);
			}
			
		}
		
		/* INTERFACE angel.game.brain.ICombatBrain */
		
		public function chooseMoveAndDrawDots():void {
			trace(me.aaId, "Patrol: Choose move and draw dots");
			if (UtilBrain.getFirstAvailableTarget(me, combat) != null) {
				//If we have a target in sight, just stand still and shoot for max damage.
				return;
			}
			if (me.location.equals(goals[currentGoalIndex])) {
				currentGoalIndex = (currentGoalIndex + 1) % goals.length;
			}
			var path:Vector.<Point> = me.findPathTo(goals[currentGoalIndex]);
			var maxDistance:int = me.maxDistanceForGait[gait]; // get this each time in case something changed my movement points
			if (path.length > maxDistance) {
				path.length = maxDistance;
			}
			
			trace(me.aaId, "next goal", goals[currentGoalIndex], "chose path:", path);
			if (path != null) {
				var gaitNeeded:int = combat.mover.extendPath(me, path);
				Assert.assertTrue(gaitNeeded <= gait, "path didn't match planned gait");
			}
			
		}
		
		public function doMove():void {
			trace(me.aaId, "do move");
			combat.mover.startEntityFollowingPath(me, gait);		
		}
		
		public function doFire():void {
			trace(me.aaId, "do fire (CombatBrainPatrol)");
			UtilBrain.fireAtFirstAvailableTarget(me, combat);
		}
		
		public function cleanup():void {
			me = null;
		}
		
	}

}