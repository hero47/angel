package angel.game.script.action {
	import angel.common.Alert;
	import angel.game.brain.BrainFollow;
	import angel.game.brain.CombatBrainUiMeldPlayer;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
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
		
		public function doAction(context:ScriptContext):Object {
			var entityWithId:SimpleEntity = context.entityWithScriptId(id);
			if (entityWithId is ComplexEntity) {
				var entity:ComplexEntity = ComplexEntity(entityWithId);
				//CONSIDER: should we give error if it's already a player?
				if (!entity.isReallyPlayer) {
					entity.setBrain(false, CombatBrainUiMeldPlayer, null);
					entity.setBrain(true, BrainFollow, Settings.lastEntityOnPlayerList().id);
					entity.changePlayerControl(true, ComplexEntity.FACTION_FRIEND);
					Settings.addToPlayerList(entity);
				}
			} else {
				Alert.show("Script error: no character " + id + " in room for changeToPc");
			}
			return null;
		}
		
	}

}