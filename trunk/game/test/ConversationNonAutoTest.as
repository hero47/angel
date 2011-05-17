package angel.game.test {
	import angel.game.script.ConversationData;
	import angel.game.Settings;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConversationNonAutoTest {
		private static var conversationData:ConversationData;
		
		public function ConversationNonAutoTest() {
			if (conversationData == null) {
				conversationData = new ConversationData();
				conversationData.addEventListener(Event.INIT, dataLoaded);
				conversationData.loadFromXmlFile("testActions.xml");
			} else {
				doTest();
			}
		}
		
		private function dataLoaded(event:Event):void {
			conversationData.removeEventListener(Event.INIT, dataLoaded);
			doTest();
		}
		
		private function doTest():void {
			Settings.currentRoom.startConversation(Settings.currentRoom.mainPlayerCharacter, conversationData);
		}
		
	}

}