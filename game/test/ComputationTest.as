package angel.game.test {
	import angel.common.Util;
	import angel.game.action.Computation;
	import angel.game.action.IComputation;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ComputationTest {
		
		private var context:ScriptContext;
		
		public function ComputationTest() {
			Autotest.testFunction(testConstantComputation);
			
			Autotest.setupTestRoom();
			context = new ScriptContext(Autotest.testRoom);
			Autotest.testFunction(testHealthComputation);
			Autotest.testFunction(testDistanceComputation);
			Autotest.cleanupTestRoom();
		}
		
		private function testConstantComputation():void {
			var five:IComputation = Computation.createFromXml(<left int="5" />);
			Autotest.assertEqual(five.value(context), 5);
		}
		
		private function testHealthComputation():void {
			var compXml:XML = <left />;
			compXml.@health = Autotest.TEST_ROOM_MAIN_PC_ID;
			var health:IComputation = Computation.createFromXml(compXml);
			Autotest.assertEqual(health.value(context), Autotest.testRoom.mainPlayerCharacter.currentHealth);
			Autotest.assertNoAlert();
			
			compXml.@health = "abcde";
			health = Computation.createFromXml(compXml);
			Autotest.assertNoAlert();
			Autotest.assertEqual(health.value(context), 0);
			Autotest.assertAlertText("Error! No character abcde in current room.", "Bad id should give error");
		}
		
		private function testDistanceComputation():void {
			var compXml:XML = <left />;
			compXml.@distance = Autotest.TEST_ROOM_MAIN_PC_ID + "," + Autotest.TEST_ROOM_ENEMY_ID;
			var trueDistance:int = Util.chessDistance(Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_MAIN_PC_ID).location,
				Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_ENEMY_ID).location);
			Autotest.assertNotEqual(trueDistance, 0, "Test room shouldn't put pc and enemy on same spot");
			var distance:IComputation = Computation.createFromXml(compXml);
			Autotest.assertEqual(distance.value(context), trueDistance, "Computation should return same distance value");
			
			compXml.@distance = "abcde";
			distance = Computation.createFromXml(compXml);
			Autotest.assertAlertText("Script error! Distance requires 'id,id' param.", "Create without comma in param should give error");
			Autotest.assertEqual(distance.value(context), 0, "Missing ids should give error and value 0");
			Autotest.assertAlerted();
			
			compXml.@distance = Autotest.TEST_ROOM_MAIN_PC_ID + "," + "abcde";
			distance = Computation.createFromXml(compXml);
			Autotest.assertEqual(distance.value(context), 0, "Missing ids should give error and value 0");
			Autotest.assertAlertText("Error! No character abcde in current room.", "Bad id should give error");
		}
		
	}

}