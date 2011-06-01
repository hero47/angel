package angel.game.script.action {
	import angel.common.Alert;
	import angel.game.combat.RoomCombat;
	import angel.game.script.ScriptContext;
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
		
		public function doAction(context:ScriptContext):Object {
			context.doThisAtEnd(changeModeToCombat);
			return null;
		}
		
		private function changeModeToCombat(context:ScriptContext):void {
			if (context.room.mode is RoomCombat) {
				Alert.show("Error! changeModeToCombat when already in combat");
			} else {
				context.room.changeModeTo(RoomCombat);
			}
		}
		
	}

}