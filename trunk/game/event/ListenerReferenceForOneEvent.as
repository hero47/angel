package angel.game.event {
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ListenerReferenceForOneEvent extends ListenerReference {
		public var originalTarget:Object;
		public var eventParam:Object;
		
		public function ListenerReferenceForOneEvent(reference:ListenerReference, originalTarget:Object, eventParam:Object) {
			super(reference.owner, reference.target, reference.eventId, reference.callback, reference.optionalCallbackParam);
			this.originalTarget = originalTarget;
			this.eventParam = eventParam;
		}
		
		public function get event():QEvent {
			var event:QEvent = new QEvent(originalTarget, eventId, eventParam);
			event.currentTarget = target;
			event.listenerParam = optionalCallbackParam;
			return event;
		}
		
		override public function toString():String {
			return "[ListenerReferenceForOneEvent eventId=" + eventId + ", owner=" + owner + ", target=" + target + 
				(optionalCallbackParam == null ? "" : ", param=" + optionalCallbackParam) +
				", originalTarget=" + originalTarget + ", eventParam=" + eventParam + "]";
		}
		
	}

}