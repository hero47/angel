package angel.game.script {
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ConversationEvent extends Event {
		public static const ENTRY_FINISHED:String = "EntryFinished";
		
		public var choice:ConversationSegment;
		
		public function ConversationEvent(type:String, choice:ConversationSegment = null, bubbles:Boolean = false, cancelable:Boolean = false) { 
			this.choice = choice;
			super(type, bubbles, cancelable);
		} 
		
		public override function clone():Event { 
			return new ConversationEvent(type, choice, bubbles, cancelable);
		} 
		
		public override function toString():String { 
			return formatToString("ConversationEvent", "type", "choice", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}