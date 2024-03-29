package angel.game.test {
	import angel.common.Alert;
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.event.EventQueue;
	import angel.game.IAngelMain;
	import angel.game.InitGameFromFiles;
	import angel.game.Room;
	import angel.game.SaveGame;
	import angel.game.script.Script;
	import angel.game.Settings;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	import flash.utils.Timer;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class AaaaStartTestsFromHere extends Sprite implements IAngelMain {
		
		private var initTimer:Timer;
		private var gameInitialized:Boolean = false;
		
		public function AaaaStartTestsFromHere() {
			Autotest.runningFromRoot = this;
			Alert.testMode = true;
			runAllStandaloneTests();
			initializeGameAndRunAllGameTests();
		}
		
		private function standaloneTests():void {
			alertTest();
			Autotest.runTest(InventoryTest);
			Autotest.runTest(EventTest);
		}
		
		private function testsRequiringGameInit():void {
			Autotest.runTest(FlagTest);
			Autotest.runTest(ActionTest);
			Autotest.runTest(ConditionTest);
			Autotest.runTest(ComputationTest);
			Autotest.runTest(ExploreTest);
			Autotest.runTest(InventoryWithCatalogTest);
			return; //******************************************************** Stick this at top while working on new test
		}
		
		private function runAllStandaloneTests():void {
			Autotest.failCount = 0;
			standaloneTests();
			trace("Standalone tests finished, failCount", Autotest.failCount);
		}
		
		private function initializeGameAndRunAllGameTests():void {
			Settings.FRAMES_PER_SECOND = stage.frameRate;
			Settings.STAGE_HEIGHT = stage.stageHeight;
			Settings.STAGE_WIDTH = stage.stageWidth;
			Settings.gameEventQueue = new EventQueue();
			
			initTimer = new Timer(3000, 1);
			initTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timeout);
			initTimer.start();
			addEventListener(Event.ENTER_FRAME, waitingForInit);
			new InitGameFromFiles(gameInitializedCallback);
		}
		
		private function gameInitializedCallback(save:SaveGame):void {
			Autotest.clearAlert();
			gameInitialized = true;
		}
		
		private function waitingForInit(event:Event):void {
			Settings.gameEventQueue.handleEvents();
			if (gameInitialized) {
				initTimer.stop();
				removeEventListener(Event.ENTER_FRAME, waitingForInit);
				Autotest.failCount = 0;
				Autotest.assertEqual(numChildren, 0, "Initialization shouldn't create room or put anything on screen");
				testsRequiringGameInit();
				trace("Game tests finished, failCount", Autotest.failCount);
				var results:TextField = Util.textBox("Tests finished, failcount = " + Autotest.failCount, 600, 50, TextFormatAlign.CENTER, false, 0xffffff);
				results.x = (stage.stageWidth - results.width) / 2;
				results.y = (stage.stageHeight - results.height) / 2;
				addChild(results);
			}
		}
		
		private function timeout(event:TimerEvent):void {
			removeEventListener(Event.ENTER_FRAME, waitingForInit);
			trace("Initialization timeout. Alert:", Alert.messageForTestMode);
		}
		
		private function alertTest():void {
			Autotest.assertNoAlert("Shouldn't have seen alert yet");
			Alert.show("test");
			Autotest.assertAlertText("test", "Wrong message");
			Autotest.clearAlert();
		}
		
		public function get currentRoom():Room {
			return Autotest.testRoom;
		}
		
		public function startRoom(room:Room):void {
			if (currentRoom != null) {
				currentRoom.cleanup();
			}
			Autotest.testRoom = room;
			if (room != null) {
				addChildAt(room, 0);
			}
		}
		
		public function get asDisplayObjectContainer():DisplayObjectContainer {
			return this;
		}
		
	}

}