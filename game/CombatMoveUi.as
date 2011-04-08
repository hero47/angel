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
			combat.statDisplay.adjustMovePointsDisplay(player.combatMovePoints);
		}
		
		public function disable():void {
			trace("ending player move phase for", player.aaId);
			player.marker.transform.colorTransform = oldMarkerColorTransform;
			this.player = null;
			combat.statDisplay.adjustMovePointsDisplay(-1);
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
				var distance:int = 1000;
				if (!player.tileBlocked(tile.location) && (combat.path.length < player.combatMovePoints)) {
					var pathToMouse:Vector.<Point> = player.findPathTo(tile.location, 
							(combat.path.length == 0 ? null : combat.path[combat.path.length-1]) );
					if (pathToMouse != null) {
						distance = combat.path.length + pathToMouse.length;
					}
				}
				room.moveHilight(tile, RoomCombat.colorForGait(player.gaitForDistance(distance)));
			}
		}
		
		public function mouseClick(tile:FloorTile):void {
			var loc:Point = tile.location;
			if (!player.tileBlocked(loc)) {
				var currentEnd:Point = (combat.path.length == 0 ? player.location : combat.path[combat.path.length - 1]);
				if (!loc.equals(currentEnd)) {
					var pathToMouse:Vector.<Point> = player.findPathTo(loc, currentEnd);
					if (pathToMouse != null && pathToMouse.length <= player.combatMovePoints - combat.path.length) {
						combat.extendPath(player, pathToMouse);
						combat.statDisplay.adjustMovePointsDisplay(player.combatMovePoints - combat.path.length);
					}
				}
			}
		}
		
		public function pieMenuForTile(tile:FloorTile):Vector.<PieSlice> {
			if (tile.location.equals(player.location) ||
						(combat.path.length > 0 && tile.location.equals(combat.path[combat.path.length - 1]))) {
				return constructPieMenu();
			}
			
			return null;
		}
		
		
		/************ Private ****************/
		
		private function constructPieMenu():Vector.<PieSlice> {
			var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
			
			if (combat.path.length > 0) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.CancelMove), removePath));
			}
			slices.push(new PieSlice(Icon.bitmapData(Icon.Stay), doPlayerMoveStay));
			if (combat.path.length > 0) {
				var minGait:int = player.gaitForDistance(combat.path.length);
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
				gaitChoice = playerMoving.gaitForDistance(combat.path.length);
			}
			playerMoving.centerRoomOnMe();
			combat.startEntityFollowingPath(playerMoving, gaitChoice);
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
			combat.clearDots(0);
			combat.path.length = 0;
			combat.statDisplay.adjustMovePointsDisplay(player.combatMovePoints);
		}
		
		private function removeLastPathSegment():void {
			if (combat.dots.length > 0) {
				combat.endIndexes.pop();
				var ends:int = combat.endIndexes.length;
				var clearFrom:int = (ends == 0 ? 0 : combat.endIndexes[ends - 1] + 1);
				combat.clearDots(clearFrom);
				combat.path.length = combat.dots.length;
				combat.statDisplay.adjustMovePointsDisplay(player.combatMovePoints - combat.path.length);
			}
		}
		
	} // end class CombatMoveUi

}