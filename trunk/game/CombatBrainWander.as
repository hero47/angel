package angel.game {
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatBrainWander {
		private var me:Entity;
		private var combat:RoomCombat;
		private var gait:int;
		
		public function CombatBrainWander(entity:Entity, combat:RoomCombat) {
			me = entity;
			this.combat = combat;
		}
		
		public function chooseMoveAndDrawDots():void {
			trace(me.aaId, "Choose move and draw dots");
			var goal:Point = new Point(Math.floor(Math.random() * 10), Math.floor(Math.random() * 10));
			
			gait = Entity.GAIT_UNSPECIFIED;
			var path:Vector.<Point> = me.findPathTo(goal);
			trace(me.aaId, "chose path:", path);
			if (path != null) {
				gait = combat.extendPath(me, path);
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
		
	}

}