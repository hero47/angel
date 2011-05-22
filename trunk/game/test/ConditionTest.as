package angel.game.test {
	import angel.game.action.Condition;
	import angel.game.action.ICondition;
	import angel.game.Flags;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConditionTest {
		
		public function ConditionTest() {
			Autotest.testFunction(testFlagCondition);
		}
		
		private static const flagCondition:XML = <foo><flag param="xxTest" /></foo>;
		private static const notFlagCondition:XML = <foo><notFlag param="xxTest" /></foo>;
		private static const flagMissingParam:XML = <foo><flag /></foo>;
		private function testFlagCondition():void {
			Autotest.assertFalse(Flags.getValue("xxTest"));
			Autotest.clearAlert();
			
			var flag:ICondition = Condition.createFromEnclosingXml(flagCondition);
			Autotest.assertNotEqual(flag, null, "failed to create flag condition");
			var notFlag:ICondition = Condition.createFromEnclosingXml(notFlagCondition);
			Autotest.assertNotEqual(notFlag, null, "failed to create notFlag condition");
			
			Autotest.assertFalse(flag.isMet(), "flag is false, regular");
			Autotest.assertTrue(notFlag.isMet(), "flag is false, invert");
			
			Flags.setValue("xxTest", true);
			Autotest.assertTrue(flag.isMet(), "flag is true, regular");
			Autotest.assertFalse(notFlag.isMet(), "flag is true, invert");
			
			Autotest.assertEqual(Condition.createFromEnclosingXml(flagMissingParam), null, "should fail to create");
			Autotest.assertAlertText("Error! 'flag' condition requires param.");
		}
		
	}

}