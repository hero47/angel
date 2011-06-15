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
		
		public static const ON_DEATH:String = "onDeath";
		public static const ON_FROB:String = "onFrob";
		public static const ON_INIT:String = "onInit";
		public static const ON_MOVE:String = "onMove";
		
		//can't use the constants to init the left side of, it doesn't translate them to strings
		private static const triggerNameToGameEvent:Object = {
			"onDeath":EntityQEvent.DEATH,
			"onFrob":EntityQEvent.FROBBED,
			"onInit":Room.ROOM_INIT,
			"onMove":EntityQEvent.FINISHED_ONE_TILE_OF_MOVE
		}
		
		public var triggerEventQueue:EventQueue = new EventQueue();
		private var context:ScriptContext;
		private var spotsThisEntityIsOn:Vector.<String>;
		private var runThese:Vector.<TriggeredScript>;
		
		private var room:Room;
		
		public function TriggerMaster() {
			triggerEventQueue.debugId = "TRIGGER";
		}
		
		public function changeRoom(newRoom:Room):void {
			if (room != null) {
				Settings.gameEventQueue.removeListenersByOwnerAndSource(this, room);
			}
			room = newRoom;
		}
		
		public function cleaningUpRoom(oldRoom:Room):void {
			if (room == oldRoom) {
				changeRoom(null);
			}
		}
		
		public function addTrigger(owner:Object, sourceIfNotCurrentRoom:Object, triggerName:String, triggerListener:Function):void {
			var gameEvent:String = triggerNameToGameEvent[triggerName];
			Assert.assertTrue(gameEvent != null, "Missing trigger " + triggerName);
			if (sourceIfNotCurrentRoom == null) {
				sourceIfNotCurrentRoom = room;
			}
			//Note: this game listener will be duplicated if more than one room/entity cares about the same trigger, but
			//the parameter should be the same triggerName so duplicates are ignored by queue
			Settings.gameEventQueue.addListener(this, (sourceIfNotCurrentRoom == null ? room : sourceIfNotCurrentRoom),
					gameEvent, gameEventListener, triggerName);
			triggerEventQueue.addListener(owner, sourceIfNotCurrentRoom, triggerName, triggerListener);
		}
		
		private function gameEventListener(event:QEvent):void {
			var triggerName:String = String(event.listenerParam);
			Assert.assertTrue(context == null, "reentry on TriggerMaster.filterAndProcessTriggers");
			var entityWhoTriggered:SimpleEntity = (event.source is SimpleEntity ? SimpleEntity(event.source) : null);
			context = new ScriptContext(room, room.activePlayer(), entityWhoTriggered);
			runThese = new Vector.<TriggeredScript>();
			if (triggerName == "onMove") {
				spotsThisEntityIsOn = room.spotsMatchingLocation(entityWhoTriggered.location);
			}
			triggerEventQueue.dispatch(new QEvent(event.source, triggerName, event.param));
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