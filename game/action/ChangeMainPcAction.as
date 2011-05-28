package angel.game.action {
	import angel.common.Alert;
	import angel.game.brain.BrainFollow;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ChangeMainPcAction implements IAction {
		private var id:String;
		
		public function ChangeMainPcAction(id:String) {
			this.id = id;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			return new ChangeMainPcAction(actionXml.@id);
			
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			var newMainPc:ComplexEntity = ComplexEntity(Script.entityWithScriptId(id));
			var oldMainPc:ComplexEntity = Settings.currentRoom.mainPlayerCharacter;
			if (oldMainPc == newMainPc) {
				return null; // already is main pc, no need to do anything
			}
			if (Settings.moveToFrontOfPlayerList(newMainPc)) {
				Settings.currentRoom.changeMainPlayerCharacterTo(newMainPc);
				oldMainPc.setBrain(true, BrainFollow, id);
				newMainPc.setBrain(true, null, null);
			} else {
				Alert.show("Error in changeMainPc: " + id + " is not a player character.");
			}
			return null;
		}
		
	}

}