package angel.game.script.action {
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class LoseGameAction implements IAction {
		
		private static const DEFAULT_MESSAGE:String = "You will need to try again\nto complete this combat.";
		private var text:String;
		
		public function LoseGameAction(text:String) {
			this.text = text;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			return new LoseGameAction(actionXml.text);
		}
		
		/* INTERFACE angel.game.script.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			context.pauseAndAddMessage(text == "" ? DEFAULT_MESSAGE : text);
			context.gameIsOver(true);
			return null;
		}
		
	}

}