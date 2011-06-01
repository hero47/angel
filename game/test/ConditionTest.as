package angel.game.test {
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.Flags;
	import angel.game.script.condition.AliveCondition;
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
			// If any of these conditions try to make use of context, we'll die with a null.
			Autotest.testFunction(testFlagCondition);
			Autotest.testFunction(testMultipleCondition);
			Autotest.testFunction(testAllOfCondition);
			Autotest.testFunction(testAnyOfCondition);
			Autotest.testFunction(testCompareCondition);
			
			Autotest.setupTestRoom();
			context = new ScriptContext(Autotest.testRoom);
			Autotest.testFunction(testSpotConditions);
			Autotest.testFunction(testAliveConditions);
			Autotest.testFunction(testPcConditions);
			Autotest.cleanupTestRoom();
		}
		
		private static const flagCondition:XML = <foo><flag param="xxTest" /></foo>;
		private static const notFlagCondition:XML = <foo><notFlag param="xxTest" /></foo>;
		private static const flagMissingParam:XML = <foo><flag /></foo>;
		private function testFlagCondition():void {
			Autotest.assertFalse(Flags.getValue("xxTest"));
			Autotest.clearAlert();
			
			var flag:ICondition = ConditionFactory.createFromEnclosingXml(flagCondition);
			Autotest.assertNotEqual(flag, null, "failed to create flag condition");
			var notFlag:ICondition = ConditionFactory.createFromEnclosingXml(notFlagCondition);
			Autotest.assertNotEqual(notFlag, null, "failed to create notFlag condition");
			
			Autotest.assertFalse(flag.isMet(context), "flag is false, regular");
			Autotest.assertTrue(notFlag.isMet(context), "flag is false, invert");
			
			Flags.setValue("xxTest", true);
			Autotest.assertTrue(flag.isMet(context), "flag is true, regular");
			Autotest.assertFalse(notFlag.isMet(context), "flag is true, invert");
			
			Autotest.assertEqual(ConditionFactory.createFromEnclosingXml(flagMissingParam), null, "should fail to create");
			Autotest.assertAlertText("Error! 'flag' condition requires param.");
			
			
			Flags.setValue("xxTest", false);
		}		
		
		private static const multipleCondition:XML = <foo>
			<flag param="xxTest" />
			<flag param="yyTest" />
		</foo>;
		private function testMultipleCondition():void {
			var shouldBeAnd:ICondition = ConditionFactory.createFromEnclosingXml(multipleCondition);
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
			var shouldBeAnd:ICondition = ConditionFactory.createFromEnclosingXml(andCondition);
			verifyAnd(shouldBeAnd, "xxTest", "yyTest", "allOf");
			var shouldBeNotAnd:ICondition = ConditionFactory.createFromEnclosingXml(notAndCondition);
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
			var shouldBeOr:ICondition = ConditionFactory.createFromEnclosingXml(orCondition);
			verifyOr(shouldBeOr, "xxTest", "yyTest", "anyOf");
			var shouldBeNotOr:ICondition = ConditionFactory.createFromEnclosingXml(notOrCondition);
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
			
			var spotEmpty:ICondition = ConditionFactory.createFromEnclosingXml(spotEmptyCondition);
			Autotest.assertNoAlert("shouldn't check spot id on creation");
			Autotest.assertClass(spotEmpty, SpotEmptyCondition, "wrong condition type");
			var spotNotEmpty:ICondition = ConditionFactory.createFromEnclosingXml(notSpotEmptyCondition);
			Autotest.assertClass(spotNotEmpty, SpotEmptyCondition, "wrong condition type");
			
			Autotest.assertFalse(spotEmpty.isMet(context), "undefined spot is not empty");
			Autotest.assertAlertText("Error in condition: spot 'test' undefined in current room.");
			Autotest.assertFalse(spotNotEmpty.isMet(context), "undefined spot is not not-empty, either");
			Autotest.assertAlertText("Error in condition: spot 'test' undefined in current room.");
			
			Autotest.testRoom.addOrMoveSpot("test", new Point(5, 5));
			Autotest.assertTrue(spotEmpty.isMet(context), "empty check should succeed");
			Autotest.assertFalse(spotNotEmpty.isMet(context), "not empty check should fail");
			
			Autotest.testRoom.addOrMoveSpot("test", Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_MAIN_PC_ID).location);
			Autotest.assertFalse(spotEmpty.isMet(context), "empty check should fail");
			Autotest.assertTrue(spotNotEmpty.isMet(context), "not empty check should succeed");
			
			Autotest.testRoom.removeSpot("test");
		}
		
		private function testAliveConditions():void {
			var aliveCondition:XML = <foo><alive param="badId" /></foo>;
			var notAliveCondition:XML = <foo><notAlive param="badId" /></foo>;
			var badAlive:ICondition = ConditionFactory.createFromEnclosingXml(aliveCondition);
			var badNotAlive:ICondition = ConditionFactory.createFromEnclosingXml(notAliveCondition);
			Autotest.assertNoAlert("shouldn't check id on creation");
			aliveCondition.alive.@param = Autotest.TEST_ROOM_MAIN_PC_ID;
			notAliveCondition.notAlive.@param = Autotest.TEST_ROOM_MAIN_PC_ID;
			var alive:ICondition = ConditionFactory.createFromEnclosingXml(aliveCondition);
			var notAlive:ICondition = ConditionFactory.createFromEnclosingXml(notAliveCondition);
			
			Autotest.assertClass(badAlive, AliveCondition, "wrong condition type");
			Autotest.assertClass(badNotAlive, AliveCondition, "wrong condition type");
			Autotest.assertClass(alive, AliveCondition, "wrong condition type");
			Autotest.assertClass(notAlive, AliveCondition, "wrong condition type");
			
			Autotest.assertFalse(badAlive.isMet(context), "unknown character is not alive");
			Autotest.assertAlertText("Error in condition: no character 'badId' in current room.");
			Autotest.assertFalse(badNotAlive.isMet(context), "undefined character is not not-alive, either");
			Autotest.assertAlertText("Error in condition: no character 'badId' in current room.");
			
			Autotest.assertTrue(alive.isMet(context), "main character is alive");
			Autotest.assertFalse(notAlive.isMet(context), "main character is not not-alive");
			
			var char:ComplexEntity = ComplexEntity(Autotest.testRoom.entityInRoomWithId(Autotest.TEST_ROOM_MAIN_PC_ID));
			Autotest.assertNotEqual(char, null, "main entity should be in room");
			char.currentHealth = 0;
			
			Autotest.assertFalse(alive.isMet(context), "main character is not alive");
			Autotest.assertTrue(notAlive.isMet(context), "main character is not-alive");
			
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
			var comp:ICondition = ConditionFactory.createFromEnclosingXml(compareCondition);
			Autotest.assertClass(comp, CompareCondition, "wrong condition type");
			Autotest.assertTrue(comp.isMet(context), "1 lt 2");
			var notComp:ICondition = ConditionFactory.createFromEnclosingXml(notCompareCondition);
			Autotest.assertFalse(notComp.isMet(context), "not 1 lt 2");
			
			compareCondition.compare.@op = "le";
			comp = ConditionFactory.createFromEnclosingXml(compareCondition);
			Autotest.assertTrue(comp.isMet(context), "1 le 2");
			
			compareCondition.compare.@op = "eq";
			comp = ConditionFactory.createFromEnclosingXml(compareCondition);
			Autotest.assertFalse(comp.isMet(context), "1 eq 2");
			
		}
			
		
		private function testPcConditions():void {
			var pcCondition:XML = <foo><pc param="badId" /></foo>; 
			var notPcCondition:XML = <foo><notPc param="badId" /></foo>;
			var badPc:ICondition = ConditionFactory.createFromEnclosingXml(pcCondition);
			var badNotPc:ICondition = ConditionFactory.createFromEnclosingXml(notPcCondition);
			Autotest.assertNoAlert("shouldn't check id on creation");
			pcCondition.pc.@param = Autotest.TEST_ROOM_MAIN_PC_ID;
			notPcCondition.notPc.@param = Autotest.TEST_ROOM_MAIN_PC_ID;
			var isPc:ICondition = ConditionFactory.createFromEnclosingXml(pcCondition);
			var notPc:ICondition = ConditionFactory.createFromEnclosingXml(notPcCondition);
			
			Autotest.assertClass(badPc, PcCondition, "wrong condition type");
			
			Autotest.assertFalse(badPc.isMet(context), "unknown character is not pc");
			Autotest.assertAlertText("Error in condition: no character 'badId' in current room.");
			Autotest.assertFalse(badNotPc.isMet(context), "undefined character is not not-pc, either");
			Autotest.assertAlertText("Error in condition: no character 'badId' in current room.");
			
			Autotest.assertTrue(isPc.isMet(context), "main character is pc");
			Autotest.assertFalse(notPc.isMet(context), "main character is not not-pc");
			
			pcCondition.pc.@param = Autotest.TEST_ROOM_ENEMY_ID;
			notPcCondition.notPc.@param = Autotest.TEST_ROOM_ENEMY_ID;
			isPc = ConditionFactory.createFromEnclosingXml(pcCondition);
			notPc= ConditionFactory.createFromEnclosingXml(notPcCondition);
			Autotest.assertFalse(isPc.isMet(context), "enemy is not pc");
			Autotest.assertTrue(notPc.isMet(context), "enemy is not-pc");
		}
		
	}

}