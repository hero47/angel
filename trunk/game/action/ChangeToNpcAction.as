package angel.game.action {
	import angel.common.Alert;
	import angel.common.Util;
	import angel.game.brain.BrainFollow;
	import angel.game.ComplexEntity;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import angel.game.Walker;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ChangeToNpcAction implements IAction {
		private var id:String;
		private var exploreBrainClass:Class;
		private var combatBrainClass:Class;
		
		public function ChangeToNpcAction(id:String, explore:Class, combat:Class) {
			this.id = id;
			this.exploreBrainClass = explore;
			this.combatBrainClass = combat;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			return new ChangeToNpcAction(actionXml.@id, Walker.exploreBrainClassFromString(actionXml.@explore),
				Walker.combatBrainClassFromString(actionXml.@combat));
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			var entityWithId:SimpleEntity = Settings.currentRoom.entityInRoomWithId(id);
			if (entityWithId is ComplexEntity) {
				var entity:ComplexEntity = ComplexEntity(entityWithId);
				entity.combatBrainClass = combatBrainClass;
				entity.exploreBrainClass = exploreBrainClass;
				entity.changePlayerControl(false);
			} else {
				Alert.show("Script error: no character " + id + " in room for changeToNpc");
			}
			return null;
		}
		
	}

}