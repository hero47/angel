package angel.game.brain {
	import angel.common.Assert;
	import angel.game.ComplexEntity;
	import angel.game.RoomExplore;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Follow routine for non-main-character PCs in explore mode. Thrown together just to see how it looks.
	// Every INTERVAL seconds (starting at random interval so they don't all move at the same time) pc will check
	// whether it's standing next to the character it's trying to follow, and if not, try to move to a spot that is.
	// Of course, the other character may move again while this one is catching up.
	 
	public class BrainFollow implements IBrain {
		private var me:ComplexEntity;
		
		private static const INTERVAL:int = 2;
		
		public function BrainFollow(entity:ComplexEntity, roomExplore:RoomExplore) {
			me = entity;
			roomExplore.addTimedEvent(Math.random()*INTERVAL, twitchOpportunity);
		}
		
		public function cleanup():void {
			Assert.assertTrue(me.room.mode is RoomExplore, "Explore brain not in explore mode");
			RoomExplore(me.room.mode).removeTimedEvent(twitchOpportunity);
			me = null;
		}

		private function twitchOpportunity(roomExplore:RoomExplore):void {
			if ((me.bestFriend != null) && !me.moving) {
				var path:Vector.<Point> = me.findPathTo(me.bestFriend.location);
				if ((path != null) && (path.length > 1)) {
					path.length = path.length - 1;
					me.startMovingAlongPath(path);
				}
			}
			roomExplore.addTimedEvent(INTERVAL, twitchOpportunity);
		}
		
		
	}

}