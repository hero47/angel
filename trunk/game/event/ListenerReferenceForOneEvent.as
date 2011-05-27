package angel.game.event {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ListenerReferenceForOneEvent extends ListenerReference {
		private var myEvent:QEvent;
		
		public function ListenerReferenceForOneEvent(reference:ListenerReference, event:QEvent) {
			super(reference.owner, reference.eventSource, reference.eventId, reference.callback, reference.optionalCallbackParam);
			myEvent = event;
		}
		
		public function get event():QEvent {
			myEvent.currentSource = eventSource;
			myEvent.listenerParam = optionalCallbackParam;
			return myEvent;
		}
		
		override public function toString():String {
			return "[ListenerReferenceForOneEvent eventId=" + eventId + ", owner=" + owner + ", eventSource=" + eventSource + 
				(optionalCallbackParam == null ? "" : ", param=" + optionalCallbackParam) +
				", event=" + myEvent + "]";
		}
		
	}

}