package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
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
			room.forEachComplexEntity(initEntityForExplore);
			
			exploreUi = new ExploreUi(room, this);
			Assert.assertTrue(room.mainPlayerCharacter != null, "Main player character undefined!");
			room.snapToCenter(room.mainPlayerCharacter.location);
			room.enableUi(exploreUi, room.mainPlayerCharacter);
		}

		public function cleanup():void {
			room.disableUi();
			room.removeEventListener(Room.UNPAUSED_ENTER_FRAME, processTimedEvents);
			room.forEachComplexEntity(cleanupEntityFromExplore);
			timeQueue = null;
		}
		
		public function entityAddedToRoom(entity:SimpleEntity):void {
			if (entity is ComplexEntity) {
				initEntityForExplore(entity as ComplexEntity);
			}
		}
		
		public function entityWillBeRemovedFromRoom(entity:SimpleEntity):void {
			if (entity is ComplexEntity) {
				cleanupEntityFromExplore(entity as ComplexEntity);
			}
		}
		
		public function playerControlChanged(entity:ComplexEntity, pc:Boolean):void {
			// do nothing special
		}
		
		private function initEntityForExplore(entity:ComplexEntity):void {
			entity.initHealth();
			entity.adjustBrainForRoomMode(this);
		}
		
		private function cleanupEntityFromExplore(entity:ComplexEntity):void {
			entity.adjustBrainForRoomMode(null);
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
		
		public function removeTimedEvent(callback:Function):void {
			for (var i:int = 0; i < timeQueue.length; ++i) {
				if (timeQueue[i].callback == callback) {
					timeQueue.splice(i, 1);
					--i;
				}
			}
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
	
	public function toString():String {
		return "TimedEvent[" + gameTime + "]";
	}
	public static function compare(a:TimedEvent, b:TimedEvent):Number {
		return a.gameTime - b.gameTime;
	}
}