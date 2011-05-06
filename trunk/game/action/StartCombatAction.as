package angel.game.action {
	import angel.common.Alert;
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
			if (Settings.currentRoom.mode is RoomCombat) {
				Alert.show("Error! changeModeToCombat when already in combat");
			} else {
				Settings.currentRoom.changeModeTo(RoomCombat);
			}
		}
		
	}

}