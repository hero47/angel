package angel.game.action {
	import angel.common.Alert;
	import angel.game.BrainFollow;
	import angel.game.ComplexEntity;
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
			var entityWithId:SimpleEntity = Settings.currentRoom.entityInRoomWithId(id);
			if (entityWithId is ComplexEntity) {
				var entity:ComplexEntity = ComplexEntity(entityWithId);
				entity.bestFriend = Settings.currentRoom.mainPlayerCharacter;
				entity.combatBrainClass = null;
				entity.exploreBrainClass = BrainFollow;
				entity.changePlayerControl(true);
			} else {
				Alert.show("Script error: no character " + id + " in room for changeToPc");
			}
			return null;
		}
		
	}

}