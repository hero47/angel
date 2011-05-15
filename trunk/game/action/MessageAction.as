package angel.game.action {
	import angel.common.Alert;
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
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			Alert.show(message);
			return null;
		}
		
	}

}