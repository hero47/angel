package angel.game.script {
	import angel.common.Assert;
	import angel.game.event.EntityQEvent;
	import angel.game.event.EventQueue;
	import angel.game.event.QEvent;
	import angel.game.Room;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class TriggerMaster {
		
		public static const ON_INIT:String = "onInit";
		public static const ON_MOVE:String = "onMove";
		public static const ON_DEATH:String = "onDeath";
		
		public var triggerEventQueue:EventQueue = new EventQueue();
		private var context:ScriptContext;
		private var spotsThisEntityIsOn:Vector.<String>;
		private var runThese:Vector.<TriggeredScript>;
		
		private var room:Room;
		
		public function TriggerMaster() {
			
		}
		
		public function changeRoom(newRoom:Room):void {
			if (room != null) {
				Settings.gameEventQueue.removeListenersByOwnerAndSource(this, room);
			}
			room = newRoom;
			if (room != null) {
				Settings.gameEventQueue.addListener(this, room, Room.ROOM_INIT, roomEventListener, ON_INIT);
				Settings.gameEventQueue.addListener(this, room, EntityQEvent.FINISHED_ONE_TILE_OF_MOVE, entityEventListener, ON_MOVE);
				Settings.gameEventQueue.addListener(this, room, EntityQEvent.DEATH, entityEventListener, ON_DEATH);
			}
		}
		
		public function cleanupFor(owner:Object):void {
		}
		
		
		private function entityEventListener(event:EntityQEvent):void {
			// event.listenerParam is the trigger name
			filterAndProcessTriggers(event.source, String(event.listenerParam), event.simpleEntity);
		}
		
		private function roomEventListener(event:QEvent):void {
			filterAndProcessTriggers(event.source, String(event.listenerParam), null);
		}
		
		private function filterAndProcessTriggers(eventSource:Object, triggerName:String, entityWhoTriggered:SimpleEntity):void {
			Assert.assertTrue(context == null, "reentry on TriggerMaster.filterAndProcessTriggers");
			context = new ScriptContext(room, room.activePlayer(), entityWhoTriggered);
			runThese = new Vector.<TriggeredScript>();
			if (triggerName == "onMove") {
				spotsThisEntityIsOn = room.spotsMatchingLocation(entityWhoTriggered.location);
			}
			triggerEventQueue.dispatch(new QEvent(this, triggerName));
			triggerEventQueue.handleEvents();
			// now all triggers that need to be run should be in runThese
			
			for each (var triggeredScript:TriggeredScript in runThese) {
				context.setMe(triggeredScript.me);
				triggeredScript.script.doActions(context);
			}
			context.endOfScriptActions();
			context = null;
			runThese = null;
			spotsThisEntityIsOn = null;
		}
		
		public function addToRunListIfPassesFilter(triggeredScript:TriggeredScript):void {
			if (triggeredScript.passesFilter(context, spotsThisEntityIsOn)) {
				runThese.push(triggeredScript);
			}
		}
		
	}

}