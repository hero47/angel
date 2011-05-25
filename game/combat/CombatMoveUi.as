package angel.game.combat {
	import angel.common.Assert;
	import angel.common.FloorTile;
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.EntityMovement;
	import angel.game.Icon;
	import angel.game.IRoomUi;
	import angel.game.PieSlice;
	import angel.game.Room;
	import angel.game.RoomExplore;
	import angel.game.ToolTip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatMoveUi implements IRoomUi {
		private var combat:RoomCombat;
		private var room:Room;
		private var player:ComplexEntity;
		private var oldMarkerColorTransform:ColorTransform;
		
		public function CombatMoveUi(room:Room, combat:RoomCombat) {
			this.combat = combat;
			this.room = room;
		}
		
		/* INTERFACE angel.game.IRoomUi */
		
		public function enable(player:ComplexEntity):void {
			trace("entering player move phase for", player.aaId);
			this.player = player;
			oldMarkerColorTransform = player.marker.transform.colorTransform;
			player.marker.transform.colorTransform = new ColorTransform(0, 0, 0, 1, 0, 255, 0, 0);
			adjustMovePointsDisplay();
		}
		
		public function disable():void {
			trace("ending player move phase for", player.aaId);
			player.marker.transform.colorTransform = oldMarkerColorTransform;
			this.player = null;
			adjustMovePointsDisplay(false);
			room.moveHilight(null, 0);
		}
		
		public function get currentPlayer():ComplexEntity {
			return player;
		}
		
		public function keyDown(keyCode:uint):void {
			switch (keyCode) {
				case Util.KEYBOARD_C:
					room.changeModeTo(RoomExplore);
				break;
				
				case Util.KEYBOARD_M:
					combat.augmentedReality.toggleMinimap();
				break;
				
				case Keyboard.BACKSPACE:
					removeLastPathSegment();
				break;
				
				case Keyboard.ENTER:
					doPlayerMove();
				break;
				
				case Keyboard.SPACE:
					room.snapToCenter(player.location);
				break;
			}
		}
		
		public function mouseMove(tile:FloorTile):void {
			if (tile != null) {
				room.moveHilight(tile, combat.mover.dotColorIfExtendPathTo(player, tile.location));
				
				if (Util.entityHasLineOfSight(player, tile.location)) {
					room.updateToolTip(tile.location);
				} else {
					ToolTip.removeToolTip();
				}
			}
		}
		
		public function mouseClick(tile:FloorTile):void {
			combat.mover.extendPathIfLegalMove(player, tile.location);
			adjustMovePointsDisplay();
		}
		
		public function pieMenuForTile(tile:FloorTile):Vector.<PieSlice> {
			var endOfCurrentPath:Point = combat.mover.endOfCurrentPath();
			var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
			
			if (combat.mover.hasPath()) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.CancelMove), "Clear path", removePath));
			}
			if (combat.mover.hasPathWithMoreThanOneSegment()) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.TestIconBitmap), "Remove last waypoint", removeLastPathSegment));
			}
			if (combat.mover.isLegalPathExtension(player, tile.location)) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.TestIconBitmap), "Add waypoint", function():void {
					combat.mover.extendPathIfLegalMove(player, tile.location);
					adjustMovePointsDisplay();
				} ));
			}
			slices.push(new PieSlice(Icon.bitmapData(Icon.Stay), "Stand still", doPlayerMoveStay));
			if (combat.mover.hasPath()) {
				if (combat.mover.shootFromCoverValidForCurrentLocationAndPath(player)) {
					slices.push(new PieSlice(Icon.bitmapData(Icon.CombatFireFromCover), "Fire from cover", doPlayerFireFromCover));
				}
				var minGait:int = combat.mover.minimumGaitForPath(player);
				if ((minGait <= EntityMovement.GAIT_WALK) && (player.movement.maxGait >= EntityMovement.GAIT_WALK)) {
					slices.push(new PieSlice(Icon.bitmapData(Icon.Walk), "Walk", doPlayerMoveWalk));
				}
				if ((minGait <= EntityMovement.GAIT_RUN) && (player.movement.maxGait >= EntityMovement.GAIT_RUN))  {
					slices.push(new PieSlice(Icon.bitmapData(Icon.Run), "Run", doPlayerMoveRun));
				}
				if (player.movement.maxGait >= EntityMovement.GAIT_SPRINT) {
					slices.push(new PieSlice(Icon.bitmapData(Icon.Sprint), "Sprint", doPlayerMoveSprint));
				}
			}
			
			return slices;
		}
		
		/************ Private ****************/
		
		private function doPlayerMove(gaitChoice:int = EntityMovement.GAIT_UNSPECIFIED):void {
			var playerMoving:ComplexEntity = player;
			room.disableUi();
			
			if (gaitChoice == EntityMovement.GAIT_UNSPECIFIED) {
				gaitChoice = combat.mover.minimumGaitForPath(playerMoving);
			}
			playerMoving.centerRoomOnMe();
			combat.mover.startEntityFollowingPath(playerMoving, gaitChoice);
		}
		
		private function doPlayerMoveStay():void {
			removePath();
			doPlayerMove(EntityMovement.GAIT_NO_MOVE);
		}
		
		private function doPlayerMoveWalk():void {
			doPlayerMove(EntityMovement.GAIT_WALK);
		}
		
		private function doPlayerMoveRun():void {
			doPlayerMove(EntityMovement.GAIT_RUN);
		}
		
		private function doPlayerMoveSprint():void {
			doPlayerMove(EntityMovement.GAIT_SPRINT);
		}
		
		private function doPlayerFireFromCover():void {
			combat.mover.displayReturnMarker(player.location);
			combat.setupFireFromCoverMove(player);
			doPlayerMove(EntityMovement.GAIT_RUN);
		}
		
		private function removePath():void {
			combat.mover.clearPath();
			adjustMovePointsDisplay();
		}
		
		private function removeLastPathSegment():void {
			combat.mover.removeLastPathSegment(player);
			adjustMovePointsDisplay();
		}
		
		private function adjustMovePointsDisplay(show:Boolean = true):void {
			//UNDONE: upgrade stat display to remove this abomination
			combat.augmentedReality.statDisplay.adjustMovePointsDisplay(show ? combat.mover.unusedMovePoints(player) : -1);
		}
		
	} // end class CombatMoveUi

}