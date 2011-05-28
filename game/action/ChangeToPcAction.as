package angel.game.action {
	import angel.common.Alert;
	import angel.game.brain.BrainFollow;
	import angel.game.brain.CombatBrainUiMeldPlayer;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ChangeToPcAction implements IAction {
		private var id:String;
		
		public function ChangeToPcAction(id:String) {
			this.id = id;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			return new ChangeToPcAction(actionXml.@id);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			var entityWithId:SimpleEntity = Script.entityWithScriptId(id);
			if (entityWithId is ComplexEntity) {
				var entity:ComplexEntity = ComplexEntity(entityWithId);
				entity.setBrain(false, CombatBrainUiMeldPlayer, null);
				entity.setBrain(true, BrainFollow, Settings.currentRoom.mainPlayerCharacter.id);
				entity.changePlayerControl(true);
				Settings.addToPlayerList(entity);
			} else {
				Alert.show("Script error: no character " + id + " in room for changeToPc");
			}
			return null;
		}
		
	}

}