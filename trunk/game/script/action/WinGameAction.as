package angel.game.script.action {
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class WinGameAction implements IAction {
		
		private static const DEFAULT_MESSAGE:String = "Congratulations! You have finished the game.";
		private var text:String;
		
		public static const TAG:String = "winGame";
		
		public function WinGameAction(text:String) {
			this.text = text;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			return new WinGameAction(actionXml.text);
		}
		
		/* INTERFACE angel.game.script.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			context.pauseAndAddMessage(text == "" ? DEFAULT_MESSAGE : text);
			context.gameIsOver(false);
			return null;
		}
		
	}

}