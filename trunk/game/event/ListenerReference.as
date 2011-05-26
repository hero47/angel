package angel.game.event {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ListenerReference {
		public var owner:Object;
		public var target:Object;
		public var eventId:String;
		public var callback:Function;
		public var optionalCallbackParam:Object;
		
		public function ListenerReference(owner:Object, target:Object, eventId:String, callback:Function, optionalCallbackParam:Object) {
			this.owner = owner;
			this.target = target;
			this.eventId = eventId;
			this.callback = callback;
			this.optionalCallbackParam = optionalCallbackParam;
		}
		
		public function toString():String {
			return "[ListenerReference eventId=" + eventId + ", owner=" + owner + ", target=" + target + 
				(optionalCallbackParam == null ? "" : ", param=" + optionalCallbackParam) +	"]";
		}
		
	}

}