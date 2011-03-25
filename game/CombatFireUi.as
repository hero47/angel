package angel.game {
	import angel.game.PieSlice;
	import angel.common.FloorTile;
	import flash.ui.Keyboard;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatFireUi implements IUi {
		private var combat:RoomCombat;
		private var room:Room;
		private var player:Entity;
		
		public function CombatFireUi(combat:RoomCombat, room:Room) {
			this.combat = combat;
			this.room = room;
			this.player = room.playerCharacter;
		}
		
		/* INTERFACE angel.game.IUi */
		
		public function enable():void {
			trace("entering player fire phase");
			//UNDONE: hide cursor, display combat cursor icon
		}
		
		public function disable():void {
			trace("ending player fire phase");
			room.moveHilight(null, 0);
			//UNDONE: restore cursor
		}
		
		public function keyDown(keyCode:uint):void {
			switch (keyCode) {
				case Keyboard.BACKSPACE:
					//UNDONE: cancel target selection
				break;
				
				case Keyboard.ENTER:
					doPlayerFire();
					//UNDONE: fire or reserve fire
				break;
			}
		}
		
		public function mouseMove(x:int, y:int, tile:FloorTile):void {
			if (tile != null) {
				room.moveHilight(tile, 0xffffff);
				//UNDONE: hilight enemy on tile
			}
			//UNDONE: move combat cursor icon
		}
		
		public function mouseClick(tile:FloorTile):void {
				//UNDONE handle click
		}
		
		public function pieMenuForTile(tile:FloorTile):Vector.<PieSlice> {
			//UNDONE build pie menu
			return null;
		}
	
		
		/************ Private ****************/
		
		private function constructPieMenu():Vector.<PieSlice> {
			var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
			return slices;
		}
		
		private function doPlayerFire():void {
			combat.disableUi();
			combat.finishedFire();
		}
	
	} // end class CombatFireUi

}