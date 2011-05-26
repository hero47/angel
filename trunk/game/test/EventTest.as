package angel.game.test {
	import angel.common.Alert;
	import angel.game.event.EventQueue;
	import angel.game.event.QEvent;
	import flash.display.Sprite;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class EventTest {
		
		private var queue:EventQueue = new EventQueue();
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
			Autotest.testFunction(removeDuringProcessing);
		}
		
		private function basicFunctionality():void {
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
			Autotest.assertEqual(queue.numberOfListeners(), 0, "No listeners registered");
			queue.addListener(this, source1, "test", sayParam, "hello");
			queue.dispatch(new QEvent("test", source1));
			Autotest.assertNoAlert("Dispatch shouldn't trigger the listener");
			queue.handleEvents();
			Autotest.assertAlertText("hello");
			queue.removeListener(source1, "test", sayParam);
			
		}
		
		private function multipleSources():void {
			Autotest.assertEqual(queue.numberOfListeners(), 0, "No listeners registered");
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
			Autotest.assertEqual(queue.numberOfListeners(), 0, "No listeners registered");
			queue.addListener(this, source1, "event1", setFooToParam, 1);
			queue.addListener(this, source1, "event2", setFooToParam, 2);
			
			foo = 0;
			queue.dispatch(new QEvent("event1", source1));
			queue.handleEvents();
			Autotest.assertEqual(foo, 1);
			
			queue.dispatch(new QEvent("event2", source1));
			queue.handleEvents();
			Autotest.assertEqual(foo, 2);
			queue.removeAllListenersOn(source1);
		}
		
		private function severalInQueue():void {
			Autotest.assertEqual(queue.numberOfListeners(), 0, "No listeners registered");
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
			
			queue.removeAllListenersOn(source1);
			queue.removeAllListenersOn(source2);
		}
		
		private function twoListeners():void {
			var otherListener:Object = new Object;
			otherListener.doIt = function(event:QEvent, param:Object):void {
				Alert.show("other");
			}
			Autotest.assertEqual(queue.numberOfListeners(), 0, "No listeners registered");
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
			queue.removeAllListenersOwnedBy(otherListener);
		}
		
		private function removeDuringProcessing():void {
			var otherListener:Object = new Object();
			otherListener.doIt = function(event:QEvent, param:Object):void {
				Alert.show("other");
			}
			Autotest.assertEqual(queue.numberOfListeners(), 0, "No listeners registered");
			queue.addListener(this, source1, "event1", removeListenersOnParam, source1);
			queue.addListener(this, source1, "event2", sayYes);
			
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 2);
			queue.dispatch(new QEvent("event1", source1));
			queue.dispatch(new QEvent("event2", source1));
			queue.handleEvents();
			Autotest.assertNoAlert();
			Autotest.assertEqual(queue.numberOfListenersOn(source1), 0);
		}
		
		private function sayYes(event:QEvent, param:Object):void {
			Alert.show("yes");
		}
		
		private function sayParam(event:QEvent, param:Object):void {
			var message:String = String(param);
			Alert.show(message);
		}
		
		private function setFooToParam(event:QEvent, param:Object):void {
			foo = int(param);
		}
		
		private function setBarToParam(event:QEvent, param:Object):void {
			bar = int(param);
		}
		
		private function removeListenersOnParam(event:QEvent, param:Object):void {
			queue.removeAllListenersOn(param);
		}
		
	}

}