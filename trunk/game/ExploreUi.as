package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Util;
	import angel.game.combat.RoomCombat;
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
		private var player:ComplexEntity;
		private var playerIsMoving:Boolean = false;
		
		private static const MOVE_COLOR:uint = 0xffffff;
		private static const FROB_COLOR:uint = 0x0000ff;
		
		public function ExploreUi(room:Room, explore:RoomExplore) {
			this.explore = explore;
			this.room = room;
		}
		
		/* INTERFACE angel.game.IRoomUi */
		
		public function enable(player:ComplexEntity):void {
			this.player = player;
		}
		
		public function disable():void {
			room.moveHilight(null, 0);
			player.removeEventListener(EntityEvent.FINISHED_MOVING, playerFinishedMoving);
			this.player = null;
		}
		
		public function get currentPlayer():ComplexEntity {
			return player;
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
						player.movement.startMovingToward(player.location);
					}
				break;
				case Keyboard.BACKSPACE:
					room.snapToCenter(player.location);
				break;
			}
		}
		
		public function mouseMove(tile:FloorTile):void {
			if (tile == null) {
				return;
			}
			var location:Point = tile.location;
			if (player.movement.tileBlocked(location)) {
				//NOTE: if two entities are on the same tile, only the first is currently frob-able.
				//CONSIDER: if this becomes a problem, we could check for this case and put up a dialog or menu
				//allowing them to pick which entity to frob.
				var target:SimpleEntity = room.firstEntityIn(location);
				if (target != null && target.frobOk(player)) {
					room.moveHilight(tile, FROB_COLOR);
				} else {
					room.moveHilight(null, 0);
				}
			} else {
				var pathToMouse:Vector.<Point> = player.movement.findPathTo(location);
				if (pathToMouse == null) {
					room.moveHilight(null, 0);
				} else {
					room.moveHilight(tile, MOVE_COLOR);
				}
			}
			
			room.updateToolTip(location);
		}
		
		
		public function mouseClick(tile:FloorTile):void {
			var loc:Point = tile.location;
			
			if (player.movement.tileBlocked(tile.location)) {
				var target:SimpleEntity = room.firstEntityIn(tile.location);
				if (target != null && target.frobOk(player)) {
					target.frob(player);
					return;
				}
			}
			
			if (!loc.equals(player.location) && !player.movement.tileBlocked(loc)) {
				playerIsMoving = player.movement.startMovingToward(loc);
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
			Assert.assertTrue((event.entity == player), "Got a playerFinishedMoving event, but with an entity other than our player");
			playerIsMoving = false;
			player.removeEventListener(EntityEvent.FINISHED_MOVING, playerFinishedMoving);
		}
		
	} // end class ExploreUi

}