package angel.game.test {
	import angel.common.Util;
	import angel.game.action.AndCondition;
	import angel.game.action.CharAliveCondition;
	import angel.game.action.CompareCondition;
	import angel.game.action.Condition;
	import angel.game.action.ICondition;
	import angel.game.action.OrCondition;
	import angel.game.action.SpotEmptyCondition;
	import angel.game.ComplexEntity;
	import angel.game.Flags;
	import angel.game.Settings;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConditionTest {
		
		public function ConditionTest() {
			Autotest.testFunction(testFlagCondition);
			Autotest.testFunction(testMultipleCondition);
			Autotest.testFunction(testAllOfCondition);
			Autotest.testFunction(testAnyOfCondition);
			Autotest.testFunction(testCompareCondition);
			
			Autotest.setupTestRoom();
			Autotest.testFunction(testSpotConditions);
			Autotest.testFunction(testAliveConditions);
			Settings.currentRoom.cleanup();
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
			
			
			Flags.setValue("xxTest", false);
		}		
		
		private static const multipleCondition:XML = <foo>
			<flag param="xxTest" />
			<flag param="yyTest" />
		</foo>;
		private function testMultipleCondition():void {
			var shouldBeAnd:ICondition = Condition.createFromEnclosingXml(multipleCondition);
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
			var shouldBeAnd:ICondition = Condition.createFromEnclosingXml(andCondition);
			verifyAnd(shouldBeAnd, "xxTest", "yyTest", "allOf");
			var shouldBeNotAnd:ICondition = Condition.createFromEnclosingXml(notAndCondition);
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
			var shouldBeOr:ICondition = Condition.createFromEnclosingXml(orCondition);
			verifyOr(shouldBeOr, "xxTest", "yyTest", "anyOf");
			var shouldBeNotOr:ICondition = Condition.createFromEnclosingXml(notOrCondition);
			verifyNotOr(shouldBeNotOr, "xxTest", "yyTest", "anyOf");
		}
		
		private function verifyAnd(andCondition:ICondition, flag1:String, flag2:String, what:String):void {
			Autotest.assertClass(andCondition, AndCondition, what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, false);
			Autotest.clearAlert();
			Autotest.assertFalse(andCondition.isMet(), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, false);
			Autotest.assertFalse(andCondition.isMet(), what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, true);
			Autotest.assertFalse(andCondition.isMet(), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, true);
			Autotest.assertTrue(andCondition.isMet(), what);
		}
		
		private function verifyNotAnd(andCondition:ICondition, flag1:String, flag2:String, what:String):void {
			Autotest.assertClass(andCondition, AndCondition, what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, false);
			Autotest.clearAlert();
			Autotest.assertTrue(andCondition.isMet(), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, false);
			Autotest.assertTrue(andCondition.isMet(), what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, true);
			Autotest.assertTrue(andCondition.isMet(), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, true);
			Autotest.assertFalse(andCondition.isMet(), what);
		}
		
		private function verifyOr(orCondition:ICondition, flag1:String, flag2:String, what:String):void {
			Autotest.assertClass(orCondition, OrCondition, what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, false);
			Autotest.clearAlert();
			Autotest.assertFalse(orCondition.isMet(), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, false);
			Autotest.assertTrue(orCondition.isMet(), what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, true);
			Autotest.assertTrue(orCondition.isMet(), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, true);
			Autotest.assertTrue(orCondition.isMet(), what);
		}
		
		private function verifyNotOr(orCondition:ICondition, flag1:String, flag2:String, what:String):void {
			Autotest.assertClass(orCondition, OrCondition, what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, false);
			Autotest.clearAlert();
			Autotest.assertTrue(orCondition.isMet(), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, false);
			Autotest.assertFalse(orCondition.isMet(), what);
			
			Flags.setValue(flag1, false);
			Flags.setValue(flag2, true);
			Autotest.assertFalse(orCondition.isMet(), what);
			
			Flags.setValue(flag1, true);
			Flags.setValue(flag2, true);
			Autotest.assertFalse(orCondition.isMet(), what);
		}
			
		private static const spotEmptyCondition:XML = <foo><empty param="test" /></foo>;
		private static const notSpotEmptyCondition:XML = <foo><notEmpty param="test" /></foo>;
		private function testSpotConditions():void {
			var location:Point = Settings.currentRoom.spotLocation("test");
			Autotest.assertEqual(location, null, "Spot shouldn't exist until we create it.");
			
			var spotEmpty:ICondition = Condition.createFromEnclosingXml(spotEmptyCondition);
			Autotest.assertNoAlert("shouldn't check spot id on creation");
			Autotest.assertClass(spotEmpty, SpotEmptyCondition, "wrong condition type");
			var spotNotEmpty:ICondition = Condition.createFromEnclosingXml(notSpotEmptyCondition);
			Autotest.assertClass(spotNotEmpty, SpotEmptyCondition, "wrong condition type");
			
			Autotest.assertFalse(spotEmpty.isMet(), "undefined spot is not empty");
			Autotest.assertAlertText("Error in condition: spot 'test' undefined in current room.");
			Autotest.assertFalse(spotNotEmpty.isMet(), "undefined spot is not not-empty, either");
			Autotest.assertAlertText("Error in condition: spot 'test' undefined in current room.");
			
			Settings.currentRoom.addOrMoveSpot("test", new Point(5, 5));
			Autotest.assertTrue(spotEmpty.isMet(), "empty check should succeed");
			Autotest.assertFalse(spotNotEmpty.isMet(), "not empty check should fail");
			
			Settings.currentRoom.addOrMoveSpot("test", Settings.currentRoom.entityInRoomWithId(Autotest.TEST_ROOM_MAIN_PC_ID).location);
			Autotest.assertFalse(spotEmpty.isMet(), "empty check should fail");
			Autotest.assertTrue(spotNotEmpty.isMet(), "not empty check should succeed");
			
			Settings.currentRoom.removeSpot("test");
		}
			
		private static const aliveCondition:XML = <foo><alive param="badId" /></foo>;
		private static const notAliveCondition:XML = <foo><notAlive param="badId" /></foo>;
		private function testAliveConditions():void {
			var badAlive:ICondition = Condition.createFromEnclosingXml(aliveCondition);
			var badNotAlive:ICondition = Condition.createFromEnclosingXml(notAliveCondition);
			Autotest.assertNoAlert("shouldn't check id on creation");
			aliveCondition.alive.@param = Autotest.TEST_ROOM_MAIN_PC_ID;
			notAliveCondition.notAlive.@param = Autotest.TEST_ROOM_MAIN_PC_ID;
			var alive:ICondition = Condition.createFromEnclosingXml(aliveCondition);
			var notAlive:ICondition = Condition.createFromEnclosingXml(notAliveCondition);
			
			Autotest.assertClass(badAlive, CharAliveCondition, "wrong condition type");
			Autotest.assertClass(badNotAlive, CharAliveCondition, "wrong condition type");
			Autotest.assertClass(alive, CharAliveCondition, "wrong condition type");
			Autotest.assertClass(notAlive, CharAliveCondition, "wrong condition type");
			
			Autotest.assertFalse(badAlive.isMet(), "unknown character is not alive");
			Autotest.assertAlertText("Error in condition: no character 'badId' in current room.");
			Autotest.assertFalse(badNotAlive.isMet(), "undefined character is not not-alive, either");
			Autotest.assertAlertText("Error in condition: no character 'badId' in current room.");
			
			Autotest.assertTrue(alive.isMet(), "main character is alive");
			Autotest.assertFalse(notAlive.isMet(), "main character is not not-alive");
			
			var char:ComplexEntity = ComplexEntity(Settings.currentRoom.entityInRoomWithId(Autotest.TEST_ROOM_MAIN_PC_ID));
			Autotest.assertNotEqual(char, null, "main entity should be in room");
			char.currentHealth = 0;
			
			Autotest.assertFalse(alive.isMet(), "main character is not alive");
			Autotest.assertTrue(notAlive.isMet(), "main character is not-alive");
			
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
			var comp:ICondition = Condition.createFromEnclosingXml(compareCondition);
			Autotest.assertClass(comp, CompareCondition, "wrong condition type");
			Autotest.assertTrue(comp.isMet(), "1 lt 2");
			var notComp:ICondition = Condition.createFromEnclosingXml(notCompareCondition);
			Autotest.assertFalse(notComp.isMet(), "not 1 lt 2");
			
			compareCondition.compare.@op = "le";
			comp = Condition.createFromEnclosingXml(compareCondition);
			Autotest.assertTrue(comp.isMet(), "1 le 2");
			
			compareCondition.compare.@op = "eq";
			comp = Condition.createFromEnclosingXml(compareCondition);
			Autotest.assertFalse(comp.isMet(), "1 eq 2");
			
		}
		
	}

}