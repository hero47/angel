package angel.game.test {
	import angel.game.event.QEvent;
	import angel.game.script.ConversationData;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConversationNonAutoTest {
		private static var conversationData:ConversationData;
		
		public function ConversationNonAutoTest() {
			if (conversationData == null) {
				conversationData = new ConversationData();
				Settings.gameEventQueue.addListener(this, conversationData, QEvent.INIT, dataLoaded);
				conversationData.loadFromXmlFile("testActions.xml");
			} else {
				doTest();
			}
		}
		
		private function dataLoaded(event:QEvent):void {
			Settings.gameEventQueue.removeListener(conversationData, QEvent.INIT, dataLoaded);
			doTest();
		}
		
		private function doTest():void {
			Settings.currentRoom.startConversation(Settings.currentRoom.mainPlayerCharacter, conversationData);
		}
		
	}

}