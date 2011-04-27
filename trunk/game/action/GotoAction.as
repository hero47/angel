package angel.game.action {
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
			return new GotoAction(id, topic);
		}
		
		public function doAction():Object {
			return { "topic":topic, "id":id };
		}
		
	}

}