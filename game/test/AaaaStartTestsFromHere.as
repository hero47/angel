package angel.game.test {
	import angel.common.Alert;
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
		
		public function AaaaStartTestsFromHere() {
			Autotest.runningFromRoot = this;
			Alert.testMode = true;			
			runAllStandaloneTests();
			initializeGameAndRunAllGameTests();
		}
		
		private function standaloneTests():void {
			alertTest();
			Autotest.runTest(InventoryTest);
		}
		
		private function testsRequiringGameInit():void {
			Autotest.runTest(ActionTest);
		}
		
		private function runAllStandaloneTests():void {
			Autotest.failCount = 0;
			standaloneTests();
			trace("Standalone tests finished, failCount", Autotest.failCount);
		}
		
		private function initializeGameAndRunAllGameTests():void {
			initTimer = new Timer(3000, 1);
			initTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timeout);
			initTimer.start();
			new InitGameFromFiles(gameInitializedCallback);
		}
		
		private function gameInitializedCallback(xml:XML):void {
			initTimer.stop();
			Autotest.failCount = 0;
			testsRequiringGameInit();
			trace("Game tests finished, failCount", Autotest.failCount);
			if (Settings.currentRoom != null) {
				
			}
		}
		
		private function timeout(event:TimerEvent):void {
			trace("Initialization timeout reached. Alert:", Alert.messageForTestMode);
		}
		
		private function alertTest():void {
			Autotest.assertNoAlert("Shouldn't have seen alert yet");
			Alert.show("test");
			Autotest.assertAlertText("test", "Wrong message");
			Autotest.clearAlert();
		}
		
	}

}