package angel.game {
	import angel.common.Alert;
	import angel.common.FloorTile;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	
	public class RoomExplore implements RoomMode {
		
		private var room:Room;
		private var playerMoveInProgress:Boolean = false;
		
		public function RoomExplore(room:Room) {
			this.room = room;
			room.addEventListener(MouseEvent.CLICK, exploreModeClickListener);
			room.stage.addEventListener(KeyboardEvent.KEY_DOWN, exploreModeKeyDownListener);
			if (room.playerCharacter != null) {
				room.scrollToCenter(room.playerCharacter.location, true);
			}
		}

		public function cleanup():void {
			room.removeEventListener(MouseEvent.CLICK, exploreModeClickListener);
			room.stage.removeEventListener(KeyboardEvent.KEY_DOWN, exploreModeKeyDownListener);
		}
		
		// For God-only-knows what reason, the version of Keyboard class for Flex compilation is missing all
		// of the letter-key constants.  The version in CS5 has them.  ?????
		public static const KEYBOARD_C:uint = 67;
		private function exploreModeKeyDownListener(event:KeyboardEvent):void {
			if (playerMoveInProgress) {
				Alert.show("No commands allowed until move finishes.");
				return;
			}
			if (event.keyCode == KEYBOARD_C) {
				room.changeModeTo(RoomCombat);
			}
			
		}
		
		private function exploreModeClickListener(event:MouseEvent):void {
			if (event.target is FloorTile) {
				if (playerMoveInProgress) {
					Alert.show("No commands allowed until move finishes.");
					return;
				}
				var loc:Point = (event.target as FloorTile).location;
				if (!loc.equals(room.playerCharacter.location) && !room.solid(loc)) {
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