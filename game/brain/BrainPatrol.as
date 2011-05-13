package angel.game.brain {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.game.ComplexEntity;
	import angel.game.EntityEvent;
	import angel.game.RoomExplore;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class BrainPatrol implements IBrain {
		private var me:ComplexEntity;
		private var goals:Vector.<Point>;
		private var currentGoalIndex:int = 0;
		
		private static const DELAY_AT_EACH_SPOT:int = 1;
		
		public function BrainPatrol(entity:ComplexEntity, roomExplore:RoomExplore, param:String) {
			me = entity;
			if ((param != null) && (param != "")) {
				goals = UtilBrain.pointsFromCommaSeparatedSpots(me.room, param, " in explore patrol route for " + entity.id);
				if (goals.length > 0) {
					me.addEventListener(EntityEvent.FINISHED_MOVING, finishedMovingListener);
					continuePatrol(roomExplore);
				}
			}
			
		}
		
		
		/* INTERFACE angel.game.brain.IBrain */
		
		public function cleanup():void {
			Assert.assertTrue(me.room.mode is RoomExplore, "Explore brain not in explore mode");
			RoomExplore(me.room.mode).removeTimedEvent(continuePatrol);
			me.removeEventListener(EntityEvent.FINISHED_MOVING, finishedMovingListener);
		}
		
		private function continuePatrol(roomExplore:RoomExplore):void {
			if (me.location.equals(goals[currentGoalIndex])) {
				currentGoalIndex = (currentGoalIndex + 1) % goals.length;
				roomExplore.addTimedEvent(DELAY_AT_EACH_SPOT, continuePatrol);
			} else {
				var path:Vector.<Point> = me.findPathTo(goals[currentGoalIndex]);
				if (path == null) {
					roomExplore.addTimedEvent(DELAY_AT_EACH_SPOT, continuePatrol);
				} else {
					me.startMovingAlongPath(path);
				}
			}
		}
		
		private function finishedMovingListener(event:EntityEvent):void {
			Assert.assertTrue(me.room.mode is RoomExplore, "Explore brain not in explore mode");
			RoomExplore(me.room.mode).addTimedEvent(DELAY_AT_EACH_SPOT, continuePatrol);
		}
		
	}

}