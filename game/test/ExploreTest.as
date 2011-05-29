package angel.game.test {
	import angel.game.brain.UtilBrain;
	import angel.game.ComplexEntity;
	import angel.game.event.QEvent;
	import angel.game.Room;
	import angel.game.RoomExplore;
	import angel.game.Settings;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ExploreTest {
		private static const CHAR_ID:String = "xxTestChar";
		private var testChar:ComplexEntity;
		
		public function ExploreTest() {
			Autotest.setupTestRoom();
			Autotest.testRoom.changeModeTo(RoomExplore);
			Autotest.assertTrue(Autotest.testRoom.mode is RoomExplore, "Change to Explore failed or delayed");
			Autotest.assertNoAlert();
			testChar = new ComplexEntity(Settings.catalog.retrieveCharacterResource(CHAR_ID), CHAR_ID);
			Autotest.clearAlert();
			
			//Tests go here
			Autotest.testFunction(moveOneSquare);
			
			Autotest.cleanupTestRoom();
		}
		
		private function moveOneSquare():void {
			var room:Room = Autotest.testRoom;
			
			room.addOrMoveSpot("dest", new Point(6, 6));
			testChar.exploreBrainClass = UtilBrain.exploreBrainClassFromString("patrol");
			testChar.exploreBrainParam = "dest";
			room.addEntity(testChar, new Point(5, 5));
			Autotest.assertEqual(room.entityInRoomWithId(CHAR_ID), testChar);
			Autotest.assertTrue(testChar.location.equals(new Point(5, 5)));
			for (var i:int = 0; i < Settings.FRAMES_PER_SECOND; ++i) {
				Settings.gameEventQueue.dispatch(new QEvent(room.parent, Room.GAME_ENTER_FRAME));
				Settings.gameEventQueue.handleEvents();
				if (i == 0) {
					Autotest.assertTrue(testChar.movement.moving(), "Char should be mid-movement");
				}
			}
			Autotest.assertFalse(testChar.movement.moving(), "Movement should be finished by now");
			Autotest.assertTrue(testChar.location.equals(new Point(6,6)), "Char should have walked to dest");
		}
		
	}

}