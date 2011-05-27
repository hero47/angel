package angel.game.event {
	import angel.common.Assert;
	import flash.display.DisplayObject;
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
		private var callbacks:Vector.<ListenerReference> = new Vector.<ListenerReference>(); // Callbacks for the event currently being handled
		private var lookup:Dictionary = new Dictionary(); // map event source to (associative array mapping eventId to Vector.<ListenerReference>)
		private var handlingEvents:Boolean;
		
		public function EventQueue() {
		}
		
		public function dispatch(event:QEvent):void {
			queue.push(event);
		}
		
		public function addListener(owner:Object, eventSource:Object, eventId:String, callback:Function, optionalCallbackParam:Object = null):void {
			var listener:ListenerReference = new ListenerReference(owner, eventSource, eventId, callback, optionalCallbackParam);
			//UNDONE priority
			var listenersOnThisSource:Object = lookup[eventSource];
			if (listenersOnThisSource == null) {
				lookup[eventSource] = listenersOnThisSource = new Object();
			}
			var forThisEvent:Vector.<ListenerReference> = listenersOnThisSource[eventId];
			if (forThisEvent == null) {
				listenersOnThisSource[eventId] = forThisEvent = new Vector.<ListenerReference>();
			}
			
			// CONSIDER: If this listener duplicates one that's already in the queue, should it be an error?
			// Initial decision: if the param is identical, just ignore it. If param is different, replace
			// the existing listener and assert.
			for (var i:int = 0; i < forThisEvent.length; ++i) {
				if (forThisEvent[i].callback == callback) {
					if (forThisEvent[i].optionalCallbackParam !== optionalCallbackParam) {
						Assert.fail("Overwriting an event listener");
						forThisEvent[i] = listener;
					}
					return;
				}
			}
			forThisEvent.push(listener);
		}
		
		public function removeListener(source:Object, eventId:String, callback:Function):void {
			var listenersOnThisSource:Object = lookup[source];
			if (listenersOnThisSource == null) {
				return;
			}
			var list:Vector.<ListenerReference> = listenersOnThisSource[eventId];
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
				listenersOnThisSource[eventId] = null;
			}
			
			//NOTE: unclear whether I should do this, but I think benefits outweigh drawbacks
			removeFromCallbacksIfMatch(source, eventId, callback);
		}
		
		private function removeFromCallbacksIfMatch(eventSource:Object, eventId:String, callback:Function):void {
			var i:int = 0;
			while (i < callbacks.length) {
				if ((callbacks[i].eventSource == eventSource) && (callbacks[i].eventId == eventId) && (callbacks[i].callback == callback)) {
					callbacks.splice(i, 1);
				} else {
					i++;
				}
			}
		}
		
		public function removeAllListenersOn(source:Object):void {
			lookup[source] = null;
			//NOTE: unclear whether I should do this, but I think benefits outweigh drawbacks
			deleteReferencesWithThisEventSource(callbacks, source);
		}
		
		public function removeAllListenersOwnedBy(owner:Object):void {
			for (var source:Object in lookup) {
				var listenersOnThisSource:Object = lookup[source];
				if (listenersOnThisSource == null) {
					continue;
				}
				for (var eventId:String in listenersOnThisSource) {
					var list:Vector.<ListenerReference> = listenersOnThisSource[eventId];
					if (list != null) {
						deleteReferencesOwnedBy(list, owner);
						if (list.length == 0) {
							delete listenersOnThisSource[eventId];
						}
					}
				}
				if (isEmpty(listenersOnThisSource)) {
					delete lookup[source];
				}
			}
			//NOTE: unclear whether I should do this, but I think benefits outweigh drawbacks
			deleteReferencesOwnedBy(callbacks, owner);
		}
		
		private function deleteReferencesOwnedBy(list:Vector.<ListenerReference>, owner:Object):void {
			var i:int = 0;
			while (i < list.length) {
				if (list[i].owner == owner) {
					list.splice(i, 1);
				} else {
					i++;
				}
			}
		}
		
		private function deleteReferencesWithThisEventSource(list:Vector.<ListenerReference>, eventSource:Object):void {
			var i:int = 0;
			while (i < list.length) {
				if (list[i].eventSource == eventSource) {
					list.splice(i, 1);
				} else {
					i++;
				}
			}
		}
		
		// Make a list of all callback info for listeners *as they currently exist*, before any of the events are processed.
		// Then process them.  Repeat until the queue stays empty.
		// The following current choices are subject to change after talking with Mickey; they
		// are based on my current intuitions and usage guesses.
		// Once this processing has started
		// * Listeners newly added will not trigger
		// * Listeners individually removed (before they're reached) will not trigger
		// * Listeners removed by removeAllListenersOwnedBy (before they're reached) will not trigger
		// * Listeners removed by removeAllListenersOn (before they're reached) will not trigger
		// (I'm still waffling over this, and unless Mickey provides some insight, I may continue
		// to waffle until I come to a case in my non-test code where it makes a difference.)
		// * Listeners on a container will still trigger for bubbled events from its original children even if the child
		// changes parentage during this processing.
		// (This means that if, in an event handler, we try to delete a child: we set its parent to null and do
		// removeAllListenersOn(it): listeners with pending events that listened to the child directly will not trigger,
		// but those that listened to its parent will still trigger for the bubbled event.  I'm not sure if this is "good"
		// or "bad"; repeat note above about waffling.)
		public function handleEvents():void {
			while (queue.length > 0) {
				while (queue.length > 0) {
					generateCallbacksForOneEvent(queue.shift());
				}
				
				if (handlingEvents) {
					// Not sure if reentrant call should be an error or not.  We can cope with it fine; just add the
					// new callbacks to end of list and return, they'll be processed by the initial call's loop.
					Assert.fail("handleEvents reentrant call");
					return;
				}
				
				handlingEvents = true;
				while (callbacks.length > 0) {
					var oneCallback:ListenerReferenceForOneEvent = callbacks.shift();
					oneCallback.callback(oneCallback.event);
				}
				handlingEvents = false;
			}
		}
		
		private function generateCallbacksForOneEvent(event:QEvent):void {
			var currentSource:Object = event.source;
			do {
				var listeners:Vector.<ListenerReference> = findListenersFor(currentSource, event.eventId);
				if (listeners != null) {
					for each (var oneListener:ListenerReference in listeners) {
						callbacks.push(new ListenerReferenceForOneEvent(oneListener, event));
					}
				}
				//CONSIDER: implement my own separate containment for QEvent bubbling rather than display list
				//Mickey *strongly* encourages this.
				if (currentSource is DisplayObject) {
					currentSource = currentSource.parent;
				} else {
					currentSource = null;
				}
			} while (currentSource != null);
		}
		
		private function findListenersFor(source:Object, eventId:String):Vector.<ListenerReference> {
			var listenersOnThisSource:Object = lookup[source];
			if (listenersOnThisSource == null) {
				return null;
			}
			return listenersOnThisSource[eventId];
		}
		
		private function isEmpty(associativeArray:Object):Boolean {
			for (var foo:String in associativeArray) {
				return false;
			}
			return true;
		}
		
		public function numberOfListenersOn(source:Object):int {
			var listenersOnThisSource:Object = lookup[source];
			if (listenersOnThisSource == null) {
				return 0;
			}
			
			var count:int;
			for (var eventId:String in listenersOnThisSource) {
				var list:Vector.<ListenerReference> = listenersOnThisSource[eventId];
				if (list != null) {
					count += list.length;
				}
			}
			return count;
		}
		
		public function numberOfListeners(owner:Object = null):int {
			var count:int = 0;
			for (var source:Object in lookup) {
				var listenersOnThisSource:Object = lookup[source];
				if (listenersOnThisSource == null) {
					continue;
				}
				for (var eventId:String in listenersOnThisSource) {
					var list:Vector.<ListenerReference> = listenersOnThisSource[eventId];
					if (list != null) {
						for (var i:int = 0; i < list.length; ++i) {
							if ((owner == null) || (list[i].owner == owner)) {
								count++;
							}
						}
					}
				}
			}
			return count;
		}
		
		public function numberOfEventsInQueue():int {
			return queue.length;
		}
		
		public function debugTraceListenersOn(source:Object):void {
			trace("Listeners on", source, ":");
			var listenersOnThisSource:Object = lookup[source];
			if (listenersOnThisSource == null) {
				trace("  none");
				return;
			}
			
			for (var eventId:String in listenersOnThisSource) {
				trace("  Event:", eventId);
				var list:Vector.<ListenerReference> = listenersOnThisSource[eventId];
				if (list == null) {
					trace("    empty list -- something didn't delete it correctly");
				} else {
					for (var i:int = 0; i < list.length; ++i) {
						trace("   ", list[i]);
					}
				}
			}
			
		}
		
		public function debugTraceListeners(owner:Object = null):void {
			var count:int = 0;
			if (owner == null) {
				trace("Registered listeners:");
			} else {
				trace("Listeners owned by", owner, ":");
			}
			for (var source:Object in lookup) {
				var listenersOnThisSource:Object = lookup[source];
				if (listenersOnThisSource == null) {
					continue;
				}
				for (var eventId:String in listenersOnThisSource) {
					var list:Vector.<ListenerReference> = listenersOnThisSource[eventId];
					if (list == null) {
						continue;						
					}
					if (list != null) {
						for (var i:int = 0; i < list.length; ++i) {
							if ((owner == null) || (list[i].owner == owner)) {
								trace("  ", list[i]);
								count++;
							}
						}
					}
				}
			}
			trace("Total:", count);
		}
		
		public function debugTraceQueue():void {
			trace("Events in queue:");
			for (var i:int = 0; i < queue.length; ++i) {
				trace(i+":", queue[i]);
			}
			trace("Total:", queue.length);
		}
		
		public function debugTraceCallbacks():void {
			trace("Callbacks:");
			for (var i:int = 0; i < callbacks.length; ++i) {
				trace(i+":", callbacks[i]);
			}
			trace("Total:", callbacks.length);
		}
		
	} // end class EventQueue

}
