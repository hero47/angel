package angel.game.test {
	import angel.game.Flags;
	import angel.game.Room;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class FlagTest {
		
		public function FlagTest() {
			basicFlagTest();
			numericFlagTest();
			
			var testRoom:Room = Autotest.setupTestRoom();			
			entityFlagTest();		
			Autotest.cleanupTestRoom();
		}
		
		
		private function basicFlagTest():void {
			var value:Boolean = Boolean(Flags.getValue("xxTest"));
			Autotest.assertNoAlert("We no longer require flags to be declared in a separate file.");
			Autotest.assertFalse(value, "Default flag value is false");
			
			Flags.setValue("xxTest", 0);
			Autotest.assertFalse(Boolean(Flags.getValue("xxTest")), "Set to false, so should return false now");
			Flags.setValue("xxTest", 1);
			Autotest.assertTrue(Boolean(Flags.getValue("xxTest")), "Set to true, so should return true now");
			Flags.setValue("xxTest", 0);
			
			Flags.setValue("", 1);
			Autotest.assertAlertText("Error: empty flag id");
			value = Boolean(Flags.getValue(""));
			Autotest.assertAlertText("Error: empty flag id");
			Autotest.assertFalse(value, "Empty flag id should always return false");	
		}
		
		private function numericFlagTest():void {
			var value:int = Flags.getValue("xxTest2");
			Autotest.assertNoAlert("We no longer require flags to be declared in a separate file.");
			Autotest.assertEqual(value, 0, "Default flag value is 0");
			
			Flags.setValue("xxTest2", 1);
			Autotest.assertEqual(Flags.getValue("xxTest2"), 1, "Set to 1, so should return 1 now");
			Flags.setValue("xxTest2", 2);
			Autotest.assertEqual(Flags.getValue("xxTest2"), 2, "Set to 2, so should return 2 now");
			Flags.setValue("xxTest2", 0);
			Autotest.assertEqual(Flags.getValue("xxTest2"), 0, "Set to 0, so should return 0 now");
		}
		
		private function entityFlagTest():void {
			var badEntityId:String = "shouldNotBeInCatalog";
			Autotest.assertEqual(Settings.catalog.entry(badEntityId), null);
			Flags.getValue("xxTest@shouldNotBeInCatalog");
			Autotest.assertAlertText("Error: no catalog entry shouldNotBeInCatalog for flag xxTest@shouldNotBeInCatalog");
			
			Flags.getValue("xxTest@" + Autotest.TEST_ROOM_MAIN_PC_ID);
			Autotest.assertNoAlert("Reference to flag on good entity id should work");
		}
		
		
	}

}