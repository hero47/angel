package angel.game {
	import angel.common.Assert;
	import angel.common.FloorTile;
	import angel.common.Util;
	import angel.game.PieSlice;
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
		private var player:Entity;
		
		private var movePointsDisplay:TextField;
		private static const MOVE_POINTS_PREFIX:String = "Move: ";
		
		public function CombatMoveUi(room:Room, combat:RoomCombat) {
			this.combat = combat;
			this.room = room;
			this.player = room.playerCharacter;
			
			movePointsDisplay = createMovePointsTextField();
			movePointsDisplay.x = 10;
			movePointsDisplay.y = 30;
		}
		
		/* INTERFACE angel.game.IUi */
		
		public function enable():void {
			trace("entering player move phase");
			adjustMovePointsDisplay(player.combatMovePoints);
			room.parent.addChild(movePointsDisplay);		
		}
		
		public function disable():void {
			trace("ending player move phase");
			room.parent.removeChild(movePointsDisplay);
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
						adjustMovePointsDisplay(player.combatMovePoints - combat.path.length);
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
				if (minGait <= Entity.GAIT_WALK) {
					slices.push(new PieSlice(Icon.bitmapData(Icon.Walk), doPlayerMoveWalk));
				}
				if (minGait <= Entity.GAIT_RUN) {
					slices.push(new PieSlice(Icon.bitmapData(Icon.Run), doPlayerMoveRun));
				}
				slices.push(new PieSlice(Icon.bitmapData(Icon.Sprint), doPlayerMoveSprint));
			}
			
			return slices;
		}
		
		private function doPlayerMove(gaitChoice:int = Entity.GAIT_UNSPECIFIED):void {
			room.disableUi();
			
			if (gaitChoice == Entity.GAIT_UNSPECIFIED) {
				gaitChoice = player.gaitForDistance(combat.path.length);
			}
			room.playerCharacter.centerRoomOnMe();
			combat.startEntityFollowingPath(player, gaitChoice);
		}
		
		private function doPlayerMoveStay():void {
			removePath();
			doPlayerMove(Entity.GAIT_WALK);
		}
		
		private function doPlayerMoveWalk():void {
			doPlayerMove(Entity.GAIT_WALK);
		}
		
		private function doPlayerMoveRun():void {
			doPlayerMove(Entity.GAIT_RUN);
		}
		
		private function doPlayerMoveSprint():void {
			doPlayerMove(Entity.GAIT_SPRINT);
		}
		
		private function removePath():void {
			combat.clearDots(0);
			combat.path.length = 0;
			adjustMovePointsDisplay(player.combatMovePoints);
		}
		
		private function removeLastPathSegment():void {
			if (combat.dots.length > 0) {
				combat.endIndexes.pop();
				var ends:int = combat.endIndexes.length;
				var clearFrom:int = (ends == 0 ? 0 : combat.endIndexes[ends - 1] + 1);
				combat.clearDots(clearFrom);
				combat.path.length = combat.dots.length;
				adjustMovePointsDisplay(player.combatMovePoints - combat.path.length);
			}
		}
		
		private function createMovePointsTextField():TextField {
			var myTextField:TextField = Util.textBox("", 80, 20, TextFormatAlign.CENTER, false);
			myTextField.border = true;
			myTextField.background = true;
			myTextField.backgroundColor = 0xffffff;
			return myTextField;
		}
		
		private function adjustMovePointsDisplay(points:int):void {
				movePointsDisplay.text = MOVE_POINTS_PREFIX + String(points);
		}
		
	} // end class CombatMoveUi

}