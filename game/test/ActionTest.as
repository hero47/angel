package angel.game.test {
	import angel.game.conversation.ConversationData;
	import angel.game.Room;
	import angel.game.Settings;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ActionTest {
		private static var conversationData:ConversationData;
		
		public function ActionTest() {
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