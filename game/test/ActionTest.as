package angel.game.test {
	import angel.common.CatalogEntry;
	import angel.common.CharResource;
	import angel.common.Floor;
	import angel.game.brain.BrainFidget;
	import angel.game.brain.BrainFollow;
	import angel.game.brain.BrainWander;
	import angel.game.brain.CombatBrainNone;
	import angel.game.brain.CombatBrainPatrol;
	import angel.game.brain.CombatBrainUiMeldPlayer;
	import angel.game.brain.CombatBrainWander;
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.event.EntityQEvent;
	import angel.game.event.QEvent;
	import angel.game.Flags;
	import angel.game.inventory.Inventory;
	import angel.game.Room;
	import angel.game.RoomExplore;
	import angel.game.script.Script;
	import angel.game.script.TriggerMaster;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ActionTest {
		private var testRoom:Room;
		
		
		public function ActionTest() {
			Autotest.testFunction(testFlagActions);
			Autotest.testFunction(testNumericFlagActions);
			Autotest.testFunction(testMessageAction);
			Autotest.testFunction(testIfAction);
			Autotest.testFunction(testIfElse);
			
			testRoom = Autotest.setupTestRoom();
			Autotest.assertEqual(Settings.gameEventQueue.numberOfCallbacksWaitingProcessing(), 0, "Setup test room should leave queue clear");
			
			trace("Testing actions for no room mode");
			runTestsForMode(null);
			trace("Testing actions for Explore mode");
			runTestsForMode(RoomExplore);
			trace("Testing actions for Combat mode");
			runTestsForMode(RoomCombat);
			
			Autotest.cleanupTestRoom();
		}
		
		private function runTestsForMode(modeClass:Class):void {
			const modeChangeFail:String = "Mode change failed or delayed";
			testRoom.changeModeTo(modeClass);
			if (modeClass == null) {
				Autotest.assertEqual(testRoom.mode, null, modeChangeFail);
			} else {
				Autotest.assertTrue(testRoom.mode is modeClass, modeChangeFail);
			}
			Settings.gameEventQueue.handleEvents();
			
			Autotest.testFunction(testAddRemoveCharacterActions);
			Autotest.testFunction(testChangeToFromPc);
			//Autotest.testFunction(testChangeRoom); This doesn't work because it loads from file, which is a delayed callback
			Autotest.testFunction(testChangeAction);
			Autotest.testFunction(testChangeMainPcAction);
			Autotest.testFunction(testInventoryActions);
			
			testRoom.changeModeTo(null);
			Autotest.assertEqual(testRoom.mode, null, modeChangeFail);
		}
		
		private const addTestFlag:XML = <set flag="xxTest" />;
		private const removeTestFlag:XML = <remove flag="xxTest" />;
		private function testFlagActions():void {
			Autotest.testActionFromXml(addTestFlag);
			Autotest.assertTrue(Boolean(Flags.getValue("xxTest")));
			Autotest.testActionFromXml(removeTestFlag);
			Autotest.assertFalse(Boolean(Flags.getValue("xxTest")));
		}
		
		private const addTestFlag2:XML = <set flag="xxTest2" int="16" />;
		private function testNumericFlagActions():void {
			Autotest.testActionFromXml(addTestFlag2);
			Autotest.assertEqual(Flags.getValue("xxTest2"), 16, "Set flag to constant failed");
			
			var adjustFlag:XML = <adjust flag="xxTest2" />;
			Autotest.testActionFromXml(adjustFlag);
			Autotest.assertEqual(Flags.getValue("xxTest2"), 17, "Adjust with no add parameter should add 1");
			
			adjustFlag.@add = "2";
			Autotest.testActionFromXml(adjustFlag);
			Autotest.assertEqual(Flags.getValue("xxTest2"), 19, "17 + 2");
			
			adjustFlag.@add = "-3";
			Autotest.testActionFromXml(adjustFlag);
			Autotest.assertEqual(Flags.getValue("xxTest2"), 16, "19 - 3");
		}
		
		private static const doubleMessage:XML =  <if notFlag="xxTest">
			<message text="first" />
			<message text="second" />
		</if>;
		private function testMessageAction():void {
			var messageActionXml:XML = <message text="Hello, world!" />;
			Autotest.testActionFromXml(messageActionXml);
			Autotest.assertAlertText("Hello, world!");
			
			Autotest.assertFalse(Boolean(Flags.getValue("xxTest")));
			Autotest.clearAlert(); // in case flag wasn't initialized yet
			Autotest.testActionFromXml(doubleMessage);
			Autotest.assertAlertText("first\nsecond", "Should have combined both messages into one alert with linefeed between them");
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
			Autotest.assertFalse(Boolean(Flags.getValue("xxTest")));
			Autotest.assertFalse(Boolean(Flags.getValue("yyTest")));
			Autotest.clearAlert(); // in case flag wasn't initialized yet
			
			Autotest.testActionFromXml(ifTestShortcutXml);
			Autotest.assertNoAlert();
			Autotest.testActionFromXml(ifNotTestShortcutXml);
			Autotest.assertAlertText("no");
			
			Flags.setValue("xxTest", 1);
			
			Autotest.testActionFromXml(ifTestShortcutXml);
			Autotest.assertAlertText("yes");
			Autotest.testActionFromXml(ifNotTestShortcutXml);
			Autotest.assertNoAlert();
			
			
			Flags.setValue("xxTest", 0);
			
			Autotest.testActionFromXml(ifTestXml);
			Autotest.assertNoAlert();
			Autotest.testActionFromXml(ifNotTestXml);
			Autotest.assertAlertText("no");
			
			Flags.setValue("xxTest", 1);
			
			Autotest.testActionFromXml(ifTestXml);
			Autotest.assertAlertText("yes");
			Autotest.testActionFromXml(ifNotTestXml);
			Autotest.assertNoAlert();
			
			
			testXxAndYy(ifWithTwoConditionsXml, "two conditions");
			testXxAndYy(ifWithAllOfConditionXml, "allOf condition");
			testXxOrYy(ifWithAnyOfConditionXml, "anyOf condition");
			
		}
		
		private function testXxAndYy(xml:XML, what:String):void {
			Flags.setValue("xxTest", 0);
			Flags.setValue("yyTest", 0);
			Autotest.testActionFromXml(xml);
			Autotest.assertNoAlert(what);
			
			Flags.setValue("xxTest", 1);
			Flags.setValue("yyTest", 0);
			Autotest.testActionFromXml(xml);
			Autotest.assertNoAlert(what);
			
			Flags.setValue("xxTest", 0);
			Flags.setValue("yyTest", 1);
			Autotest.testActionFromXml(xml);
			Autotest.assertNoAlert(what);
			
			Flags.setValue("xxTest", 1);
			Flags.setValue("yyTest", 1);
			Autotest.testActionFromXml(xml);
			Autotest.assertAlertText("yes", what);
		}
		
		private function testXxOrYy(xml:XML, what:String):void {
			Flags.setValue("xxTest", 0);
			Flags.setValue("yyTest", 0);
			Autotest.testActionFromXml(xml);
			Autotest.assertNoAlert(what);
			
			Flags.setValue("xxTest", 1);
			Flags.setValue("yyTest", 0);
			Autotest.testActionFromXml(xml);
			Autotest.assertAlertText("yes", what);
			
			Flags.setValue("xxTest", 0);
			Flags.setValue("yyTest", 1);
			Autotest.testActionFromXml(xml);
			Autotest.assertAlertText("yes", what);
			
			Flags.setValue("xxTest", 1);
			Flags.setValue("yyTest", 1);
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
			var script:Script = new Script(ifElseScript, Autotest.script);
			Autotest.assertNoAlert("ifElse script parsing failed");
			
			Flags.setValue("xxTest", 1);
			Flags.setValue("yyTest", 0);
			Autotest.clearAlert();
			script.run(testRoom, null, null);
			Autotest.assertAlertText("xx");
			
			Flags.setValue("xxTest", 0);
			Flags.setValue("yyTest", 0);
			script.run(testRoom, null, null);
			Autotest.assertAlertText("neither");
			
			Flags.setValue("xxTest", 0);
			Flags.setValue("yyTest", 1);
			script.run(testRoom, null, null);
			Autotest.assertAlertText("yy and not xx");
		}
		
		
		private const addnei:XML = <addNpc id="nei" />;
		private const removenei:XML = <removeFromRoom id="nei" />;
		private const addneiAt12:XML = <addNpc id="nei" x="1" y="2" />;
		private const addneiAtTestSpot:XML = <addNpc id="nei" spot="test" />;
		private const addNeiWithBrains:XML = <addNpc id="nei" explore="fidget" combat="wander" />
		// Can't test adding with script because that loads from file, which is a delayed callback
		
		private function testAddRemoveCharacterActions():void {
			if (Settings.catalog.entry("nei") == null) {
				var resource:CharResource = Settings.catalog.retrieveCharacterResource("nei");
				Autotest.clearAlert();
			}
			var entry:CatalogEntry = Settings.catalog.entry("nei");
			var neiOK:Boolean = (entry != null) && (entry.type == CatalogEntry.CHARACTER);
			Autotest.assertTrue(neiOK, "This test requires nei character in catalog.");
			if (!neiOK) {
				return;
			}
			
			Autotest.assertEqual(testRoom.entityInRoomWithId("nei"), null);
			Autotest.testActionFromXml(removenei);
			Autotest.assertAlertText("Script error in removeFromRoom: No entity 'nei' in current room.");
			
			Autotest.assertEqual(testRoom.entityInRoomWithId("nei"), null);
			Autotest.testActionFromXml(addnei);
			var nei:SimpleEntity = testRoom.entityInRoomWithId("nei");
			Autotest.assertNotEqual(nei, null, "nei should have been added to room");
			Autotest.assertTrue(nei is ComplexEntity);
			Autotest.assertFalse(ComplexEntity(nei).isReallyPlayer, "Should be npc");
			Autotest.assertTrue(nei.location.equals(new Point(0, 0)), "Unspecified location should default to 0,0");
			
			Autotest.testActionFromXml(removenei);
			Autotest.assertEqual(testRoom.entityInRoomWithId("nei"), null, "nei should have been removed");
			
			Autotest.testActionFromXml(addneiAt12);
			var nei2:SimpleEntity = testRoom.entityInRoomWithId("nei");
			Autotest.assertTrue(nei2.location.equals(new Point(1, 2)), "Should use x & y if provided");
			Autotest.testActionFromXml(removenei);
			
			Autotest.testActionFromXml(addneiAtTestSpot);
			var nei3:SimpleEntity = testRoom.entityInRoomWithId("nei");
			Autotest.assertAlerted("Undefined spot");
			Autotest.assertTrue(nei3.location.equals(new Point(0, 0)), "Should create at 0,0 if spot undefined");
			Autotest.testActionFromXml(removenei);
			
			testRoom.addOrMoveSpot("test", new Point(3, 4));
			Autotest.testActionFromXml(addneiAtTestSpot);
			var nei4:SimpleEntity = testRoom.entityInRoomWithId("nei");
			Autotest.assertTrue(nei4.location.equals(new Point(3, 4)), "Should create at 0,0 if spot undefined");
			Autotest.testActionFromXml(removenei);
			testRoom.removeSpot("test");
			
			Autotest.testActionFromXml(addNeiWithBrains);
			var nei5:ComplexEntity = ComplexEntity(testRoom.entityInRoomWithId("nei"));
			Autotest.assertEqual(nei5.exploreBrainClass, BrainFidget);
			Autotest.assertEqual(nei5.combatBrainClass, CombatBrainWander);
			if (testRoom.mode is RoomExplore) {
				Autotest.assertTrue(nei5.brain is BrainFidget);
			} else if (testRoom.mode is RoomCombat) {
				Autotest.assertTrue(nei5.brain is CombatBrainWander, "Note: This will fail if controlEnemies==true");
			} else {
				Autotest.assertEqual(nei5.brain, null);
			}
			Autotest.testActionFromXml(removenei);
			
			var mainPcId:String = testRoom.mainPlayerCharacter.id;
			var removeMainPc:XML = removenei.copy();
			removeMainPc.@id = mainPcId;
			Autotest.testActionFromXml(removeMainPc);
			Autotest.assertAlerted("Attempt to remove main pc should give error");
		}
		
		private const changeNeiToPc:XML = <changeToPc id="nei" />;
		private const changeNeiToNpc:XML = <changeToNpc id="nei" />;
		private const changeNeiToNpcWithBrains:XML = <changeToNpc id="nei" explore="wander" combat="patrol" combatParam="3:testSpot" />
		
		private function testChangeToFromPc():void {
			var room:Room = testRoom;
			
			Autotest.testActionFromXml(changeNeiToPc);
			Autotest.assertAlertText("Script error in changeToPc: No character 'nei' in current room.");			
			
			Autotest.testActionFromXml(changeNeiToNpc);
			Autotest.assertAlertText("Script error in changeToNpc: No character 'nei' in current room.");
			
			Autotest.testActionFromXml(addNeiWithBrains);
			var nei:ComplexEntity = ComplexEntity(room.entityInRoomWithId("nei"));
			Autotest.assertFalse(nei.isReallyPlayer, "Should be npc");
			Autotest.assertEqual(nei.faction, ComplexEntity.FACTION_ENEMY, "No faction specified npc should be enemy");
			
			Autotest.testActionFromXml(changeNeiToNpc);
			Autotest.assertNoAlert("Change to Npc does nothing if entity is already npc");
			
			Autotest.testActionFromXml(changeNeiToPc);
			Autotest.assertEqual(room.entityInRoomWithId("nei"), nei, "Change pc-ness shouldn't change room or identity");
			Autotest.assertTrue(nei.isReallyPlayer, "Should have changed to player");
			Autotest.assertEqual(nei.faction, ComplexEntity.FACTION_FRIEND, "PC should always be friend faction");
			Autotest.assertEqual(nei.exploreBrainClass, BrainFollow, "PC gets follow brain");
			Autotest.assertEqual(nei.combatBrainClass, CombatBrainUiMeldPlayer, "PC gets special combat brain");
			if (testRoom.mode is RoomExplore) {
				Autotest.assertTrue(nei.brain is BrainFollow);
			} else if (testRoom.mode is RoomCombat) {
				Autotest.assertTrue(nei.brain is CombatBrainUiMeldPlayer);
			} else {
				Autotest.assertEqual(nei.brain, null);
			}
			
			Autotest.testActionFromXml(changeNeiToNpc);
			Autotest.assertEqual(room.entityInRoomWithId("nei"), nei, "Change pc-ness shouldn't change room or identity");
			Autotest.assertFalse(nei.isReallyPlayer, "Should have changed back to npc");
			Autotest.assertEqual(nei.faction, ComplexEntity.FACTION_ENEMY, "No faction specified npc should be enemy");
			Autotest.assertEqual(nei.exploreBrainClass, null, "No explore brain specified should default to null");
			Autotest.assertEqual(nei.combatBrainClass, CombatBrainNone, "No combat brain specified should default to CombatBrainNone");
			if (testRoom.mode is RoomCombat) {
				Autotest.assertTrue(nei.brain is CombatBrainNone);
			} else {
				Autotest.assertEqual(nei.brain, null);
			}
			
			testRoom.addOrMoveSpot("testSpot", new Point(0, 0));
			Autotest.testActionFromXml(changeNeiToPc);
			Autotest.testActionFromXml(changeNeiToNpcWithBrains);
			Autotest.assertEqual(nei.exploreBrainClass, BrainWander);
			Autotest.assertEqual(nei.combatBrainClass, CombatBrainPatrol);
			Autotest.assertEqual(nei.combatBrainParam, "3:testSpot");
			if (testRoom.mode is RoomExplore) {
				Autotest.assertTrue(nei.brain is BrainWander);
			} else if (testRoom.mode is RoomCombat) {
				Autotest.assertTrue(nei.brain is CombatBrainPatrol, "Note: This will fail if controlEnemies==true");
			} else {
				Autotest.assertEqual(nei.brain, null);
			}
			testRoom.removeSpot("testSpot");
			
			Autotest.testActionFromXml(changeNeiToPc);
			Autotest.testActionFromXml(removenei);
			Autotest.assertEqual(room.entityInRoomWithId("nei"), null, "nei should have been removed");
			
			var mainPcId:String = testRoom.mainPlayerCharacter.id;
			var changeMainPc:XML = changeNeiToNpc.copy();
			changeMainPc.@id = mainPcId;
			Autotest.testActionFromXml(changeMainPc);
			Autotest.assertAlerted("Attempt to change main pc to npc should give error");
		}
		
		/*
		 * Can't actually run this because it loads from file, which is a delayed callback.
		private static const changeRoom:XML = <changeRoom file="empty15x15.xml" />;
		private function testChangeRoom():void {
			var oldCurrentRoom:Room = testRoom;
			var mainPc:ComplexEntity = testRoom.mainPlayerCharacter;
			//UNDONE: this isn't at all a rigorous test; we don't have anything but the pc's in either room
			//also not testing mode, start spot
			testActionFromXml(changeRoom, true);
			Autotest.assertNoAlert();
			
			Autotest.assertNotEqual(oldCurrentRoom, testRoom, "Room didn't change");
			oldCurrentRoom = null;
			Autotest.assertEqual(mainPc.room, testRoom, "PC didn't move");
			Autotest.assertEqual(testRoom.mainPlayerCharacter, mainPc, "Same character should be main pc");
		}
		*/
		
		private const changeNeiSpot:XML = <change id="nei" spot="testSpot"/>;
		private const changeNeiWithXY:XML = <change id="nei" x="4" y="7" />;
		private const changeNeiSpotAndXY:XML = <change id="nei" spot="testSpot" x="1" y="1" />;
		private const changeNeiBrain:XML = <change id="nei" explore="wander" combat="patrol" combatParam="testSpot" />;
		private const clearNeiBrain:XML = <change id="nei" explore="" combat="" />;
		private const changeNeiToFriend:XML = <change id="nei" faction="1" />
		
		private const changeFoo:XML = <change id="foo" explore="wander" combat="patrol" combatParam="testSpot" spot="testSpot"/>;
		private const removeFoo:XML = <removeFromRoom id="foo" />;
		private function testChangeAction():void {
			var room:Room = testRoom;
			testRoom.addOrMoveSpot("testSpot", new Point(3, 5));
			
			Autotest.testActionFromXml(addneiAt12);
			var nei:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertTrue(nei.location.equals(new Point(1, 2)), "Initial location wrong");
			Autotest.testActionFromXml(changeNeiSpot);
			Autotest.assertTrue(nei.location.equals(new Point(3, 5)), "Didn't move correctly with spot");
			Autotest.testActionFromXml(changeNeiWithXY);
			Autotest.assertTrue(nei.location.equals(new Point(4, 7)), "Didn't move correctly with X & Y parameters");
			Autotest.testActionFromXml(changeNeiSpotAndXY);
			Autotest.assertAlertText("Script error in change: contains both spot and x,y");
			
			Autotest.testActionFromXml(changeNeiBrain);
			var neiComplex:ComplexEntity = ComplexEntity(nei);
			Autotest.assertEqual(neiComplex.exploreBrainClass, BrainWander);
			Autotest.assertEqual(neiComplex.combatBrainClass, CombatBrainPatrol);
			Autotest.assertEqual(neiComplex.combatBrainParam, "testSpot");
			if (testRoom.mode is RoomExplore) {
				Autotest.assertTrue(neiComplex.brain is BrainWander);
			} else if (testRoom.mode is RoomCombat) {
				Autotest.assertTrue(neiComplex.brain is CombatBrainPatrol, "Note: This will fail if controlEnemies==true");
			} else {
				Autotest.assertEqual(neiComplex.brain, null);
			}
			Autotest.testActionFromXml(clearNeiBrain);
			Autotest.assertEqual(neiComplex.exploreBrainClass, null);
			Autotest.assertEqual(neiComplex.combatBrainClass, CombatBrainNone);
			Autotest.assertEqual(neiComplex.combatBrainParam, null, "Removing behavior should auto-remove corresponding param");
			
			Autotest.assertEqual(neiComplex.faction, ComplexEntity.FACTION_ENEMY);
			var gotEvent:Boolean = false;
			Settings.gameEventQueue.addListener(this, neiComplex, EntityQEvent.CHANGED_FACTION, function(event:QEvent):void {
				gotEvent = true;
			});
			Autotest.testActionFromXml(changeNeiToFriend);
			Settings.gameEventQueue.removeAllListenersOwnedBy(this);
			Autotest.assertEqual(neiComplex.faction, ComplexEntity.FACTION_FRIEND);
			Autotest.assertTrue(gotEvent, "should have processed faction change listener");
			
			var fooXml:XML = <prop id="foo" x="6" y="5"/>
			var foo:SimpleEntity = SimpleEntity.createFromRoomContentsXml(fooXml, Settings.catalog);
			Autotest.clearAlert();
			Autotest.assertNotEqual(foo, null, "couldn't create prop foo");
			testRoom.addEntityUsingItsLocation(foo);
			Settings.gameEventQueue.handleEvents();
			var foo1:SimpleEntity = testRoom.entityInRoomWithId("foo");
			Autotest.assertEqual(foo, foo1, "foo not added to room");
			Autotest.assertTrue(foo.location.equals(new Point(6, 5)), "foo location wrong");
			
			Autotest.testActionFromXml(changeFoo);
			Autotest.assertNoAlert("Changing brains on simple entity should be ignored, not cause error");
			Autotest.assertTrue(foo.location.equals(new Point(3, 5)), "foo didn't move to spot");
			Autotest.testActionFromXml(removeFoo);
			
			Autotest.testActionFromXml(removenei);
			testRoom.removeSpot("testSpot");
		}
		
		private function testChangeMainPcAction():void {
			Autotest.testActionFromXml(<addNpc id="xxNewMainPc" />);
			Autotest.clearAlert(); // should alert the first time through because it's not in catalog
			Autotest.testActionFromXml(<changeToPc id="xxNewMainPc" />);
			//Autotest.clearAlert();
			var newPc:ComplexEntity = ComplexEntity(testRoom.entityInRoomWithId("xxNewMainPc"));
			Autotest.assertNotEqual(newPc, null, "xxNewMainPc should be in room now");
			
			var originalMainPcId:String = testRoom.mainPlayerCharacter.id;
			var changeMainPc:XML = <changeMainPc />;
			changeMainPc.@id = "xxNewMainPc";
			Autotest.testActionFromXml(changeMainPc);
			Autotest.assertEqual(testRoom.mainPlayerCharacter.id, "xxNewMainPc", "Main pc should have changed");
			Autotest.testActionFromXml(<removeFromRoom id="xxNewMainPc" />);
			Autotest.assertAlerted("Attempt to remove new main pc should fail");
			changeMainPc.@id = originalMainPcId;
			Autotest.testActionFromXml(changeMainPc);
			Autotest.assertEqual(testRoom.mainPlayerCharacter.id, originalMainPcId, "Main pc should have changed back");
			
			Autotest.testActionFromXml(<removeFromRoom id="xxNewMainPc" />);
			newPc = ComplexEntity(testRoom.entityInRoomWithId("xxNewMainPc"));
			Autotest.assertEqual(newPc, null, "remove should have succeeded now that it's not main pc any more");
		}
		
		
		private static const addGun:XML = <addToInventory id="nei" list="xxGun" />;
		private static const removeGun:XML = <removeFromInventory id="nei" list="xxGun" />;
		private static const checkGun:XML = <if>
			<inventoryHas id="nei" list="xxGun" />
			<script>
				<message text="yes" />
			</script>
		</if>;
		//Minimal testing of inventory functionality, that should be done directly in InventoryTest
		private function testInventoryActions():void {
			Settings.catalog.retrieveWeaponResource("xxGun");
			Autotest.clearAlert();
			
			Autotest.testActionFromXml(addneiAt12);
			var nei:ComplexEntity = ComplexEntity(testRoom.entityInRoomWithId("nei"));
			nei.inventory = new Inventory();
			
			Autotest.testActionFromXml(checkGun);
			Autotest.assertNoAlert();
			
			Autotest.testActionFromXml(removeGun);
			Autotest.assertAlertText("Remove from inventory: xxgun not found.");
			
			Autotest.testActionFromXml(addGun);
			Autotest.assertNoAlert();
			Autotest.assertEqual(nei.inventory.entriesInPileOfStuff(), 1, "Something got added");
			
			Autotest.testActionFromXml(checkGun);
			Autotest.assertAlertText("yes", "Says yes if gun found in inventory");
			
			Autotest.testActionFromXml(removeGun);
			Autotest.assertNoAlert();
			
			Autotest.testActionFromXml(checkGun);
			Autotest.assertNoAlert();
			
			Autotest.testActionFromXml(removenei);
		}
		
		
	} // end class ActionTest

}