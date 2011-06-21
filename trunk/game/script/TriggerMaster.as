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
		public static const TRIGGER_NAME_TO_GAME_EVENT:Object = {
			"onDeath":EntityQEvent.DEATH,
			"onFrob":EntityQEvent.FROBBED,
			"onInit":Room.ROOM_INIT,
			"onMove":EntityQEvent.FINISHED_ONE_TILE_OF_MOVE
		}
		
		private var context:ScriptContext;
		private var runThese:Vector.<RunInfo>;
		
		public var room:Room;
		
		public function TriggerMaster() {
			runThese = new Vector.<RunInfo>();
		}
		
		public function gameEventsFinishedForFrame():void {
			runTriggeredEvents();
		}
		
		public function changeRoom(newRoom:Room):void {
			runTriggeredEvents();
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
		
		private function runTriggeredEvents():void {
			while (runThese.length > 0) {
				context = new ScriptContext(room, room.activePlayer(), room, null);
				var runningNow:Vector.<RunInfo> = runThese;
				runThese = new Vector.<RunInfo>();
				for each (var runInfo:RunInfo in runningNow) {
					runInfo.adjustContextAndDoScriptActions(context);
				}
				context.finish();
			}
			context = null;
		}
		
		public function addToRunListIfPassesFilter(triggeredScript:TriggeredScript, me:Object, entityWhoTriggered:SimpleEntity):void {
			var context:ScriptContext = new ScriptContext(room, room.activePlayer(), me, entityWhoTriggered);
			var spotsThisEntityIsOn:Vector.<String>;
			if (triggeredScript.spotIds != null) {
				spotsThisEntityIsOn = room.spotsMatchingLocation(entityWhoTriggered.location);
			}
			if (triggeredScript.passesFilter(context, spotsThisEntityIsOn)) {
				var runInfo:RunInfo = new RunInfo(triggeredScript.script, me, entityWhoTriggered);
				runThese.push(runInfo);
			}
			context.finish(); // display any errors
			//CONSIDER: keep context around, updating contents here, display errors at end of frame processing
		}
		
	}

}
import angel.game.script.Script;
import angel.game.script.ScriptContext;
import angel.game.SimpleEntity;

internal class RunInfo {
	public var script:Script;
	public var me:Object;
	public var entityWhoTriggered:SimpleEntity;
	public function RunInfo(script:Script, me:Object, entityWhoTriggered:SimpleEntity) {
		this.script = script;
		this.me = me;
		this.entityWhoTriggered = entityWhoTriggered;
	}
	
	public function adjustContextAndDoScriptActions(context:ScriptContext):void {
		context.setSpecialId(Script.SELF, me);
		context.setSpecialId(Script.TRIGGERING_ENTITY, entityWhoTriggered);
		script.doActions(context);
	}
	
}