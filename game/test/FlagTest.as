package angel.game.test {
	import angel.game.Flags;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class FlagTest {
		
		public function FlagTest() {
			var value:Boolean = Flags.getValue("xxTest");
			Autotest.assertAlertText("Warning: unknown flag [xxTest].", "This test should be run before any others that use flags!");
			Autotest.assertFalse(value, "Default flag value is false");
			value = Flags.getValue("xxTest");
			Autotest.assertNoAlert("Second reference should not alert");
			
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
			
			
		}
		
	}

}