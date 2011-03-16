package angel.game {
	import angel.common.Alert;
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
		public var playerMoveInProgress:Boolean = false;
		private var dragging:Boolean = false;
		
		public function RoomExplore(room:Room) {
			this.room = room;
			room.addEventListener(MouseEvent.CLICK, exploreModeClickListener);
			room.addEventListener(MouseEvent.MOUSE_DOWN, exploreModeMouseDownListener);
			room.addEventListener(MouseEvent.MOUSE_MOVE, exploreModeMouseMoveListener);
			room.stage.addEventListener(KeyboardEvent.KEY_DOWN, exploreModeKeyDownListener);
			room.addEventListener(Room.UNPAUSED_ENTER_FRAME, processTimedEvents);
			if (room.playerCharacter != null) {
				room.scrollToCenter(room.playerCharacter.location, true);
			}
			room.forEachEntity(initEntityBrain);
		}

		public function cleanup():void {
			room.removeEventListener(MouseEvent.CLICK, exploreModeClickListener);
			room.removeEventListener(MouseEvent.MOUSE_DOWN, exploreModeMouseDownListener);
			room.removeEventListener(MouseEvent.MOUSE_UP, exploreModeMouseUpListener);
			room.removeEventListener(MouseEvent.MOUSE_MOVE, exploreModeMouseMoveListener);
			room.stage.removeEventListener(KeyboardEvent.KEY_DOWN, exploreModeKeyDownListener);
			room.removeEventListener(Room.UNPAUSED_ENTER_FRAME, processTimedEvents);
			room.playerCharacter.removeEventListener(Entity.FINISHED_MOVING, playerFinishedMoving);
			room.moveHilight(null, 0);
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
		
		// For God-only-knows what reason, the version of Keyboard class for Flex compilation is missing all
		// of the letter-key constants.  The version in CS5 has them.  ?????
		public static const KEYBOARD_C:uint = 67;
		public static const KEYBOARD_V:uint = 86;
		private function exploreModeKeyDownListener(event:KeyboardEvent):void {
			switch (event.keyCode) {
				case KEYBOARD_C:
					if (playerMoveInProgress) {
						Alert.show("Wait for move to finish before changing modes.");
					} else {
						room.changeModeTo(RoomCombat);
					}
				break;
				case KEYBOARD_V:
					room.toggleVisibility();
				break;
				case Keyboard.SPACE:
					// if move in progress, stop moving as soon as possible.
					if (playerMoveInProgress) {
						room.playerCharacter.startMovingToward(room.playerCharacter.location);
					}
				break;
				case Keyboard.BACKSPACE:
					room.scrollToCenter(room.playerCharacter.location, true);
				break;
			}
			
		}

		private function exploreModeMouseDownListener(event:MouseEvent):void {
			if (event.shiftKey) {
				room.addEventListener(MouseEvent.MOUSE_UP, exploreModeMouseUpListener);
				room.startDrag();
				dragging = true;
			} else {
				dragging = false;
			}
		}

		private function exploreModeMouseUpListener(event:MouseEvent):void {
			room.removeEventListener(MouseEvent.MOUSE_UP, exploreModeMouseUpListener);
			room.stopDrag();
		}
		
		private function exploreModeMouseMoveListener(event:MouseEvent):void {
			if (event.target is FloorTile) {
				room.moveHilight(event.target as FloorTile, 0xffffff);;
			}
		}
		
		private function exploreModeClickListener(event:MouseEvent):void {
			if (!dragging && event.target is FloorTile) {
				var loc:Point = (event.target as FloorTile).location;
				if (!loc.equals(room.playerCharacter.location) && !room.playerCharacter.tileBlocked(loc)) {
					playerMoveInProgress = room.playerCharacter.startMovingToward(loc);
					if (playerMoveInProgress) {
						room.playerCharacter.addEventListener(Entity.FINISHED_MOVING, playerFinishedMoving);
						if (!(Settings.testExploreScroll > 0)) {
							room.scrollToCenter(loc);
						}
					}
				}
			}
		}
		
		private function playerFinishedMoving(event:Event):void {
			playerMoveInProgress = false;
			room.playerCharacter.removeEventListener(Entity.FINISHED_MOVING, playerFinishedMoving);
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