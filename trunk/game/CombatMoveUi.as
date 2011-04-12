package angel.game {
	import angel.common.Assert;
	import angel.common.FloorTile;
	import angel.common.Util;
	import angel.game.PieSlice;
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
		
		/* INTERFACE angel.game.IUi */
		
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
		
		public function keyDown(keyCode:uint):void {
			switch (keyCode) {
				case Util.KEYBOARD_C:
					room.changeModeTo(RoomExplore);
				break;
				
				case Keyboard.BACKSPACE:
					removeLastPathSegment();
				break;
				
				case Keyboard.ENTER:
					doPlayerMove();
				break;
			}
		}
		
		public function mouseMove(tile:FloorTile):void {
			if (tile != null) {
				room.moveHilight(tile, player.combatMover.dotColorIfExtendPathTo(tile.location));
			}
		}
		
		public function mouseClick(tile:FloorTile):void {
			player.combatMover.extendPathIfLegalMove(tile.location);
			adjustMovePointsDisplay();
		}
		
		public function pieMenuForTile(tile:FloorTile):Vector.<PieSlice> {
			if (tile.location.equals(player.location) || tile.location.equals(player.combatMover.endOfCurrentPath())) {
				return constructPieMenu();
			}
			
			return null;
		}
		
		
		/************ Private ****************/
		
		private function constructPieMenu():Vector.<PieSlice> {
			var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
			
			if (player.combatMover.path.length > 0) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.CancelMove), removePath));
			}
			slices.push(new PieSlice(Icon.bitmapData(Icon.Stay), doPlayerMoveStay));
			if (player.combatMover.path.length > 0) {
				var minGait:int = player.combatMover.minimumGaitForPath();
				if (minGait <= ComplexEntity.GAIT_WALK) {
					slices.push(new PieSlice(Icon.bitmapData(Icon.Walk), doPlayerMoveWalk));
				}
				if (minGait <= ComplexEntity.GAIT_RUN) {
					slices.push(new PieSlice(Icon.bitmapData(Icon.Run), doPlayerMoveRun));
				}
				slices.push(new PieSlice(Icon.bitmapData(Icon.Sprint), doPlayerMoveSprint));
			}
			
			return slices;
		}
		
		private function doPlayerMove(gaitChoice:int = ComplexEntity.GAIT_UNSPECIFIED):void {
			var playerMoving:ComplexEntity = player;
			room.disableUi();
			
			if (gaitChoice == ComplexEntity.GAIT_UNSPECIFIED) {
				gaitChoice = playerMoving.combatMover.minimumGaitForPath();
			}
			playerMoving.centerRoomOnMe();
			playerMoving.combatMover.startEntityFollowingPath(gaitChoice);
		}
		
		private function doPlayerMoveStay():void {
			removePath();
			doPlayerMove(ComplexEntity.GAIT_WALK);
		}
		
		private function doPlayerMoveWalk():void {
			doPlayerMove(ComplexEntity.GAIT_WALK);
		}
		
		private function doPlayerMoveRun():void {
			doPlayerMove(ComplexEntity.GAIT_RUN);
		}
		
		private function doPlayerMoveSprint():void {
			doPlayerMove(ComplexEntity.GAIT_SPRINT);
		}
		
		private function removePath():void {
			player.combatMover.clearPath();
			adjustMovePointsDisplay();
		}
		
		private function removeLastPathSegment():void {
			player.combatMover.removeLastPathSegment();
			adjustMovePointsDisplay();
		}
		
		private function adjustMovePointsDisplay(show:Boolean = true):void {
			combat.statDisplay.adjustMovePointsDisplay(show ? player.combatMover.unusedMovePoints() : -1);
		}
		
	} // end class CombatMoveUi

}