package angel.game.script.action {
	import angel.common.Util;
	import angel.game.ComplexEntity;
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
		private var playerId:String;
		private var targetId:String;
		
		public static const TAG:String = "conversation";
		
		public function ConversationAction(conversationData:ConversationData, targetId:String = null, playerId:String = null) {
			this.conversationData = conversationData;
			this.targetId = targetId;
			this.playerId = playerId;
		}
		
		public static function createFromXml(actionXml:XML, rootScript:Script):IAction {
			var data:ConversationData = new ConversationData();
			data.initializeFromXml(actionXml, rootScript);
			return new ConversationAction(data, actionXml.@id, actionXml.@pc);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			context.doThisAtEnd(startConversation);
			return null;
		}
		
		private function startConversation(context:ScriptContext):void {
			var targetEntity:SimpleEntity;
			var playerEntity:ComplexEntity;
			var conversationContext:ScriptContext = context.cloneSettings();
			if (!Util.nullOrEmpty(playerId)) {
				conversationContext.setSpecialId(Script.TRIGGERING_ENTITY, targetEntity);
			}
			if (!Util.nullOrEmpty(targetId)) {
				conversationContext.setSpecialId(Script.ACTIVE_PLAYER, targetEntity);
			}
			context.room.startConversation(conversationContext, conversationData);
		}
		
	}

}