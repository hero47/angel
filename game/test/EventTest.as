package angel.game.test {
	import angel.common.Alert;
	import angel.game.event.EventQueue;
	import angel.game.event.QEvent;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class EventTest {
		
		private var source1:Sprite = new Sprite();
		private var source2:Sprite = new Sprite();
		private var foo:int;
		private var bar:int;
		
		public function EventTest() {
			Autotest.testFunction(basicFunctionality);
			Autotest.testFunction(listenerWithParam);
			Autotest.testFunction(multipleSources);
			Autotest.testFunction(differentEvents);
			Autotest.testFunction(severalInQueue);
			Autotest.testFunction(twoListeners);
			Autotest.testFunction(addAfterDispatchButBeforeProcessing);
			Autotest.testFunction(removeAfterDispatchButBeforeProcessing);
			Autotest.testFunction(addDuringProcessing);
			Autotest.testFunction(removeDuringProcessing);
			Autotest.testFunction(bubbling);
		}
		
		private function basicFunctionality():void {
			var queue:EventQueue = new EventQueue();
			Autotest.assertEqual(queue.numberOfEventsInQueue(), 0, "Queue starts out empty");
			Autotest.assertEqual(queue.numberOfListeners(), 0, "No listeners registered");
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 0, "No listeners on the sprite");
			Autotest.assertEqual(queue.numberOfListeners(this), 0, "I own none");
			Autotest.assertEqual(queue.numberOfListenersOn(this), 0, "No listeners on me");
			Autotest.assertEqual(queue.numberOfListeners(source1), 0, "Sprite owns none");
			
			queue.addListener(this, source1, "test", sayYes);
			Autotest.assertEqual(queue.numberOfEventsInQueue(), 0, "Adding listeners doesn't affect queue");
			Autotest.assertEqual(queue.numberOfListeners(), 1, "One registered");
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 1, "Listener was added to sprite");
			Autotest.assertEqual(queue.numberOfListeners(this), 1, "I own the listener I added");
			Autotest.assertEqual(queue.numberOfListenersOn(this), 0, "Listener wasn't added to me");
			Autotest.assertEqual(queue.numberOfListeners(source1), 0, "Sprite owns none");
			
			queue.dispatch(new QEvent("test", source1));
			Autotest.assertEqual(queue.numberOfEventsInQueue(), 1, "Event was added to queue");
			Autotest.assertNoAlert("Dispatch shouldn't trigger the listener");
			
			queue.handleEvents();
			Autotest.assertAlertText("yes", "Listener ran");
			Autotest.assertEqual(queue.numberOfEventsInQueue(), 0, "Handling events leaves queue empty");
			Autotest.assertEqual(queue.numberOfListeners(), 1, "Still one registered registered");
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 1, "Sprite still has listener");
			Autotest.assertEqual(queue.numberOfListeners(this), 1, "I still own it");
			
			queue.removeListener(source1, "test", sayYes);
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 0, "Listener was removed");
			Autotest.assertEqual(queue.numberOfListeners(this), 0, "I don't own it anymore");
			Autotest.assertEqual(queue.numberOfListeners(), 0, "No listeners registered");
			
			queue.dispatch(new QEvent("test", source1));
			Autotest.assertEqual(queue.numberOfEventsInQueue(), 1, "Event was added to queue");
			Autotest.assertNoAlert("Dispatch shouldn't trigger the listener");
			queue.handleEvents();
			Autotest.assertNoAlert("Nothing should happen");
		}
		
		private function listenerWithParam():void {
		var queue:EventQueue = new EventQueue();
			queue.addListener(this, source1, "test", sayParam, "hello");
			queue.dispatch(new QEvent("test", source1));
			Autotest.assertNoAlert("Dispatch shouldn't trigger the listener");
			queue.handleEvents();
			Autotest.assertAlertText("hello");
		}
		
		private function multipleSources():void {
		var queue:EventQueue = new EventQueue();
			queue.addListener(this, source1, "test", setFooToParam, 3);
			queue.addListener(this, source1, "test", sayYes);
			queue.addListener(this, source2, "test", sayParam, "hello");
			Autotest.assertEqual(queue.numberOfListeners(), 3, "Got registered");
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 2, "Two on first");
			Autotest.assertEqual(queue.numberOfListenersOn(source2), 1, "One on second");
			
			foo = 1;
			queue.dispatch(new QEvent("test", source1));
			queue.handleEvents();
			Autotest.assertEqual(foo, 3);
			Autotest.assertAlertText("yes");
			
			foo = 1;
			queue.dispatch(new QEvent("test", source2));
			queue.handleEvents();
			Autotest.assertEqual(foo, 1);
			Autotest.assertAlertText("hello");
			
			queue.removeAllListenersOn(source1);
			Autotest.assertEqual(queue.numberOfListeners(), 1);
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 0);
			Autotest.assertEqual(queue.numberOfListenersOn(source2), 1);
			
			queue.removeAllListenersOn(source2);
			Autotest.assertEqual(queue.numberOfListeners(), 0);
		}
		
		private function differentEvents():void {
		var queue:EventQueue = new EventQueue();
			queue.addListener(this, source1, "event1", setFooToParam, 1);
			queue.addListener(this, source1, "event2", setFooToParam, 2);
			
			foo = 0;
			queue.dispatch(new QEvent("event1", source1));
			queue.handleEvents();
			Autotest.assertEqual(foo, 1);
			
			queue.dispatch(new QEvent("event2", source1));
			queue.handleEvents();
			Autotest.assertEqual(foo, 2);
		}
		
		private function severalInQueue():void {
		var queue:EventQueue = new EventQueue();
			queue.addListener(this, source1, "event1", setFooToParam, 1);
			queue.addListener(this, source1, "event2", sayYes);
			queue.addListener(this, source2, "event1", setBarToParam, 2);

			foo = 0;
			bar = 0;
			queue.dispatch(new QEvent("event1", source1));
			queue.dispatch(new QEvent("event2", source1));
			queue.dispatch(new QEvent("event1", source2));
			Autotest.assertEqual(foo, 0);
			Autotest.assertEqual(bar, 0);
			Autotest.assertNoAlert();
			queue.handleEvents();
			Autotest.assertEqual(foo, 1);
			Autotest.assertEqual(bar, 2);
			Autotest.assertAlertText("yes");
		}
		
		private function twoListeners():void {
		var queue:EventQueue = new EventQueue();
			var otherListener:Object = new Object;
			otherListener.doIt = function(event:QEvent):void {
				Alert.show("other");
			}
			queue.addListener(this, source1, "event1", setFooToParam, 1);
			queue.addListener(this, source1, "event2", sayYes);
			queue.addListener(otherListener, source1, "event1", otherListener.doIt);
			Autotest.assertEqual(queue.numberOfListeners(), 3);
			Autotest.assertEqual(queue.numberOfListeners(this), 2);
			Autotest.assertEqual(queue.numberOfListeners(otherListener), 1);
			
			foo = 0;
			queue.dispatch(new QEvent("event1", source1));
			queue.handleEvents();
			Autotest.assertEqual(foo, 1);
			Autotest.assertAlertText("other");
			
			queue.removeAllListenersOwnedBy(this);
			Autotest.assertEqual(queue.numberOfListeners(), 1);
		}
		
		//NOTE: I am not sure whether this is the most useful behavior or not!
		//May change after discussing with Mickey; in the meantime, keep it in mind and see if any of the code I'm writing
		//is simplified or complicated by either of the possible behaviors.
		private function addAfterDispatchButBeforeProcessing():void {
		var queue:EventQueue = new EventQueue();
		
			queue.dispatch(new QEvent("event1", source1));
			queue.addListener(this, source1, "event1", sayYes);
			queue.handleEvents();
			Autotest.assertAlertText("yes", "Listener added after dispatch but before processing starts SHOULD trigger");
		}
		
		//NOTE: same note as previous!
		private function removeAfterDispatchButBeforeProcessing():void {
		var queue:EventQueue = new EventQueue();
		
			queue.addListener(this, source1, "event1", sayYes);
			queue.dispatch(new QEvent("event1", source1));
			queue.removeListener(source1, "event1", sayYes);
			queue.handleEvents();
			Autotest.assertNoAlert("Listener removed after dispatch but before processing starts should NOT trigger");
		}
		
		private function addDuringProcessing():void {
		var queue:EventQueue = new EventQueue();
			queue.addListener(this, source1, "event1", function(event:QEvent):void {
				queue.addListener(this, source1, "event2", sayParam, "added");
			}, source1);
			
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 1);
			queue.dispatch(new QEvent("event1", source1));
			queue.dispatch(new QEvent("event2", source1));
			queue.handleEvents();
			Autotest.assertNoAlert("Listener added after event processing started should not trigger");
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 2);
			
			queue.dispatch(new QEvent("event2", source1));
			queue.handleEvents();
			Autotest.assertAlertText("added");
		}
		
		private function removeDuringProcessing():void {
		var queue:EventQueue = new EventQueue();
			queue.addListener(this, source1, "event1", function(event:QEvent):void {
				queue.removeAllListenersOn(event.listenerParam);
			}, source1);
			queue.addListener(this, source1, "event2", sayYes);
			
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 2);
			queue.dispatch(new QEvent("event1", source1));
			queue.dispatch(new QEvent("event2", source1));
			queue.handleEvents();
			Autotest.assertNoAlert();
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 0);
		}
		
		private function bubbling():void {
		var queue:EventQueue = new EventQueue();
			var child1:Sprite = new Sprite();
			child1.name = "child1";
			var child2:Sprite = new Sprite();
			child2.name = "child2";
			var container:Sprite = new Sprite();
			container.name = "parent";
			container.addChild(child1);
			container.addChild(child2);
			
			Autotest.assertEqual(queue.numberOfListeners(), 0, "No listeners registered");
			queue.addListener(this, container, "event1", sayTargetNames);
			
			queue.dispatch(new QEvent("event1", child1));
			queue.handleEvents();
			Autotest.assertAlertText("child1,parent");
			
			queue.dispatch(new QEvent("event1", child2));
			queue.handleEvents();
			Autotest.assertAlertText("child2,parent");
		}
		
		private function sayYes(event:QEvent):void {
			Alert.show("yes");
		}
		
		private function sayParam(event:QEvent):void {
			var message:String = String(event.listenerParam);
			Alert.show(message);
		}
		
		private function setFooToParam(event:QEvent):void {
			foo = int(event.listenerParam);
		}
		
		private function setBarToParam(event:QEvent):void {
			bar = int(event.listenerParam);
		}
		
		private function sayTargetNames(event:QEvent):void {
			Alert.show(DisplayObject(event.target).name + "," + DisplayObject(event.currentTarget).name);
		}
		
	}

}