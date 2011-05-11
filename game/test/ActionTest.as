package angel.game.test {
	import angel.common.CatalogEntry;
	import angel.common.Floor;
	import angel.game.action.Action;
	import angel.game.action.IAction;
	import angel.game.brain.BrainFidget;
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
		
		private var doAtEnd:Vector.<Function> = new Vector.<Function>();
		
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
			
			runTestsForMode(null);
			runTestsForMode(RoomExplore);
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
			
			var addFlag:IAction = Action.createFromXml(addTestFlag);
			var removeFlag:IAction = Action.createFromXml(removeTestFlag);
			addFlag.doAction(doAtEnd);
			Autotest.assertTrue(Flags.getValue("xxTest"));
			removeFlag.doAction(doAtEnd);
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
			Action.createFromXml(removenei).doAction(doAtEnd); // Removing entity that's not in room does nothing
			
			Autotest.assertEqual(room.entityInRoomWithId("nei"), null);
			Action.createFromXml(addnei).doAction(doAtEnd);
			var nei1:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertNotEqual(nei1, null, "nei should have been added to room");
			Autotest.assertTrue(nei1 is Walker);
			Autotest.assertTrue(nei1.location.equals(new Point(0, 0)), "Unspecified location should default to 0,0");
			
			Action.createFromXml(removenei).doAction(doAtEnd);
			Autotest.assertEqual(room.entityInRoomWithId("nei"), null, "nei should have been removed");
			
			Action.createFromXml(addneiAt12).doAction(doAtEnd);
			var nei2:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertTrue(nei2.location.equals(new Point(1, 2)), "Should use x & y if provided");
			room.removeEntityWithId("nei");
			
			Action.createFromXml(addneiAtTestSpot).doAction(doAtEnd);
			var nei3:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertAlerted("Undefined spot");
			Autotest.assertTrue(nei3.location.equals(new Point(0, 0)), "Should create at 0,0 if spot undefined");
			room.removeEntityWithId("nei");
			
			room.addOrMoveSpot("test", new Point(3, 4));
			Action.createFromXml(addneiAtTestSpot).doAction(doAtEnd);
			var nei4:SimpleEntity = room.entityInRoomWithId("nei");
			Autotest.assertTrue(nei4.location.equals(new Point(3, 4)), "Should create at 0,0 if spot undefined");
			room.removeEntityWithId("nei");
			room.removeSpot("test");
			
			Action.createFromXml(addNeiWithBrains).doAction(doAtEnd);
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
	}

}