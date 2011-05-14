package angel.game.action {
	import angel.common.Alert;
	import angel.game.conversation.ConversationData;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConversationAction implements IAction {
		private var conversationData:ConversationData;
		private var targetId:String;
		
		public function ConversationAction(conversationData:ConversationData, targetId:String = null) {
			this.conversationData = conversationData;
			this.targetId = targetId;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var data:ConversationData = new ConversationData();
			data.initializeFromXml(actionXml, "");
			return new ConversationAction(data, actionXml.@id);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			doAtEnd.push(startConversation);
			return null;
		}
		
		private function startConversation():void {
			var targetEntity:SimpleEntity;
			if ((targetId != null) && (targetId != "")) {
				targetEntity = Settings.currentRoom.entityInRoomWithId(targetId);
			}
			if (targetEntity == null) {
				targetEntity = Settings.currentRoom.mainPlayerCharacter;
			}
			Settings.currentRoom.startConversation(targetEntity, conversationData);
		}
		
	}

}