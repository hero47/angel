package angel.game.action {
	import angel.common.Alert;
	import angel.game.Room;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class MessageAction implements IAction {
		private var message:String;
		
		public function MessageAction(message:String) {
			this.message = message;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			return new MessageAction(actionXml.@text);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			context.pauseAndAddMessage(message);
			return null;
		}
		
		
	}

}