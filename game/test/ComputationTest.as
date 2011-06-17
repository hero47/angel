package angel.game.test {
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.script.computation.ComputationFactory;
	import angel.game.script.computation.IComputation;
	import angel.game.script.Script;
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
			context = new ScriptContext(Autotest.testRoom, Autotest.testRoom.activePlayer());
			Autotest.testFunction(testHealthComputation);
			Autotest.testFunction(testDistanceComputation);
			Autotest.testFunction(testActiveComputation);
			Autotest.cleanupTestRoom();
			
			Autotest.assertNoAlert();
		}
		
		private function testConstantComputation():void {
			var five:IComputation = ComputationFactory.createFromXml(<left int="5" />, Autotest.script);
			Autotest.assertEqual(five.value(context), 5);
		}
		
		private function testHealthComputation():void {
			var compXml:XML = <left />;
			compXml.@health = Autotest.TEST_ROOM_MAIN_PC_ID;
			var health:IComputation = ComputationFactory.createFromXml(compXml, Autotest.script);
			Autotest.assertEqual(health.value(context), Autotest.testRoom.mainPlayerCharacter.currentHealth);
			Autotest.assertNoAlert();
			
			compXml.@health = "abcde";
			health = ComputationFactory.createFromXml(compXml, Autotest.script);
			Autotest.assertNoAlert();
			Autotest.assertEqual(health.value(context), 0);
			Autotest.assertContextMessage(context, "Script error in health: No character 'abcde' in current room.", "Bad id should give error");
		}
		
		private function testDistanceComputation():void {
			var compXml:XML = <left />;
			compXml.@distance = Autotest.TEST_ROOM_MAIN_PC_ID + "," + Autotest.TEST_ROOM_ENEMY_ID;
			var trueDistance:int = Util.chessDistance(Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_MAIN_PC_ID).location,
				Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_ENEMY_ID).location);
			Autotest.assertNotEqual(trueDistance, 0, "Test room shouldn't put pc and enemy on same spot");
			var distance:IComputation = ComputationFactory.createFromXml(compXml, Autotest.script);
			Autotest.assertEqual(distance.value(context), trueDistance, "Computation should return same distance value");
			
			compXml.@distance = "abcde";
			distance = ComputationFactory.createFromXml(compXml, Autotest.script);
			Autotest.script.displayAndClearParseErrors();
			Autotest.script.initErrorList();
			Autotest.assertAlertText("Script errors:\ndistance requires 'id,id' param.", "Create without comma in param should give error");
			Autotest.assertEqual(distance.value(context), 0, "Missing ids should give error and value 0");
			Autotest.assertContextHadMessage(context);
			
			compXml.@distance = Autotest.TEST_ROOM_MAIN_PC_ID + "," + "abcde";
			distance = ComputationFactory.createFromXml(compXml, Autotest.script);
			Autotest.assertEqual(distance.value(context), 0, "Missing ids should give error and value 0");
			Autotest.assertContextMessage(context, "Script error in distance: No character 'abcde' in current room.", "Bad id should give error");
		}
		
		private function testActiveComputation():void {
			var active:IComputation;
			
			active = ComputationFactory.createFromXml(<left active="enemy" />, Autotest.script);
			Autotest.assertEqual(active.value(context), 1, "Test room has 1 enemy");
			ComplexEntity(Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_ENEMY_ID)).currentHealth = 0;
			Autotest.assertEqual(active.value(context), 0, "The only enemy is dead");
			ComplexEntity(Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_ENEMY_ID)).currentHealth = 1;
			
			active = ComputationFactory.createFromXml(<left active="friend" />, Autotest.script);
			Autotest.assertEqual(active.value(context), 1, "Test room has 1 friend(player)");
			ComplexEntity(Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_MAIN_PC_ID)).currentHealth = 0;
			Autotest.assertEqual(active.value(context), 0, "The only friend is dead");
			
			active = ComputationFactory.createFromXml(<left active="all" />, Autotest.script);
			Autotest.assertEqual(active.value(context), 1, "Only 1 character active in room");
			ComplexEntity(Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_MAIN_PC_ID)).currentHealth = 1;
			Autotest.assertEqual(active.value(context), 2, "Now both characters active");
		}
		
	}

}