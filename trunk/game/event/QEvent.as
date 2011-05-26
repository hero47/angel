package angel.game.event {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class QEvent {
		
		public var eventId:String;
		public var target:Object;
		public var currentTarget:Object;
		public var param:Object;
		
		public function QEvent(eventId:String, source:Object, param:Object = null) {
			this.eventId = eventId;
			this.target = this.currentTarget = source;
			this.param = param;
		}
		
		public function toString():String {
			return "[QEvent eventId=" + eventId + ", target=" + target + ", currentTarget=" + currentTarget + ", param=" + param + "]";
		}
		
	}

}