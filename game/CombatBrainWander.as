package angel.game {
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainWander {
		private var me:Entity;
		private var roomCombat:RoomCombat;
		
		public function CombatBrainWander(entity:Entity, roomCombat:RoomCombat) {
			me = entity;
			this.roomCombat = roomCombat;
		}
		
		public function chooseMoveAndDrawDots():void {
			trace(me.aaId, "Choose move and draw dots");
			var goal:Point = new Point(Math.floor(Math.random() * 10), Math.floor(Math.random() * 10));
			
			var path:Vector.<Point> = me.findPathTo(goal);
			trace(me.aaId, "chose path:", path);
			if (path != null) {
				roomCombat.extendPath(path);
			}
		}
		
		public function doMove():void {
			trace(me.aaId, "do move");
			roomCombat.startEntityFollowingPath(me, Entity.GAIT_WALK);
		}
		
	}

}