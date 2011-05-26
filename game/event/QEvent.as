package angel.game.event {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class QEvent {
		
		public var eventId:String;
		public var source:Object;
		public var currentSource:Object;
		public var param:Object;
		public var listenerParam:Object;
		
		public function QEvent(source:Object, eventId:String, param:Object = null) {
			this.eventId = eventId;
			this.source = source;
			this.param = param;
		}
		
		public function toString():String {
			return "[QEvent eventId=" + eventId + ", source=" + source + ", currentSource=" + currentSource + ", param=" + param + ", listenerParam=" + listenerParam + "]";
		}
		
	}

}