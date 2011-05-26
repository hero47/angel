package angel.game.event {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ListenerReference {
		public var owner:Object;
		public var eventSource:Object;
		public var eventId:String;
		public var callback:Function;
		public var optionalCallbackParam:Object;
		
		public function ListenerReference(owner:Object, eventSource:Object, eventId:String, callback:Function, optionalCallbackParam:Object) {
			this.owner = owner;
			this.eventSource = eventSource;
			this.eventId = eventId;
			this.callback = callback;
			this.optionalCallbackParam = optionalCallbackParam;
		}
		
		public function toString():String {
			return "[ListenerReference eventId=" + eventId + ", owner=" + owner + ", eventSource=" + eventSource + 
				(optionalCallbackParam == null ? "" : ", param=" + optionalCallbackParam) +	"]";
		}
		
	}

}