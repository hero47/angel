package angel.game.script.action {
	import angel.common.Alert;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class GotoAction implements IAction {
		private var id:String;
		private var topic:String;
		
		public function GotoAction(id:String, topic:String) {
			this.id = id;
			this.topic = topic;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var id:String = actionXml.@id;
			var topic:String = actionXml.@topic;
			if (topic == "") {
				topic = null;
			}
			if (id == "") {
				Alert.show("Error! Goto action with no id.");
				return null;
			}
			return new GotoAction(id, topic);
		}
		
		public function doAction(context:ScriptContext):Object {
			return { "topic":topic, "id":id };
		}
		
	}

}