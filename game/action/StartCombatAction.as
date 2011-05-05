package angel.game.action {
	import angel.game.RoomCombat;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class StartCombatAction implements IAction {
		
		public function StartCombatAction() {
			
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			return new StartCombatAction();
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			doAtEnd.push(changeModeToCombat);
			return null;
		}
		
		private function changeModeToCombat():void {
			Settings.currentRoom.changeModeTo(RoomCombat);
		}
		
	}

}