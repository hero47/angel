package angel.game.event {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ListenerReferenceForOneEvent extends ListenerReference {
		public var originalEventSource:Object;
		public var eventParam:Object;
		
		public function ListenerReferenceForOneEvent(reference:ListenerReference, originalEventSource:Object, eventParam:Object) {
			super(reference.owner, reference.eventSource, reference.eventId, reference.callback, reference.optionalCallbackParam);
			this.originalEventSource = originalEventSource;
			this.eventParam = eventParam;
		}
		
		public function get event():QEvent {
			var event:QEvent = new QEvent(originalEventSource, eventId, eventParam);
			event.currentSource = eventSource;
			event.listenerParam = optionalCallbackParam;
			return event;
		}
		
		override public function toString():String {
			return "[ListenerReferenceForOneEvent eventId=" + eventId + ", owner=" + owner + ", eventSource=" + eventSource + 
				(optionalCallbackParam == null ? "" : ", param=" + optionalCallbackParam) +
				", originalEventSource=" + originalEventSource + ", eventParam=" + eventParam + "]";
		}
		
	}

}