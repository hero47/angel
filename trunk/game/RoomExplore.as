package angel.game {
	import angel.common.Alert;
	import angel.common.FloorTile;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;

	
	public class RoomExplore implements RoomMode {
		
		private var room:Room;
		private var playerMoveInProgress:Boolean = false;
		private var dragging:Boolean = false;
		
		public function RoomExplore(room:Room) {
			this.room = room;
			room.addEventListener(MouseEvent.CLICK, exploreModeClickListener);
			room.addEventListener(MouseEvent.MOUSE_DOWN, exploreModeMouseDownListener);
			room.stage.addEventListener(KeyboardEvent.KEY_DOWN, exploreModeKeyDownListener);
			if (room.playerCharacter != null) {
				room.scrollToCenter(room.playerCharacter.location, true);
			}
		}

		public function cleanup():void {
			room.removeEventListener(MouseEvent.CLICK, exploreModeClickListener);
			room.removeEventListener(MouseEvent.MOUSE_DOWN, exploreModeMouseDownListener);
			room.removeEventListener(MouseEvent.MOUSE_UP, exploreModeMouseUpListener);
			room.stage.removeEventListener(KeyboardEvent.KEY_DOWN, exploreModeKeyDownListener);
		}
		
		// For God-only-knows what reason, the version of Keyboard class for Flex compilation is missing all
		// of the letter-key constants.  The version in CS5 has them.  ?????
		public static const KEYBOARD_C:uint = 67;
		private function exploreModeKeyDownListener(event:KeyboardEvent):void {
			switch (event.keyCode) {
				case KEYBOARD_C:
					if (playerMoveInProgress) {
						Alert.show("Wait for move to finish before changing modes.");
					} else {
						room.changeModeTo(RoomCombat);
					}
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
		
		private function exploreModeClickListener(event:MouseEvent):void {
			if (!dragging && event.target is FloorTile) {
				var loc:Point = (event.target as FloorTile).location;
				if (!loc.equals(room.playerCharacter.location) && !room.playerCharacter.tileBlocked(loc)) {
					playerMoveInProgress = room.playerCharacter.startMovingToward(loc);
					if (playerMoveInProgress) {
						if (!(Settings.testExploreScroll > 0)) {
							room.scrollToCenter(loc);
						}
					}
				}
			}
		}

		public function playerMoved(newLocation:Point):void {
			if (newLocation == null) {
				playerMoveInProgress = false;
			}
		}
		
		
	} // end class RoomExplore

}