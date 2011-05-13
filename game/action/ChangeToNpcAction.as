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
		private var exploreParam:String;
		private var combatParam:String;
		
		public function ChangeToNpcAction(id:String, explore:Class, exploreParam:String, combat:Class, combatParam:String) {
			this.id = id;
			this.exploreBrainClass = explore;
			this.combatBrainClass = combat;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			return new ChangeToNpcAction(actionXml.@id, Walker.exploreBrainClassFromString(actionXml.@explore), actionXml.@exploreParam,
				Walker.combatBrainClassFromString(actionXml.@combat), actionXml.@combatParam);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(doAtEnd:Vector.<Function>):Object {
			var entityWithId:SimpleEntity = Settings.currentRoom.entityInRoomWithId(id);
			if (entityWithId is ComplexEntity) {
				var entity:ComplexEntity = ComplexEntity(entityWithId);
				if (entity.isReallyPlayer) {
					entity.combatBrainClass = combatBrainClass;
					entity.exploreBrainClass = exploreBrainClass;
					entity.changePlayerControl(false);
					Settings.removeFromPlayerList(entity);
				}
			} else {
				Alert.show("Script error: no character " + id + " in room for changeToNpc");
			}
			return null;
		}
		
	}

}