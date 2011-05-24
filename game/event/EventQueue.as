package angel.game.event {
	import flash.display.Stage;
	import flash.events.Event;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// My own personal event handling system, separate and distinct from Flash's.
	// These events use a queue.  Dispatching an event adds it to the queue (normally at the back end) and immediately
	// returns -- unlike Flash events, the listeners are NOT called before returning.
	// (I'm going to start out with just adding to the back end; I'll add methods for "insert at front" and/or "process
	// listeners before returning" or any other special cases if/when I find a need for them.)
	//
	// CONSIDER: I may end up want to maintain one event queue for events that the game code itself is using, and a
	// separate one (with a different set of events) for the events used by the game's scripts (room onEnter, onMove,
	// etc.)  I haven't thought through the ramifications of this yet.  The question of whether the script events
	// should do their filtering all in a batch before any of the handlers trigger, or process the handlers sequentially,
	// filtering for each just before the handler executes, also needs to be considered and may influence this.
	//
	// When event queue is initialized, it sets up a Flash listener that will be called every frame to handle events.
	// (CONSIDER: should I not do this, and instead require the main program to explicitly call the event handler?
	// If I want a separate handler for script events, then I'll probably want that sort of direct control.)
	// The handler will process events from the front of the queue until empty, then return.
	//
	// (CONSIDER: could put a time check in, and release control once a certain amount of time has passed regardless
	// of whether the queue is empty or not; however, this would require all the code using the queue to be "safe" for
	// that sort of delayed processing -- allowing the screen to update while events are still pending could produce
	// very weird results.  A variant of this might make an useful debugging tool, though, allowing the screen
	// to update while stepping through events, accepting and glorifying in those intermediate weird results as
	// valuable debugging info.)
	//
	// CONSIDER: if a listener is added after an event is dispatched, but before the event is handled, should that
	// listener get called?  I was thinking yes.  But...
	// CONSIDER: if a listener is added DURING the processing of an event, should it get called???  I was thinking
	// not, which suggests that to handle an event, I should run through all the listeners, create a list of the ones that
	// need to be called, and then process THAT list rather than continuing to refer back to the full listener collection.
	// Which makes me question that first answer about listeners added after the event was dispatched.  Maybe the
	// list should be created at dispatch time???
	// Also, if a listener that hasn't been called yet is removed during the processing of an event, I'm thinking
	// it shouldn't be called -- I remember "ghosting" of things I thought had been deleted still hanging around and
	// receiving events caused surprises and headaches in MageTower.  So the remove would need to remove both from
	// the full collection and the temporary list, if there is a temporary list.
	// **** If possible, discuss with Mickey in terms of what rules he has found most useful in the past! ***
	//
	// Another issue I haven't thought through yet, jotting here so I don't forget:
	// an object may be trying to be deleted while it still has events pending that it's the source for
	// I think the event listeners may just need to be aware that this can happen, but that can lead to ugliness.
	// Providing a way for an object to retroactively delete any events that it generated that are still on the queue
	// would avoid those uglinesses, but first impressions is that that would wreak even more havoc on program logic.
	// Also, if we generate list of callbacks when we start handling an event, and then process it, an event source
	// could change its parent during one of the callbacks.  (More general case than trying to delete itself, which
	// would change parent to null.)
	//
	// QEvents do not go through the "capture" phase of Flash events; if I find a need for this, I can add it later.
	// QEvents include a "param" object that can be used to pass parameters, reducing the need to subclass QEvent.
	//
	// I do need the QEvents to go through a "bubbling" phase like Flash, so a listener can register for a container
	// object and get events from everything inside that container.  Initially, at least, I will continue to use the
	// Flash display list for this containment.
	// CONSIDER: might someday want a "containment" model to bubble events through separate from (or in addition to) the
	// display list.
	//
	// When registering an event listener, you pass the object that the listener belongs to as well as a callback function.
	// This allows us to provide methods for finding and cleaning up all listeners belonging to an object that
	// we want to free.  You can also pass along an arbitrary object for parameter(s) which will be passed back when
	// the listener is triggered, so you aren't forced to use an anonymous function just to provide access to context
	// information for the listener.  
	// NOTE: I was going to provide some sort of reference that can be used to remove that-particular-listener even if
	// it's an anonymous function, but I just discovered that Actionscript actually has one, completely unmentioned in
	// any of the documentation dealing with events and listeners: "arguments.callee".  I'm documenting it here!
	//
	// CONSIDER: do I need listener priority?  Probably.  (e.g. need to ensure that the "augmented reality" processes
	// entity movement before the minimap, because the minimap depends on visibility having been adjusted.)
	//
	// I also plan to provide methods for detecting and cleaning up all listeners on an object, in addition to
	// all listeners belonging to an object.
	// 
	
	public class EventQueue {
		
		private var queue:Vector.<QEvent> = new Vector.<QEvent>();
		private var lookup:Dictionary; // map event source to (associative array mapping eventId to Vector.<ListenerReference>)
		
		public function EventQueue(stage:Stage) {
			if (singleton != null) {
				trace("ERROR: creating second instance of EventQueue");
				return;
			}
			singleton = this;
			stage.addEventListener(Event.ENTER_FRAME, handleEvents);
		}
		
		public function dispatch(event:QEvent):void {
			queue.push(event);
		}
		
		public function addListener(owner:Object, target:Object, eventId:String, callback:Function, optionalCallbackParam:Object = null):void {
			var listener = new ListenerReference(owner, target, eventId, callback, optionalCallbackParam);
			//UNDONE priority
			var listenersOnThisTarget:Object = lookup[target];
			if (listenersOnThisTarget == null) {
				lookup[target] = listenersOnThisTarget = new Object();
			}
			var forThisEvent:Vector.<ListenerReference> = listenersOnThisTarget[eventId];
			if (forThisEvent == null) {
				listenersOnThisTarget[eventId] = forThisEvent = new Vector.<ListenerReference>();
			}
			forThisEvent.push(listener);
		}
		
		public function removeListener(target:Object, eventId:String, callback:Function):void {
			var listenersOnThisTarget:Object = lookup[target];
			if (listenersOnThisTarget == null) {
				return;
			}
			var list:Vector.<ListenerReference> = listenersOnThisTarget[eventId];
			if (list == null) {
				return;
			}
			
			for (var i:int = 0; i < list.length; ++i) {
				if (list[i].callback == callback) {
					list.splice(i, 1);
					break;
				}
			}
			if (list.length == 0) {
				listenersOnThisTarget[eventId] = null;
			}
		}
		
		public function removeAllListenersOn(target:Object):void {
			lookup[target] = null;
		}
		
		public function removeAllListenersOwnedBy(owner:Object):void {
			for (var target:Object in lookup) {
				var listenersOnThisTarget:Object = lookup[target];
				if (listenersOnThisTarget == null) {
					continue;
				}
				for (var eventId:String in listenersOnThisTarget) {
					var list:Vector.<ListenerReference> = listenersOnThisTarget[eventId];
					if (list != null) {
						deleteFromListIfOwnedBy(list, owner);
					}
					if (list.length == 0) {
						listenersOnThisTarget[eventId] = null;
					}
				}
				if (isEmpty(listenersOnThisTarget)) {
					delete lookup[target];
				}
			}
		}
		
		private function deleteFromListIfOwnedBy(list:Vector.<ListenerReference>, owner:Object):void {
			var i:int = 0;
			while (i < list.length) {
				if (list[i].owner == owner) {
					list.splice(i, 1);
				} else {
					i++;
				}
			}
		}
		
		
		private function handleEvents():void {
			while (queue.length > 0) {
				handleOneEvent(queue.shift());
			}
		}
		
		private function handleOneEvent(event:QEvent):void {
			// See notes at top, section ending with
	// **** If possible, discuss with Mickey in terms of what rules he has found most useful in the past! ***
			// May want callbacks to be a class variable, so the "removeAll" functions can remove
			// from there, too.
			var callbacks:Vector.<CallbackInfo> = new Vector.<CallbackInfo>();
			var currentTarget:Object = event.target;
			do {
				var listeners:Vector.<ListenerReference> = findListenersFor(currentTarget, event.eventId);
				if (listeners != null) {
					for each (var oneListener:ListenerReference in listeners) {
						callbacks.push(new CallbackInfo(oneListener.callback, oneListener.optionalCallbackParam, currentTarget));
					}
				}
				currentTarget = currentTarget.parent;
			} while (currentTarget != null);
			
			while (callbacks.length > 0) {
				var oneCallback:CallbackInfo = callbacks.shift();
				event.currentTarget = oneCallback.currentTarget;
				oneCallback.callback(event, oneCallback.optionalCallbackParam);
			}
		}
		
		private function findListenersFor(target:Object, eventId:String):Vector.<ListenerReference> {
			var listenersOnThisTarget:Object = lookup[target];
			if (listenersOnThisTarget == null) {
				return null;
			}
			return listenersOnThisTarget[eventId];
		}
		
		private function isEmpty(associativeArray:Object):Boolean {
			for (var foo:String in associativeArray) {
				return false;
			}
			return true;
		}
		
	}

}

class ListenerReference {
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
}

class CallbackInfo {
	public var callback:Function;
	public var optionalCallbackParam:Object;
	public var currentTarget:Object;
	public function CallbackInfo(callback:Function, optionalCallbackParam:Object, currentTarget:Object):void {
		this.callback = callback;
		this.optionalCallbackParam = optionalCallbackParam;
		this.currentTarget = currentTarget;
	}
}

