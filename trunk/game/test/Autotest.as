package angel.game.test {
	import angel.common.Alert;
	import angel.common.Floor;
	import angel.game.brain.CombatBrainWander;
	import angel.game.ComplexEntity;
	import angel.game.Room;
	import angel.game.SaveGame;
	import angel.game.script.action.ActionFactory;
	import angel.game.script.action.IAction;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	import flash.display.Sprite;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Autotest {
		
		public static var failCount:int = 0;
		public static var runningFromRoot:Sprite;
		public static var testRoom:Room = null;
		public static const TEST_ROOM_MAIN_PC_ID:String = "xxMainPc";
		public static const TEST_ROOM_ENEMY_ID:String = "xxEnemy";
		
		public function Autotest() {
		}
		
		public static function assertTrue(test:Boolean, message:String = ""):void {
			if (!test) {
				fail(message);
			}
		}
		
		public static function assertFalse(test:Boolean, message:String = ""):void {
			if (test) {
				fail(message);
			}
		}
		
		public static function assertEqual(val1:*, val2:*, message:String = ""):void {
			if (val1 != val2) {
				fail("[" + val1 + "] != [" + val2 + "] " + message);
			}
		}
		
		public static function assertNotEqual(val1:*, val2:*, message:String = ""):void {
			if (val1 == val2) {
				fail("[" + val1 + "] " + message);
			}
		}
		
		public static function assertClass(val1:*, val2:Class, message:String = ""):void {
			if (!(val1 is val2)) {
				fail("[" + val1 + "] is not [" + val2 + "] " + message);
			}
		}
		
		public static function clearAlert():void {
			Alert.messageForTestMode = null;
		}
		
		public static function assertNoAlert(message:String = ""):void {
			if (Alert.messageForTestMode != null) {
				fail("Alert: [" + Alert.messageForTestMode + "] " + message);
			}
			clearAlert();
		}
		
		public static function assertAlerted(message:String = ""):void {
			if (Alert.messageForTestMode == null) {
				fail("Should have alerted. " + message);
			}
			clearAlert();
		}
		
		public static function assertAlertText(text:String, message:String = ""):void {
			if (Alert.messageForTestMode != text) {
				fail("Alert [" + Alert.messageForTestMode + "], expected [" + text + "] " + message);
			}
			clearAlert();
		}
		
		public static function fail(message:String):void {
			trace(failureFileAndLineNumber(), message);
			failCount++;
		}
		
		public static function runTest(testClass:Class):void {
			trace("Running:", testClass);
			clearAlert();
			new testClass();
			assertNoAlert("Something in " + testClass + " caused an alert.");
			if (Settings.gameEventQueue != null) {
				assertEqual(Settings.gameEventQueue.numberOfCallbacksWaitingProcessing(), 0, "Queue has leftover events after "+ testClass);
			}
		}
		
		public static function testFunction(testFunction:Function):void {
			assertNoAlert("Leftover alert before testFunction");
			testFunction();
			assertNoAlert("Something in a tested function caused an alert.");
			if (Settings.gameEventQueue != null) {
				assertEqual(Settings.gameEventQueue.numberOfCallbacksWaitingProcessing(), 0, "Queue has leftover events after tested function");
			}
		}
		
		private static function failureFileAndLineNumber(): String {
			try { throw new Error(); }
			catch (e:Error) { 
				return firstNonAutotestFileAndLine(e.getStackTrace()); 
			}
			return "";
		}

		public static function firstNonAutotestFileAndLine(stack:String):String {
			var lines:Array = stack.split("\n");
			// line 0 is just "Error", skip it
			for (var i:int = 1; i < lines.length; i++) {
				if (lines[i].indexOf("Autotest") < 0) {
					var lastBackslash:int = lines[i].lastIndexOf("\\");
					return "[" + lines[i].substr(lastBackslash + 1);
				}
			}
			return "?";
			/* Full stack trace:			
			// remove the path
			// it's too long and we can get the info from the method trace
			var regEx:RegExp = /\w:[\\\/]([\w-]+[\\\/])*\w+.as/ig;
			var newStack:String = new String("\n");
			for (var i:int = 0; i < lines.length; i++) {
				var line:String = lines[i];
				line = line.replace(regEx, "");
				line = line.replace("[:", " [line:");
				newStack = newStack + line + "\n";
			}
			return newStack;
			*/
		}
		
		private static const floorXml:XML = <floor x="10" y="10"/>;
		public static function setupTestRoom():Room {
			Autotest.assertEqual(testRoom, null, "Test room didn't get cleaned up by previous test");
			
			var save:SaveGame = new SaveGame();
			var playerInitXml:XML = <init><player><pc /></player></init>;
			playerInitXml.player.pc.@id = TEST_ROOM_MAIN_PC_ID;
			save.initPlayerInfoFromXml(playerInitXml.player, Settings.catalog);
			save.startLocation = new Point(9, 8);
			
			var enemy:ComplexEntity = new ComplexEntity(Settings.catalog.retrieveCharacterResource(TEST_ROOM_ENEMY_ID), TEST_ROOM_ENEMY_ID);
			Autotest.clearAlert(); // should alert the first time we're called, since these aren't in catalog
			enemy.combatBrainClass = CombatBrainWander;
			
			var floor:Floor = new Floor();
			floor.loadFromXml(Settings.catalog, floorXml);
			
			testRoom = new Room(floor);
			save.addPlayerCharactersToRoom(testRoom);
			testRoom.addEntity(enemy, new Point(8, 9));
			
			Autotest.runningFromRoot.addChild(testRoom);
			Autotest.assertNoAlert();
			Settings.gameEventQueue.handleEvents();
			Autotest.assertNoAlert();
			
			return testRoom;
		}
		
		public static function cleanupTestRoom():void {
			testRoom.cleanup();
			testRoom = null;
		}
		
		public static function testActionFromXml(xml:XML, shouldDelayUntilEnd:Boolean = false):void {
			Autotest.assertEqual(Settings.gameEventQueue.numberOfCallbacksWaitingProcessing(), 0, "Queue not empty before testing action");
			var context:ScriptContext = new ScriptContext(testRoom);
			var action:IAction = ActionFactory.createFromXml(xml);
			Autotest.assertNoAlert();
			Autotest.assertNotEqual(action, null, "Action creation failed");
			if (action != null) {
				action.doAction(context);
				Autotest.assertEqual(context.hasEndOfScriptActions(), shouldDelayUntilEnd, "Wrong delay status");
				context.endOfScriptActions();
			}
			Settings.gameEventQueue.handleEvents();
			Autotest.assertTrue((testRoom == null) || !testRoom.gameTimeIsPaused(), "Action left room paused");
		}
		
		
	}

}