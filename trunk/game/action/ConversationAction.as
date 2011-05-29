package angel.game.action {
	import angel.game.script.ConversationData;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
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
		
		public function doAction(context:ScriptContext):Object {
			context.doThisAtEnd(startConversation);
			return null;
		}
		
		private function startConversation(context:ScriptContext):void {
			var targetEntity:SimpleEntity;
			if ((targetId != null) && (targetId != "")) {
				targetEntity = context.entityWithScriptId(targetId);
			}
			if (targetEntity == null) {
				targetEntity = context.room.mainPlayerCharacter;
			}
			context.room.startConversation(targetEntity, conversationData);
		}
		
	}

}