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
		public var listenerParam:Object;
		
		public function QEvent(source:Object, eventId:String, param:Object = null) {
			this.eventId = eventId;
			this.target = source;
			this.param = param;
		}
		
		public function toString():String {
			return "[QEvent eventId=" + eventId + ", target=" + target + ", currentTarget=" + currentTarget + ", param=" + param + "]";
		}
		
	}

}