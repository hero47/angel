package angel.game.brain {
	import angel.common.Alert;
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
	public class CombatBrainPatrol extends CombatBrainUiMeld {
		private var goals:Vector.<Point>;
		private var currentGoalIndex:int = 0;
		
		public function CombatBrainPatrol(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat);
			gait = 1;
			if ((param != null) && (param != "")) {
				var splitParam:Array = param.split(":");
				var route:String;
				if (splitParam.length == 1) {
					route = param;
				} else {
					gait = int(splitParam[0]);
					route = splitParam[1];
					if (splitParam.length > 2) {
						Alert.show("Extra : in route for " + entity.id);
					}
				}
				goals = UtilBrain.pointsFromCommaSeparatedSpots(entity.room, route, " in route for " + entity.id);
			}
			
		}
		
		/* INTERFACE angel.game.brain.ICombatBrain */
		
		override public function chooseMoveAndDrawDots():void {
			trace(me.aaId, "Patrol: Choose move and draw dots");
			if (!me.canMove() || shouldStop()) {
				//If we can't move, or have a gun and a target in sight, just stand still and shoot for max damage.
				return;
			}
			if (me.location.equals(goals[currentGoalIndex])) {
				currentGoalIndex = (currentGoalIndex + 1) % goals.length;
			}
			var path:Vector.<Point> = me.movement.findPathTo(goals[currentGoalIndex]);
			var maxDistance:int = me.movement.maxDistanceForGait(gait); // get this each time in case something changed my movement points
			if (path.length > maxDistance) {
				path.length = maxDistance;
			}
			
			trace(me.aaId, "next goal", goals[currentGoalIndex], "chose path:", path);
			if (path != null) {
				var gaitNeeded:int = combat.mover.extendPath(me, path);
				Assert.assertTrue(gaitNeeded <= gait, "path didn't match planned gait");
			}
			
		}
		
		override public function doFire():void {
			trace(me.aaId, "do fire (CombatBrainPatrol)");
			beginFireGunOrReserve(me, UtilBrain.getFirstAvailableTarget(me, combat));
		}
		
		protected function shouldStop():Boolean {
			return UtilBrain.canShoot(me, combat);
		}
		
	}

}