package angel.game.test {
	import angel.common.Alert;
	import angel.game.event.EventQueue;
	import angel.game.InitGameFromFiles;
	import angel.game.Settings;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class AaaaStartTestsFromHere extends Sprite {
		
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
			Autotest.runTest(ExploreTest);
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
		
		private function gameInitializedCallback(initRoomXml:XML):void {
			//ignore the initRoomXml; any tests that want a room will make their own
			gameInitialized = true;
		}
		
		private function waitingForInit(event:Event):void {
			Settings.gameEventQueue.handleEvents();
			if (gameInitialized) {
				initTimer.stop();
				removeEventListener(Event.ENTER_FRAME, waitingForInit);
				Autotest.failCount = 0;
				Autotest.assertEqual(Settings.currentRoom, null, "Initialization shouldn't create room");
				testsRequiringGameInit();
				trace("Game tests finished, failCount", Autotest.failCount);
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
		
	}

}