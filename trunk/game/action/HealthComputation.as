package angel.game.action {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.Settings;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class HealthComputation implements IComputation {
		private var id:String;
		
		public function HealthComputation(param:String) {
			id = param;
		}
		
		/* INTERFACE angel.game.action.IComputation */
		
		public function value():int {
			var entity:ComplexEntity = ComplexEntity(Settings.currentRoom.entityInRoomWithId(id));
			if (entity == null) {
				Alert.show("Error! No character " + id + " in current room.");
				return 0;
			}
			return entity.currentHealth;
		}
		
	}

}