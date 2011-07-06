package angel.game.test {
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.Flags;
	import angel.game.script.condition.ActiveCondition;
	import angel.game.script.condition.AndCondition;
	import angel.game.script.condition.CompareCondition;
	import angel.game.script.condition.ConditionFactory;
	import angel.game.script.condition.ICondition;
	import angel.game.script.condition.OrCondition;
	import angel.game.script.condition.PcCondition;
	import angel.game.script.condition.SpotEmptyCondition;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConditionTest {
		private var context:ScriptContext;
		
		public function ConditionTest() {
			Autotest.setupTestRoom();
			context = new ScriptContext(Autotest.testRoom, Autotest.testRoom.activePlayer(), null, null);
			Autotest.testFunction(testFlagCondition);
			Autotest.testFunction(testMultipleCondition);
			Autotest.testFunction(testAllOfCondition);
			Autotest.testFunction(testAnyOfCondition);
			Autotest.testFunction(testCompareCondition);
			Autotest.testFunction(testSpotConditions);
			Autotest.testFunction(testActiveConditions);
			Autotest.testFunction(testPcConditions);
			Autotest.cleanupTestRoom();
		}
		
		private static const flagCondition:XML = <foo><flag param="xxTest" /></foo>;
		private static const notFlagCondition:XML = <foo><notFlag param="xxTest" /></foo>;
		private static const flagMissingParam:XML = <foo><flag /></foo>;
		private function testFlagCondition():void {
			Autotest.assertFalse(Flags.getValue("xxTest"));
			Autotest.clearAlert();
			
			var flag:ICondition = ConditionFactory.createFromEnclosingXml(flagCondition, Autotest.script);
			Autotest.assertNotEqual(flag, null, "failed to create flag condition");
			var notFlag:ICondition = ConditionFactory.createFromEnclosingXml(notFlagCondition, Autotest.script);
			Autotest.assertNotEqual(notFlag, null, "failed to create notFlag condition");
			
			Autotest.assertFalse(flag.isMet(context), "flag is false, regular");
			Autotest.assertTrue(notFlag.isMet(context), "flag is false, invert");
			
			Flags.setValue("xxTest", true);
			Autotest.assertTrue(flag.isMet(context), "flag is true, regular");
			Autotest.assertFalse(notFlag.isMet(context), "flag is true, invert");
			
			Autotest.assertEqual(ConditionFactory.createFromEnclosingXml(flagMissingParam, Autotest.script), null, "should fail to create");
			Autotest.script.displayAndClearParseErrors();
			Autotest.script.initErrorList();
			Autotest.assertAlertText("Script errors:\nflag condition requires param.");
			
			
			Flags.setValue("xxTest", false);
		}		
		
		private static const multipleCondition:XML = <foo>
			<flag param="xxTest" />
			<flag param="yyTest" />
		</foo>;
		private function testMultipleCondition():void {
			var shouldBeAnd:ICondition = ConditionFactory.createFromEnclosingXml(multipleCondition, Autotest.script);
			verifyAnd(shouldBeAnd, "xxTest", "yyTest", "Two or more individual conditions should produce an And");
		}
			
		private static const andCondition:XML = <foo>
			<allOf>
				<flag param="xxTest" />
				<flag param="yyTest" />
			</allOf>
		</foo>;
			
		private static const notAndCondition:XML = <foo>
			<notAllOf>
				<flag param="xxTest" />
				<flag param="yyTest" />
			</notAllOf>
		</foo>;
		private function testAllOfCondition():void {
			var shouldBeAnd:ICondition = ConditionFactory.createFromEnclosingXml(andCondition, Autotest.script);
			verifyAnd(shouldBeAnd, "xxTest", "yyTest", "allOf");
			var shouldBeNotAnd:ICondition = ConditionFactory.createFromEnclosingXml(notAndCondition, Autotest.script);
			verifyNotAnd(shouldBeNotAnd, "xxTest", "yyTest", "allOf");
		}
			
		private static const orCondition:XML = <foo>
			<anyOf>
				<flag param="xxTest" />
				<flag param="yyTest" />
			</anyOf>
		</foo>;
		private static const notOrCondition:XML = <foo>
			<notAnyOf>
				<flag param="xxTest" />
				<flag param="yyTest" />
			</notAnyOf>
		</foo>;
		private function testAnyOfCondition():void {
			var shouldBeOr:ICondition = ConditionFactory.createFromEnclosingXml(orCondition, Autotest.script);
			verifyOr(shouldBeOr, "xxTest", "yyTest", "anyOf");
			var shouldBeNotOr:ICondition = ConditionFactory.createFromEnclosingXml(notOrCondition, Autotest.script);
			verifyNotOr(shouldBeNotOr, "xxTest", "yyTest", "anyOf");
		}
		
		private function verifyAnd(andCondition:ICondition, flag1:String, flag2:String, what:String):void {
			Autotest.assertClass(andCondition, AndCondition, what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, false);
			Autotest.clearAlert();
			Autotest.assertFalse(andCondition.isMet(context), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, false);
			Autotest.assertFalse(andCondition.isMet(context), what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, true);
			Autotest.assertFalse(andCondition.isMet(context), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, true);
			Autotest.assertTrue(andCondition.isMet(context), what);
		}
		
		private function verifyNotAnd(andCondition:ICondition, flag1:String, flag2:String, what:String):void {
			Autotest.assertClass(andCondition, AndCondition, what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, false);
			Autotest.clearAlert();
			Autotest.assertTrue(andCondition.isMet(context), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, false);
			Autotest.assertTrue(andCondition.isMet(context), what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, true);
			Autotest.assertTrue(andCondition.isMet(context), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, true);
			Autotest.assertFalse(andCondition.isMet(context), what);
		}
		
		private function verifyOr(orCondition:ICondition, flag1:String, flag2:String, what:String):void {
			Autotest.assertClass(orCondition, OrCondition, what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, false);
			Autotest.clearAlert();
			Autotest.assertFalse(orCondition.isMet(context), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, false);
			Autotest.assertTrue(orCondition.isMet(context), what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, true);
			Autotest.assertTrue(orCondition.isMet(context), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, true);
			Autotest.assertTrue(orCondition.isMet(context), what);
		}
		
		private function verifyNotOr(orCondition:ICondition, flag1:String, flag2:String, what:String):void {
			Autotest.assertClass(orCondition, OrCondition, what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, false);
			Autotest.clearAlert();
			Autotest.assertTrue(orCondition.isMet(context), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, false);
			Autotest.assertFalse(orCondition.isMet(context), what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, true);
			Autotest.assertFalse(orCondition.isMet(context), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, true);
			Autotest.assertFalse(orCondition.isMet(context), what);
		}
			
		private function testSpotConditions():void {
			var spotEmptyCondition:XML = <foo><empty param="test" /></foo>;
			var notSpotEmptyCondition:XML = <foo><notEmpty param="test" /></foo>;
			var location:Point = Autotest.testRoom.spotLocation("test");
			Autotest.assertEqual(location, null, "Spot shouldn't exist until we create it.");
			
			var spotEmpty:ICondition = ConditionFactory.createFromEnclosingXml(spotEmptyCondition, Autotest.script);
			Autotest.assertNoAlert("shouldn't check spot id on creation");
			Autotest.assertClass(spotEmpty, SpotEmptyCondition, "wrong condition type");
			var spotNotEmpty:ICondition = ConditionFactory.createFromEnclosingXml(notSpotEmptyCondition, Autotest.script);
			Autotest.assertClass(spotNotEmpty, SpotEmptyCondition, "wrong condition type");
			
			Autotest.assertFalse(spotEmpty.isMet(context), "undefined spot is not empty");
			Autotest.assertContextMessage(context, "Script error in spotEmpty: spot 'test' undefined in current room.");
			Autotest.assertFalse(spotNotEmpty.isMet(context), "undefined spot is not not-empty, either");
			Autotest.assertContextMessage(context, "Script error in spotEmpty: spot 'test' undefined in current room.");
			
			Autotest.testRoom.addOrMoveSpot("test", new Point(5, 5));
			Autotest.assertTrue(spotEmpty.isMet(context), "empty check should succeed");
			Autotest.assertFalse(spotNotEmpty.isMet(context), "not empty check should fail");
			
			Autotest.testRoom.addOrMoveSpot("test", Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_MAIN_PC_ID).location);
			Autotest.assertFalse(spotEmpty.isMet(context), "empty check should fail");
			Autotest.assertTrue(spotNotEmpty.isMet(context), "not empty check should succeed");
			
			Autotest.testRoom.removeSpot("test");
		}
		
		private function testActiveConditions():void {
			var activeCondition:XML = <foo><active param="badId" /></foo>;
			var notActiveCondition:XML = <foo><notActive param="badId" /></foo>;
			var badActive:ICondition = ConditionFactory.createFromEnclosingXml(activeCondition, Autotest.script);
			var badNotActive:ICondition = ConditionFactory.createFromEnclosingXml(notActiveCondition, Autotest.script);
			Autotest.assertNoAlert("shouldn't check id on creation");
			activeCondition.active.@param = Autotest.TEST_ROOM_MAIN_PC_ID;
			notActiveCondition.notActive.@param = Autotest.TEST_ROOM_MAIN_PC_ID;
			var active:ICondition = ConditionFactory.createFromEnclosingXml(activeCondition, Autotest.script);
			var notActive:ICondition = ConditionFactory.createFromEnclosingXml(notActiveCondition, Autotest.script);
			
			Autotest.assertClass(badActive, ActiveCondition, "wrong condition type");
			Autotest.assertClass(badNotActive, ActiveCondition, "wrong condition type");
			Autotest.assertClass(active, ActiveCondition, "wrong condition type");
			Autotest.assertClass(notActive, ActiveCondition, "wrong condition type");
			
			Autotest.assertFalse(badActive.isMet(context), "unknown character is not active");
			Autotest.assertContextMessage(context, "Script error in active: No character 'badId' in current room.");
			Autotest.assertFalse(badNotActive.isMet(context), "undefined character is not not-active, either");
			Autotest.assertContextMessage(context, "Script error in active: No character 'badId' in current room.");
			
			Autotest.assertTrue(active.isMet(context), "main character is active");
			Autotest.assertFalse(notActive.isMet(context), "main character is not not-active");
			
			var char:ComplexEntity = ComplexEntity(Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_MAIN_PC_ID));
			Autotest.assertNotEqual(char, null, "main entity should be in room");
			char.currentHealth = 0;
			
			Autotest.assertFalse(active.isMet(context), "main character is not active");
			Autotest.assertTrue(notActive.isMet(context), "main character is not-active");
			
			char.currentHealth = char.maxHealth;
		}
		
			
		private static const compareCondition:XML = <foo>
			<compare op="lt">
				<left int="1" />
				<right int="2"/>
			</compare>
		</foo>;
		private static const notCompareCondition:XML = <foo>
			<notCompare op="lt">
				<left int="1" />
				<right int="2"/>
			</notCompare>
		</foo>;
		private function testCompareCondition():void {
			//NOTE: Not a full or complete test, but covers the basic concept
			var comp:ICondition = ConditionFactory.createFromEnclosingXml(compareCondition, Autotest.script);
			Autotest.assertClass(comp, CompareCondition, "wrong condition type");
			Autotest.assertTrue(comp.isMet(context), "1 lt 2");
			var notComp:ICondition = ConditionFactory.createFromEnclosingXml(notCompareCondition, Autotest.script);
			Autotest.assertFalse(notComp.isMet(context), "not 1 lt 2");
			
			compareCondition.compare.@op = "le";
			comp = ConditionFactory.createFromEnclosingXml(compareCondition, Autotest.script);
			Autotest.assertTrue(comp.isMet(context), "1 le 2");
			
			compareCondition.compare.@op = "eq";
			comp = ConditionFactory.createFromEnclosingXml(compareCondition, Autotest.script);
			Autotest.assertFalse(comp.isMet(context), "1 eq 2");
			
		}
			
		
		private function testPcConditions():void {
			var pcCondition:XML = <foo><pc param="badId" /></foo>; 
			var notPcCondition:XML = <foo><notPc param="badId" /></foo>;
			var badPc:ICondition = ConditionFactory.createFromEnclosingXml(pcCondition, Autotest.script);
			var badNotPc:ICondition = ConditionFactory.createFromEnclosingXml(notPcCondition, Autotest.script);
			Autotest.assertNoAlert("shouldn't check id on creation");
			pcCondition.pc.@param = Autotest.TEST_ROOM_MAIN_PC_ID;
			notPcCondition.notPc.@param = Autotest.TEST_ROOM_MAIN_PC_ID;
			var isPc:ICondition = ConditionFactory.createFromEnclosingXml(pcCondition, Autotest.script);
			var notPc:ICondition = ConditionFactory.createFromEnclosingXml(notPcCondition, Autotest.script);
			
			Autotest.assertClass(badPc, PcCondition, "wrong condition type");
			
			Autotest.assertFalse(badPc.isMet(context), "unknown character is not pc");
			Autotest.assertContextMessage(context, "Script error in pc: No character 'badId' in current room.");
			Autotest.assertFalse(badNotPc.isMet(context), "undefined character is not not-pc, either");
			Autotest.assertContextMessage(context, "Script error in pc: No character 'badId' in current room.");
			
			Autotest.assertTrue(isPc.isMet(context), "main character is pc");
			Autotest.assertFalse(notPc.isMet(context), "main character is not not-pc");
			
			pcCondition.pc.@param = Autotest.TEST_ROOM_ENEMY_ID;
			notPcCondition.notPc.@param = Autotest.TEST_ROOM_ENEMY_ID;
			isPc = ConditionFactory.createFromEnclosingXml(pcCondition, Autotest.script);
			notPc= ConditionFactory.createFromEnclosingXml(notPcCondition, Autotest.script);
			Autotest.assertFalse(isPc.isMet(context), "enemy is not pc");
			Autotest.assertTrue(notPc.isMet(context), "enemy is not-pc");
		}
		
	}

}