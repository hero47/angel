package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Util;
	import angel.game.PieSlice;
	import angel.common.FloorTile;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ExploreUi implements IRoomUi {
		private var room:Room;
		private var explore:RoomExplore;
		private var player:Entity;
		private var playerIsMoving:Boolean = false;
		
		public function ExploreUi(room:Room, explore:RoomExplore) {
			this.explore = explore;
			this.room = room;
			this.player = room.playerCharacter;
		}
		
		/* INTERFACE angel.game.IUi */
		
		public function enable():void {
			
		}
		
		public function disable():void {
			room.moveHilight(null, 0);
			room.playerCharacter.removeEventListener(EntityEvent.FINISHED_MOVING, playerFinishedMoving);
		}
		
		public function keyDown(keyCode:uint):void {
			switch (keyCode) {
				case Util.KEYBOARD_C:
					if (playerIsMoving) {
						Alert.show("Wait for move to finish before changing modes.");
					} else {
						room.changeModeTo(RoomCombat);
					}
				break;
				case Keyboard.SPACE:
					// if move in progress, stop moving as soon as possible.
					if (playerIsMoving) {
						player.startMovingToward(player.location);
					}
				break;
				case Keyboard.BACKSPACE:
					room.scrollToCenter(player.location, true);
				break;
			}
		}
		
		public function mouseMove(tile:FloorTile):void {
			if (tile != null) {
				if (player.tileBlocked(tile.location)) {
					room.moveHilight(null, 0);
				} else {
					var pathToMouse:Vector.<Point> = player.findPathTo(tile.location);
					if (pathToMouse == null) {
						room.moveHilight(null, 0);
					} else {
						room.moveHilight(tile, 0xffffff);;
					}
				}
			}
		}
		
		public function mouseClick(tile:FloorTile):void {
			var loc:Point = tile.location;
			if (!loc.equals(player.location) && !player.tileBlocked(loc)) {
				playerIsMoving = player.startMovingToward(loc);
				if (playerIsMoving) {
					player.addEventListener(EntityEvent.FINISHED_MOVING, playerFinishedMoving);
					if (!(Settings.testExploreScroll > 0)) {
						room.scrollToCenter(loc);
					}
				}
			}
		}
		
		public function pieMenuForTile(tile:FloorTile):Vector.<PieSlice> {
			return null;
		}
	
		
		/************ Private ****************/
		
		private function playerFinishedMoving(event:EntityEvent):void {
			Assert.assertTrue(event.entity.isPlayerControlled, "playerFinishedMoving called for NPC");
			playerIsMoving = false;
			room.playerCharacter.removeEventListener(EntityEvent.FINISHED_MOVING, playerFinishedMoving);
		}
		
	} // end class ExploreUi

}