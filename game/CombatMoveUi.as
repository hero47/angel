package angel.game {
	import angel.common.Assert;
	import angel.common.FloorTile;
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
	public class CombatMoveUi implements IUi {
		private var combat:RoomCombat;
		private var room:Room;
		private var player:Entity;
		
		private var movePointsDisplay:TextField;
		
		public function CombatMoveUi(combat:RoomCombat, room:Room) {
			this.combat = combat;
			this.room = room;
			this.player = room.playerCharacter;
			
			movePointsDisplay = createMovePointsTextField();
			movePointsDisplay.text = String(player.combatMovePoints);
			movePointsDisplay.x = 10;
			movePointsDisplay.y = 10;
		}
		
		/* INTERFACE angel.game.IUi */
		
		public function enable():void {
			trace("entering player move phase");
			room.parent.addChild(movePointsDisplay);
			movePointsDisplay.text = String(player.combatMovePoints);
			
		}
		
		public function disable():void {
			trace("ending player move phase");
			room.parent.removeChild(movePointsDisplay);
			room.moveHilight(null, 0);
		}
		
		public function keyDown(keyCode:uint):void {
			switch (keyCode) {
				case Keyboard.BACKSPACE:
					removeLastPathSegment();
				break;
				
				case Keyboard.ENTER:
					doPlayerMove();
				break;
			}
		}
		
		public function mouseMove(x:int, y:int, tile:FloorTile):void {
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
						movePointsDisplay.text = String(player.combatMovePoints - combat.path.length);
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
			combat.disableUi();
			
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
			movePointsDisplay.text = String(player.combatMovePoints);
		}
		
		private function removeLastPathSegment():void {
			if (combat.dots.length > 0) {
				combat.endIndexes.pop();
				var ends:int = combat.endIndexes.length;
				var clearFrom:int = (ends == 0 ? 0 : combat.endIndexes[ends - 1] + 1);
				combat.clearDots(clearFrom);
				combat.path.length = combat.dots.length;
				movePointsDisplay.text = String(player.combatMovePoints - combat.path.length);
			}
		}
		
		private function createMovePointsTextField():TextField {
			var myTextField:TextField = new TextField();
			myTextField.selectable = false;
			myTextField.width = 40;
			myTextField.height = 20;
			var myTextFormat:TextFormat = new TextFormat();
			myTextFormat.size = 16;
			myTextFormat.align = TextFormatAlign.CENTER;
			myTextField.defaultTextFormat = myTextFormat;
			myTextField.type = TextFieldType.DYNAMIC;
			myTextField.border = true;
			myTextField.background = true;
			myTextField.backgroundColor = 0xffffff;
			myTextField.textColor = 0x0;
			return myTextField;
		}
		
	} // end class CombatMoveUi

}