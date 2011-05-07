package angel.game.brain {
	import angel.common.Assert;
	import angel.game.ComplexEntity;
	import angel.game.RoomExplore;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	/* "The NPC should be placed in the scene, facing in a random direction; they should then turn to face another
	 * direction, intermittently, in a random direction.  At this point, no more than twice in a row; with a wait
	 * of a second between chances to turn; and no more than ¼ of the time will they move."
	 */
	public class BrainFidget implements IBrain {
		private var me:ComplexEntity;
		
		public function BrainFidget(entity:ComplexEntity, roomExplore:RoomExplore) {
			me = entity;
			me.turnToFacing(Math.random() * 8);
			// Set the first twitch opportunity to a random fraction of a second, so all the NPCs in
			// the room aren't acting in unison.
			roomExplore.addTimedEvent(Math.random(), twitchOpportunity);
		}
		
		public function cleanup():void {
			Assert.assertTrue(me.room.mode is RoomExplore, "Explore brain not in explore mode");
			RoomExplore(me.room.mode).removeTimedEvent(twitchOpportunity);
			me = null;
		}

		private function twitchOpportunity(roomExplore:RoomExplore):void {
			if (Math.random() < 0.25) {
				me.turnToFacing(Math.random() * 8);
				roomExplore.addTimedEvent(2, twitchOpportunity);
			} else {
				roomExplore.addTimedEvent(1, twitchOpportunity);
			}
		}
		
		
	}

}