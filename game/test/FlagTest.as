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
			var value:Boolean = Flags.getValue("xxTest");
			Autotest.assertNoAlert("We no longer require flags to be declared in a separate file.");
			Autotest.assertFalse(value, "Default flag value is false");
			value = Flags.getValue("xxTest");
			
			Flags.setValue("xxTest", false);
			Autotest.assertFalse(Flags.getValue("xxTest"), "Set to false, so should return false now");
			Flags.setValue("xxTest", true);
			Autotest.assertTrue(Flags.getValue("xxTest"), "Set to true, so should return true now");
			Flags.setValue("xxTest", false);
			
			Flags.setValue("", true);
			Autotest.assertAlertText("Error: empty flag id");
			value = Flags.getValue("");
			Autotest.assertAlertText("Error: empty flag id");
			Autotest.assertFalse(value, "Empty flag id should always return false");
			
			var testRoom:Room = Autotest.setupTestRoom();
			
			var badEntityId:String = "shouldNotBeInCatalog";
			Autotest.assertEqual(Settings.catalog.entry(badEntityId), null);
			Flags.getValue("xxTest@shouldNotBeInCatalog");
			Autotest.assertAlertText("Error: no catalog entry shouldNotBeInCatalog for flag xxTest@shouldNotBeInCatalog");
			
			Flags.getValue("xxTest@" + Autotest.TEST_ROOM_MAIN_PC_ID);
			Autotest.assertNoAlert("Reference to flag on good entity id should work");
			
			Autotest.cleanupTestRoom();
		}
		
	}

}