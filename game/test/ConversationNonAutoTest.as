package angel.game.test {
	import angel.game.event.QEvent;
	import angel.game.Room;
	import angel.game.script.ConversationData;
	import angel.game.script.Script;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConversationNonAutoTest {
		private static var frobScript:Script;
		private var room:Room;
		
		public function ConversationNonAutoTest(room:Room) {
			this.room = room;
			if (frobScript == null) {
				frobScript = new Script();
				Settings.gameEventQueue.addListener(this, frobScript, QEvent.INIT, dataLoaded);
				frobScript.loadEntityScriptFromXmlFile("testActions.xml");
			} else {
				doTest();
			}
		}
		
		private function dataLoaded(event:QEvent):void {
			Settings.gameEventQueue.removeListener(frobScript, QEvent.INIT, dataLoaded);
			doTest();
		}
		
		private function doTest():void {
			frobScript.run(room, room.mainPlayerCharacter);
		}
		
	}

}