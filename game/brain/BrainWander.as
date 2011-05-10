package angel.game.brain {
	import angel.common.Assert;
	import angel.game.ComplexEntity;
	import angel.game.RoomExplore;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	/* The NPC should move, no more than one space, intermittently, in a random direction.
	 * At this point, no more than one space at a time; no more than twice in a row; with 
	 * a wait of a second between chances to move; and no more than ¼ of the time will they move."
	 */
	
	public class BrainWander implements IBrain {
		private var me:ComplexEntity;
		
		public function BrainWander(entity:ComplexEntity, roomExplore:RoomExplore, param:String) {
			me = entity;
			// Set the first twitch opportunity to a random fraction of a second, so all the NPCs in
			// the room aren't acting in unison.
			// This is not a listener; it will automatically go away when room explore mode ends
			roomExplore.addTimedEvent(Math.random(), twitchOpportunity);
		}
		
		public function cleanup():void {
			Assert.assertTrue(me.room.mode is RoomExplore, "Explore brain not in explore mode");
			RoomExplore(me.room.mode).removeTimedEvent(twitchOpportunity);
			me = null;
		}

		private function twitchOpportunity(roomExplore:RoomExplore):void {
			var wait:Number = 1;
			if (Math.random() < 0.25) {
				var goal:Point = chooseVacantNeighbor();
				if (goal != null) {
					me.startMovingToward(goal);
					wait = 2;
				}
			}
			roomExplore.addTimedEvent(wait, twitchOpportunity);
		}
	
		// We want to give equal chance to each vacant neighbor rather than favoring those adjacent to a blocked
		// neighbor, so make a list of all valid choices and pick one randomly from that list.
		private function chooseVacantNeighbor():Point {
			var facing:int;
			var choices:Vector.<Point> = new Vector.<Point>;
			for (facing = 0; facing < 8; ++facing) {
				var goal:Point = me.location.add(ComplexEntity.facingToNeighbor[facing]);
				if (!me.tileBlocked(goal)) {
					choices.push(goal);
				}
			}
			if (choices.length == 0) {
				return null;
			}
			return choices[Math.floor(Math.random() * choices.length)];
		}
		
	} // end class BrainWander

}