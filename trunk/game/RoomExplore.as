package angel.game {
	import angel.common.Alert;
	import angel.common.Floor;
	import angel.common.FloorTile;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;

	
	public class RoomExplore implements RoomMode {
		
		private var room:Room;
		private var exploreUi:ExploreUi;
		
		public function RoomExplore(room:Room) {
			this.room = room;
			room.addEventListener(Room.UNPAUSED_ENTER_FRAME, processTimedEvents);
			if (room.playerCharacter != null) {
				room.scrollToCenter(room.playerCharacter.location, true);
			}
			room.forEachEntity(initEntityBrain);
			
			exploreUi = new ExploreUi(room, this);
			room.enableUi(exploreUi);
		}

		public function cleanup():void {
			room.disableUi();
			room.removeEventListener(Room.UNPAUSED_ENTER_FRAME, processTimedEvents);
			room.forEachEntity(endEntityBrain);
			timeQueue = null;
		}
		
		private function initEntityBrain(entity:Entity):void {
			if (entity.exploreBrainClass != null) {
				entity.brain = new entity.exploreBrainClass(entity, this);
			}
		}
		
		private function endEntityBrain(entity:Entity):void {
			entity.brain = null;
		}
		
		/***************  TIMER STUFF  ****************/
		// I'm going to run all the time-based scripting stuff for Explore mode through this central location
		// because (a) I'm not sure whether I want to use real time (plus "pause") or enterFrame-based time, so
		// putting that choice in one place is cleaner than spreading it across multiple places, and
		// (b) I think it will make resource management cleaner as well.
		
		private var timeQueue:Vector.<TimedEvent> = new Vector.<TimedEvent>();
		private var queueNeedsSort:Boolean = false;
		private var time:int = 0;
		
		// called each frame except when game is paused
		private function processTimedEvents(event:Event):void {
			time++;
			if (queueNeedsSort) {
				timeQueue.sort(TimedEvent.compare);
				queueNeedsSort = false;
			}
			while (timeQueue.length > 0 && timeQueue[0].gameTime <= time) {
				timeQueue.shift().callback(this);
			}
		}
		
		// callback takes pointer to this, which it can use to set another timer
		public function addTimedEvent(secondsFromNow:Number, callback:Function):void {
			var timedEvent:TimedEvent = new TimedEvent(time + secondsFromNow * Settings.FRAMES_PER_SECOND, callback);
			timeQueue.push(timedEvent);
			queueNeedsSort = true;
		}
		
	} // end class RoomExplore

}

class TimedEvent {
	public var gameTime:int;
	public var callback:Function;
	public function TimedEvent(gameTime:int, callback:Function) {
		this.gameTime = gameTime;
		this.callback = callback;
	}
	
	public static function compare(a:TimedEvent, b:TimedEvent):Number {
		return b.gameTime - a.gameTime;
	}
}