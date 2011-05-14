package angel.game.test {
	import angel.common.CatalogEntry;
	import angel.common.Floor;
	import angel.game.action.Action;
	import angel.game.action.IAction;
	import angel.game.brain.BrainFidget;
	import angel.game.brain.BrainFollow;
	import angel.game.brain.BrainWander;
	import angel.game.brain.CombatBrainPatrolWalk;
	import angel.game.brain.CombatBrainWander;
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.Flags;
	import angel.game.InitGameFromFiles;
	import angel.game.Room;
	import angel.game.RoomExplore;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import angel.game.Walker;
	import flash.display.Stage;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ActionTest {
		
		private const floorXml:XML = <floor x="10" y="10"/>;
		
		
		//CONSIDER: Parts of this are really flag tests and catalog tests, could be separated out
		//CONSIDER: Room initialization will probably want to be pulled out so other tests can use it as well
		public function ActionTest() {
			Autotest.testFunction(testFlagActions);
			
			var xxTest:Walker = new Walker(Settings.catalog.retrieveWalkerImage("xxTest"), "xxTest");
			Autotest.assertAlertText("Error: xxTest not in catalog.");
			Autotest.assertNotEqual(xxTest, null, "Should create with default settings if not in catalog");
			var xxTest2:Walker = new Walker(Settings.catalog.retrieveWalkerImage("xxTest"), "xxTest");
			Autotest.assertNoAlert("No alert expected on second reference to unknown id");
			
			// Explore mode requires a player character.
			// Combat mode requires a player character and an enemy (or it will immediately declare that combat is over).
			var mainPcId:String = "mainPcForTesting";
			while (Settings.catalog.entry(mainPcId) != null) {
				mainPcId += "X";
			}
			var enemyId:String = "enemyForTesting";
			while (Settings.catalog.entry(enemyId) != null) {
				enemyId += "X";
			}
			var mainPc:Walker = new Walker(Settings.catalog.retrieveWalkerImage(mainPcId), mainPcId);
			var enemy:Walker = new Walker(Settings.catalog.retrieveWalkerImage(mainPcId), enemyId);
			enemy.combatBrainClass = CombatBrainWander;
			Autotest.assertAlerted("Catalog should have alerted and then created default WalkerImage");
			
			var floor:Floor = new Floor();
			floor.loadFromXml(Settings.catalog, floorXml);			
			Settings.currentRoom = new Room(floor);
			Settings.currentRoom.addPlayerCharacter(mainPc, new Point(9, 8));
			Settings.currentRoom.addEntity(enemy, new Point(8, 9));
			
			Autotest.runningFromRoot.addChild(Settings.currentRoom);
			Autotest.assertNoAlert();
			
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
			
			Autotest.testFunction(testAddRemoveCharacterActions);
			Autotest.testFunction(testChangeToFromPc);
			//Autotest.testFunction(testChangeRoom); This doesn't work because it uses a callback
			
			Settings.currentRoom.changeModeTo(null);
			Autotest.assertEqual(Settings.currentRoom.mode, null, modeChangeFail);
		}
		
		private const addTestFlag:XML = <add flag="xxTest" />;
		private const removeTestFlag:XML = <remove flag="xxTest" />;
		private function testFlagActions():void {
			var value:Boolean = Flags.getValue("xxTest");
			Autotest.assertAlertText("Warning: unknown flag [xxTest].", "First reference to unknown flag should alert");
			Autotest.assertFalse(value, "Default flag value is false");
			value = Flags.getValue("xxTest");
			Autotest.assertNoAlert("Second reference should not alert");
			
			testActionFromXml(addTestFlag);
			Autotest.assertTrue(Flags.getValue("xxTest"));
			testActionFromXml(removeTestFlag);
			Autotest.assertFalse(Flags.getValue("xxTest"));
		}
		
		private const addnei:XML = <addNpc id="nei" />;
		private const removenei:XML = <removeFromRoom id="nei" />;
		private const addneiAt12:XML = <addNpc id="nei" x="1" y="2" />;
		private const addneiAtTestSpot:XML = <addNpc id="nei" spot="test" />;
		private const addNeiWithBrains:XML = <addNpc id="nei" explore="fidget" combat="wander" />
		
		private function testAddRemoveCharacterActions():void {
			var entry:CatalogEntry = Settings.catalog.entry("nei");
			var neiOK:Boolean = (entry != null) && (entry.type == CatalogEntry.WALKER);
			Autotest.assertTrue(neiOK, "This test requires nei character in catalog.");
			if (!neiOK) {
				return;
			}
			
			var room:Room = Settings.currentRoom;
			
			Autotest.assertEqual(room.entityInRoomWithId("nei"), null);
			testActionFromXml(removenei); // Removing entity that's not in room does nothing
			
			Autotest.assertEqual(room.entityInRoomWithId("nei"), null);
			testActionFromXml(addnei);
			var nei:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertNotEqual(nei, null, "nei should have been added to room");
			Autotest.assertTrue(nei is Walker);
			Autotest.assertFalse(Walker(nei).isReallyPlayer, "Should be npc");
			Autotest.assertTrue(nei.location.equals(new Point(0, 0)), "Unspecified location should default to 0,0");
			Autotest.assertFalse(Settings.isOnPlayerList(nei));
			
			testActionFromXml(removenei);
			Autotest.assertEqual(room.entityInRoomWithId("nei"), null, "nei should have been removed");
			
			testActionFromXml(addneiAt12);
			var nei2:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertTrue(nei2.location.equals(new Point(1, 2)), "Should use x & y if provided");
			room.removeEntityWithId("nei");
			
			testActionFromXml(addneiAtTestSpot);
			var nei3:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertAlerted("Undefined spot");
			Autotest.assertTrue(nei3.location.equals(new Point(0, 0)), "Should create at 0,0 if spot undefined");
			room.removeEntityWithId("nei");
			
			room.addOrMoveSpot("test", new Point(3, 4));
			testActionFromXml(addneiAtTestSpot);
			var nei4:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertTrue(nei4.location.equals(new Point(3, 4)), "Should create at 0,0 if spot undefined");
			room.removeEntityWithId("nei");
			room.removeSpot("test");
			
			testActionFromXml(addNeiWithBrains);
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
			room.removeEntityWithId("nei");
		}
		
		private const changeNeiToPc:XML = <changeToPc id="nei" />;
		private const changeNeiToNpc:XML = <changeToNpc id="nei" />;
		private const changeNeiToNpcWithBrains:XML = <changeToNpc id="nei" explore="wander" combat="patrolWalk" />
		
		private function testChangeToFromPc():void {
			var room:Room = Settings.currentRoom;
			
			testActionFromXml(changeNeiToPc);
			Autotest.assertAlertText("Script error: no character nei in room for changeToPc");			
			
			testActionFromXml(changeNeiToNpc);
			Autotest.assertAlertText("Script error: no character nei in room for changeToNpc");
			
			testActionFromXml(addNeiWithBrains);
			var nei:ComplexEntity = ComplexEntity(room.entityInRoomWithId("nei"));
			Autotest.assertFalse(nei.isReallyPlayer, "Should be npc");
			Autotest.assertFalse(Settings.isOnPlayerList(nei), "Npc shouldn't be on player list");
			
			testActionFromXml(changeNeiToNpc);
			Autotest.assertNoAlert("Change to Npc does nothing if entity is already npc");
			
			testActionFromXml(changeNeiToPc);
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
			
			testActionFromXml(changeNeiToNpc);
			Autotest.assertEqual(room.entityInRoomWithId("nei"), nei, "Change pc-ness shouldn't change room or identity");
			Autotest.assertFalse(nei.isReallyPlayer, "Should have changed back to npc");
			Autotest.assertFalse(Settings.isOnPlayerList(nei), "Should have removed from player list");
			Autotest.assertEqual(nei.exploreBrainClass, null, "No explore brain specified should default to null");
			Autotest.assertEqual(nei.combatBrainClass, null, "No combat brain specified should default to null");
			Autotest.assertEqual(nei.brain, null);
			
			testActionFromXml(changeNeiToPc);
			testActionFromXml(changeNeiToNpcWithBrains);
			Autotest.assertEqual(nei.exploreBrainClass, BrainWander);
			Autotest.assertEqual(nei.combatBrainClass, CombatBrainPatrolWalk);
			if (Settings.currentRoom.mode is RoomExplore) {
				Autotest.assertTrue(nei.brain is BrainWander);
			} else if (Settings.currentRoom.mode is RoomCombat) {
				Autotest.assertTrue(nei.brain is CombatBrainPatrolWalk, "Note: This will fail if controlEnemies==true");
			} else {
				Autotest.assertEqual(nei.brain, null);
			}
			
			testActionFromXml(changeNeiToPc);
			testActionFromXml(removenei);
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
		
		private function testActionFromXml(xml:XML, shouldDelayUntilEnd:Boolean = false):void {
			var doAtEnd:Vector.<Function> = new Vector.<Function>();
			var action:IAction = Action.createFromXml(xml);
			Autotest.assertNoAlert();
			Autotest.assertNotEqual(action, null, "Action creation failed");
			if (action != null) {
				action.doAction(doAtEnd);
				Autotest.assertEqual(shouldDelayUntilEnd, doAtEnd.length > 0, "Wrong delay status");
				while (doAtEnd.length > 0) {
					var doThis:Function = doAtEnd.shift();
					doThis();
				}
			}
		}
		
		
	} // end class ActionTest

}