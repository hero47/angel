package angel.game.test {
	import angel.common.CatalogEntry;
	import angel.common.Floor;
	import angel.game.action.Action;
	import angel.game.action.IAction;
	import angel.game.brain.BrainFidget;
	import angel.game.brain.BrainFollow;
	import angel.game.brain.BrainWander;
	import angel.game.brain.CombatBrainPatrol;
	import angel.game.brain.CombatBrainWander;
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.Flags;
	import angel.game.Room;
	import angel.game.RoomExplore;
	import angel.game.script.Script;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ActionTest {
		
		
		
		//CONSIDER: Parts of this are really flag tests and catalog tests, could be separated out
		//CONSIDER: Room initialization will probably want to be pulled out so other tests can use it as well
		public function ActionTest() {
			Autotest.testFunction(testFlagActions);
			Autotest.testFunction(testMessageAction);
			Autotest.testFunction(testIfAction);
			Autotest.testFunction(testIfElse);
			
			Autotest.setupTestRoom();
			Autotest.assertEqual(Settings.gameEventQueue.numberOfEventsInQueue(), 0, "Setup test room should leave queue clear");
			
			trace("Testing actions for no room mode");
			runTestsForMode(null);
			trace("Testing actions for Explore mode");
			runTestsForMode(RoomExplore);
			trace("Testing actions for Combat mode");
			runTestsForMode(RoomCombat);
			
			Settings.currentRoom.cleanup();
		}
		
		private function runTestsForMode(modeClass:Class):void {
			const modeChangeFail:String = "Mode change failed or delayed";
			Settings.currentRoom.changeModeTo(modeClass);
			if (modeClass == null) {
				Autotest.assertEqual(Settings.currentRoom.mode, null, modeChangeFail);
			} else {
				Autotest.assertTrue(Settings.currentRoom.mode is modeClass, modeChangeFail);
			}
			Settings.gameEventQueue.handleEvents();
			
			Autotest.testFunction(testAddRemoveCharacterActions);
			Autotest.testFunction(testChangeToFromPc);
			//Autotest.testFunction(testChangeRoom); This doesn't work because it loads from file, which is a delayed callback
			Autotest.testFunction(testChangeAction);
			
			Settings.currentRoom.changeModeTo(null);
			Autotest.assertEqual(Settings.currentRoom.mode, null, modeChangeFail);
		}
		
		private const addTestFlag:XML = <add flag="xxTest" />;
		private const removeTestFlag:XML = <remove flag="xxTest" />;
		private function testFlagActions():void {
			Autotest.testActionFromXml(addTestFlag);
			Autotest.assertTrue(Flags.getValue("xxTest"));
			Autotest.testActionFromXml(removeTestFlag);
			Autotest.assertFalse(Flags.getValue("xxTest"));
		}
		
		private function testMessageAction():void {
			var messageActionXml:XML = <message text="Hello, world!" />;
			Autotest.testActionFromXml(messageActionXml);
			Autotest.assertAlertText("Hello, world!");
		}
		
		private static const ifTestShortcutXml:XML = <if flag="xxTest">
			<message text="yes" />
		</if>;
		private static const ifNotTestShortcutXml:XML = <if notFlag="xxTest">
			<message text="no" />
		</if>;
		private static const ifTestXml:XML = <if>
			<flag param="xxTest" />
			<script>
				<message text="yes" />
			</script>
		</if>;
		private static const ifNotTestXml:XML = <if>
			<notFlag param="xxTest" />
			<script>
				<message text="no" />
			</script>
		</if>;
		private static const ifWithTwoConditionsXml:XML = <if>
			<flag param="xxTest" />
			<flag param="yyTest" />
			<script>
				<message text="yes" />
			</script>
		</if>;
		private static const ifWithAllOfConditionXml:XML = <if>
			<allOf>
				<flag param="xxTest" />
				<flag param="yyTest" />
			</allOf>
			<script>
				<message text="yes" />
			</script>
		</if>;
		private static const ifWithAnyOfConditionXml:XML = <if>
			<anyOf>
				<flag param="xxTest" />
				<flag param="yyTest" />
			</anyOf>
			<script>
				<message text="yes" />
			</script>
		</if>;
		private function testIfAction():void {
			Autotest.assertFalse(Flags.getValue("xxTest"));
			Autotest.assertFalse(Flags.getValue("yyTest"));
			Autotest.clearAlert();
			
			Autotest.testActionFromXml(ifTestShortcutXml);
			Autotest.assertNoAlert();
			Autotest.testActionFromXml(ifNotTestShortcutXml);
			Autotest.assertAlertText("no");
			
			Flags.setValue("xxTest", true);
			
			Autotest.testActionFromXml(ifTestShortcutXml);
			Autotest.assertAlertText("yes");
			Autotest.testActionFromXml(ifNotTestShortcutXml);
			Autotest.assertNoAlert();
			
			
			Flags.setValue("xxTest", false);
			
			Autotest.testActionFromXml(ifTestXml);
			Autotest.assertNoAlert();
			Autotest.testActionFromXml(ifNotTestXml);
			Autotest.assertAlertText("no");
			
			Flags.setValue("xxTest", true);
			
			Autotest.testActionFromXml(ifTestXml);
			Autotest.assertAlertText("yes");
			Autotest.testActionFromXml(ifNotTestXml);
			Autotest.assertNoAlert();
			
			
			testXxAndYy(ifWithTwoConditionsXml, "two conditions");
			testXxAndYy(ifWithAllOfConditionXml, "allOf condition");
			testXxOrYy(ifWithAnyOfConditionXml, "anyOf condition");
			
		}
		
		private function testXxAndYy(xml:XML, what:String):void {
			Flags.setValue("xxTest", false);
			Flags.setValue("yyTest", false);
			Autotest.testActionFromXml(xml);
			Autotest.assertNoAlert(what);
			
			Flags.setValue("xxTest", true);
			Flags.setValue("yyTest", false);
			Autotest.testActionFromXml(xml);
			Autotest.assertNoAlert(what);
			
			Flags.setValue("xxTest", false);
			Flags.setValue("yyTest", true);
			Autotest.testActionFromXml(xml);
			Autotest.assertNoAlert(what);
			
			Flags.setValue("xxTest", true);
			Flags.setValue("yyTest", true);
			Autotest.testActionFromXml(xml);
			Autotest.assertAlertText("yes", what);
		}
		
		private function testXxOrYy(xml:XML, what:String):void {
			Flags.setValue("xxTest", false);
			Flags.setValue("yyTest", false);
			Autotest.testActionFromXml(xml);
			Autotest.assertNoAlert(what);
			
			Flags.setValue("xxTest", true);
			Flags.setValue("yyTest", false);
			Autotest.testActionFromXml(xml);
			Autotest.assertAlertText("yes", what);
			
			Flags.setValue("xxTest", false);
			Flags.setValue("yyTest", true);
			Autotest.testActionFromXml(xml);
			Autotest.assertAlertText("yes", what);
			
			Flags.setValue("xxTest", true);
			Flags.setValue("yyTest", true);
			Autotest.testActionFromXml(xml);
			Autotest.assertAlertText("yes", what);
		}
		
		private static const ifElseScript:XML = <script>
			<if flag="xxTest">
				<message text="xx" />
			</if>
			<elseIf flag="yyTest">
				<message text="yy and not xx" />
			</elseIf>
			<else>
				<message text="neither" />
			</else>
		</script>;
		
		private function testIfElse():void {
			var script:Script = new Script(ifElseScript, "testIfElse");
			Autotest.assertNoAlert("ifElse script parsing failed");
			
			Flags.setValue("xxTest", true);
			Flags.setValue("yyTest", false);
			Autotest.clearAlert();
			script.run();
			Autotest.assertAlertText("xx");
			
			Flags.setValue("xxTest", false);
			Flags.setValue("yyTest", false);
			script.run();
			Autotest.assertAlertText("neither");
			
			Flags.setValue("xxTest", false);
			Flags.setValue("yyTest", true);
			script.run();
			Autotest.assertAlertText("yy and not xx");
		}
		
		
		private const addnei:XML = <addNpc id="nei" />;
		private const removenei:XML = <removeFromRoom id="nei" />;
		private const addneiAt12:XML = <addNpc id="nei" x="1" y="2" />;
		private const addneiAtTestSpot:XML = <addNpc id="nei" spot="test" />;
		private const addNeiWithBrains:XML = <addNpc id="nei" explore="fidget" combat="wander" />
		// Can't test adding with script because that loads from file, which is a delayed callback
		
		private function testAddRemoveCharacterActions():void {
			var entry:CatalogEntry = Settings.catalog.entry("nei");
			var neiOK:Boolean = (entry != null) && (entry.type == CatalogEntry.CHARACTER);
			Autotest.assertTrue(neiOK, "This test requires nei character in catalog.");
			if (!neiOK) {
				return;
			}
			
			var room:Room = Settings.currentRoom;
			
			Autotest.assertEqual(room.entityInRoomWithId("nei"), null);
			Autotest.testActionFromXml(removenei); // Removing entity that's not in room does nothing
			
			Autotest.assertEqual(room.entityInRoomWithId("nei"), null);
			Autotest.testActionFromXml(addnei);
			var nei:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertNotEqual(nei, null, "nei should have been added to room");
			Autotest.assertTrue(nei is ComplexEntity);
			Autotest.assertFalse(ComplexEntity(nei).isReallyPlayer, "Should be npc");
			Autotest.assertTrue(nei.location.equals(new Point(0, 0)), "Unspecified location should default to 0,0");
			Autotest.assertFalse(Settings.isOnPlayerList(nei));
			
			Autotest.testActionFromXml(removenei);
			Autotest.assertEqual(room.entityInRoomWithId("nei"), null, "nei should have been removed");
			
			Autotest.testActionFromXml(addneiAt12);
			var nei2:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertTrue(nei2.location.equals(new Point(1, 2)), "Should use x & y if provided");
			Autotest.testActionFromXml(removenei);
			
			Autotest.testActionFromXml(addneiAtTestSpot);
			var nei3:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertAlerted("Undefined spot");
			Autotest.assertTrue(nei3.location.equals(new Point(0, 0)), "Should create at 0,0 if spot undefined");
			Autotest.testActionFromXml(removenei);
			
			room.addOrMoveSpot("test", new Point(3, 4));
			Autotest.testActionFromXml(addneiAtTestSpot);
			var nei4:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertTrue(nei4.location.equals(new Point(3, 4)), "Should create at 0,0 if spot undefined");
			Autotest.testActionFromXml(removenei);
			room.removeSpot("test");
			
			Autotest.testActionFromXml(addNeiWithBrains);
			var nei5:ComplexEntity = ComplexEntity(room.entityInRoomWithId("nei"));
			Autotest.assertEqual(nei5.exploreBrainClass, BrainFidget);
			Autotest.assertEqual(nei5.combatBrainClass, CombatBrainWander);
			if (Settings.currentRoom.mode is RoomExplore) {
				Autotest.assertTrue(nei5.brain is BrainFidget);
			} else if (Settings.currentRoom.mode is RoomCombat) {
				Autotest.assertTrue(nei5.brain is CombatBrainWander, "Note: This will fail if controlEnemies==true");
			} else {
				Autotest.assertEqual(nei5.brain, null);
			}
			Autotest.testActionFromXml(removenei);
		}
		
		private const changeNeiToPc:XML = <changeToPc id="nei" />;
		private const changeNeiToNpc:XML = <changeToNpc id="nei" />;
		private const changeNeiToNpcWithBrains:XML = <changeToNpc id="nei" explore="wander" combat="patrol" combatParam="3:testSpot" />
		
		private function testChangeToFromPc():void {
			var room:Room = Settings.currentRoom;
			
			Autotest.testActionFromXml(changeNeiToPc);
			Autotest.assertAlertText("Script error: no character nei in room for changeToPc");			
			
			Autotest.testActionFromXml(changeNeiToNpc);
			Autotest.assertAlertText("Script error: no character nei in room for changeToNpc");
			
			Autotest.testActionFromXml(addNeiWithBrains);
			var nei:ComplexEntity = ComplexEntity(room.entityInRoomWithId("nei"));
			Autotest.assertFalse(nei.isReallyPlayer, "Should be npc");
			Autotest.assertFalse(Settings.isOnPlayerList(nei), "Npc shouldn't be on player list");
			
			Autotest.testActionFromXml(changeNeiToNpc);
			Autotest.assertNoAlert("Change to Npc does nothing if entity is already npc");
			
			Autotest.testActionFromXml(changeNeiToPc);
			Autotest.assertEqual(room.entityInRoomWithId("nei"), nei, "Change pc-ness shouldn't change room or identity");
			Autotest.assertTrue(nei.isReallyPlayer, "Should have changed to player");
			Autotest.assertTrue(Settings.isOnPlayerList(nei), "Should have added to player list");
			Autotest.assertEqual(nei.exploreBrainClass, BrainFollow, "PC gets follow brain");
			Autotest.assertEqual(nei.combatBrainClass, null, "PC gets no combat brain");
			if (Settings.currentRoom.mode is RoomExplore) {
				Autotest.assertTrue(nei.brain is BrainFollow);
			} else {
				Autotest.assertEqual(nei.brain, null);
			}
			
			Autotest.testActionFromXml(changeNeiToNpc);
			Autotest.assertEqual(room.entityInRoomWithId("nei"), nei, "Change pc-ness shouldn't change room or identity");
			Autotest.assertFalse(nei.isReallyPlayer, "Should have changed back to npc");
			Autotest.assertFalse(Settings.isOnPlayerList(nei), "Should have removed from player list");
			Autotest.assertEqual(nei.exploreBrainClass, null, "No explore brain specified should default to null");
			Autotest.assertEqual(nei.combatBrainClass, null, "No combat brain specified should default to null");
			Autotest.assertEqual(nei.brain, null);
			
			Settings.currentRoom.addOrMoveSpot("testSpot", new Point(0, 0));
			Autotest.testActionFromXml(changeNeiToPc);
			Autotest.testActionFromXml(changeNeiToNpcWithBrains);
			Autotest.assertEqual(nei.exploreBrainClass, BrainWander);
			Autotest.assertEqual(nei.combatBrainClass, CombatBrainPatrol);
			Autotest.assertEqual(nei.combatBrainParam, "3:testSpot");
			if (Settings.currentRoom.mode is RoomExplore) {
				Autotest.assertTrue(nei.brain is BrainWander);
			} else if (Settings.currentRoom.mode is RoomCombat) {
				Autotest.assertTrue(nei.brain is CombatBrainPatrol, "Note: This will fail if controlEnemies==true");
			} else {
				Autotest.assertEqual(nei.brain, null);
			}
			Settings.currentRoom.removeSpot("testSpot");
			
			Autotest.testActionFromXml(changeNeiToPc);
			Autotest.testActionFromXml(removenei);
			Autotest.assertEqual(room.entityInRoomWithId("nei"), null, "nei should have been removed");
			Autotest.assertFalse(Settings.isOnPlayerList(nei), "Remove pc from room should also remove from player list");
		}
		
		/*
		 * Can't actually run this because it loads from file, which is a delayed callback.
		private static const changeRoom:XML = <changeRoom file="empty15x15.xml" />;
		private function testChangeRoom():void {
			var oldCurrentRoom:Room = Settings.currentRoom;
			var mainPc:ComplexEntity = Settings.currentRoom.mainPlayerCharacter;
			//UNDONE: this isn't at all a rigorous test; we don't have anything but the pc's in either room
			//also not testing mode, start spot
			testActionFromXml(changeRoom, true);
			Autotest.assertNoAlert();
			
			Autotest.assertNotEqual(oldCurrentRoom, Settings.currentRoom, "Room didn't change");
			oldCurrentRoom = null;
			Autotest.assertEqual(mainPc.room, Settings.currentRoom, "PC didn't move");
			Autotest.assertEqual(Settings.currentRoom.mainPlayerCharacter, mainPc, "Same character should be main pc");
		}
		*/
		
		private const changeNeiSpot:XML = <change id="nei" spot="testSpot"/>;
		private const changeNeiWithXY:XML = <change id="nei" x="4" y="7" />;
		private const changeNeiSpotAndXY:XML = <change id="nei" spot="testSpot" x="1" y="1" />;
		private const changeNeiBrain:XML = <change id="nei" explore="wander" combat="patrol" combatParam="testSpot" />;
		private const clearNeiBrain:XML = <change id="nei" explore="" combat="" />;
		
		private const changeFoo:XML = <change id="foo" explore="wander" combat="patrol" combatParam="testSpot" spot="testSpot"/>;
		private const removeFoo:XML = <removeFromRoom id="foo" />;
		private function testChangeAction():void {
			var room:Room = Settings.currentRoom;
			Settings.currentRoom.addOrMoveSpot("testSpot", new Point(3, 5));
			
			Autotest.testActionFromXml(addneiAt12);
			var nei:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertTrue(nei.location.equals(new Point(1, 2)), "Initial location wrong");
			Autotest.testActionFromXml(changeNeiSpot);
			Autotest.assertTrue(nei.location.equals(new Point(3, 5)), "Didn't move correctly with spot");
			Autotest.testActionFromXml(changeNeiWithXY);
			Autotest.assertTrue(nei.location.equals(new Point(4, 7)), "Didn't move correctly with X & Y parameters");
			Autotest.testActionFromXml(changeNeiSpotAndXY);
			Autotest.assertAlertText("Error: change action with both spot and x,y");
			
			Autotest.testActionFromXml(changeNeiBrain);
			var neiComplex:ComplexEntity = ComplexEntity(nei);
			Autotest.assertEqual(neiComplex.exploreBrainClass, BrainWander);
			Autotest.assertEqual(neiComplex.combatBrainClass, CombatBrainPatrol);
			Autotest.assertEqual(neiComplex.combatBrainParam, "testSpot");
			if (Settings.currentRoom.mode is RoomExplore) {
				Autotest.assertTrue(neiComplex.brain is BrainWander);
			} else if (Settings.currentRoom.mode is RoomCombat) {
				Autotest.assertTrue(neiComplex.brain is CombatBrainPatrol, "Note: This will fail if controlEnemies==true");
			} else {
				Autotest.assertEqual(neiComplex.brain, null);
			}
			Autotest.testActionFromXml(clearNeiBrain);
			Autotest.assertEqual(neiComplex.exploreBrainClass, null);
			Autotest.assertEqual(neiComplex.combatBrainClass, null);
			Autotest.assertEqual(neiComplex.combatBrainParam, null, "Removing behavior should auto-remove corresponding param");
			
			var fooXml:XML = <prop id="foo" x="6" y="5"/>
			var foo:SimpleEntity = SimpleEntity.createFromRoomContentsXml(fooXml, 1, Settings.catalog);
			Autotest.clearAlert();
			Autotest.assertNotEqual(foo, null, "couldn't create prop foo");
			Settings.currentRoom.addEntityUsingItsLocation(foo);
			Settings.gameEventQueue.handleEvents();
			var foo1:SimpleEntity = Settings.currentRoom.entityInRoomWithId("foo");
			Autotest.assertEqual(foo, foo1, "foo not added to room");
			Autotest.assertTrue(foo.location.equals(new Point(6, 5)), "foo location wrong");
			
			Autotest.testActionFromXml(changeFoo);
			Autotest.assertNoAlert("Changing brains on simple entity should be ignored, not cause error");
			Autotest.assertTrue(foo.location.equals(new Point(3, 5)), "foo didn't move to spot");
			Autotest.testActionFromXml(removeFoo);
			
			Autotest.testActionFromXml(removenei);
			Settings.currentRoom.removeSpot("testSpot");
		}
		
		
	} // end class ActionTest

}