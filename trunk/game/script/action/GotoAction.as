package angel.game.script.action {
	import angel.common.Alert;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class GotoAction implements IAction {
		private var id:String;
		private var topic:String;
		
		public static const TAG:String = "goto";
		
		public function GotoAction(id:String, topic:String) {
			this.id = id;
			this.topic = topic;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "id", actionXml)) {
				return null;
			}
			var topic:String = actionXml.@topic;
			if (topic == "") {
				topic = null;
			}
			return new GotoAction(actionXml.@id, topic);
		}
		
		public function doAction(context:ScriptContext):Object {
			return { "topic":topic, "id":id };
		}
		
	}

}