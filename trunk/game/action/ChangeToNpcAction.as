package angel.game.action {
	import angel.common.Alert;
	import angel.common.Util;
	import angel.game.brain.BrainFollow;
	import angel.game.brain.UtilBrain;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ChangeToNpcAction implements IAction {
		private var id:String;
		private var commonXml:XML;
		private var exploreBrainClass:Class;
		private var combatBrainClass:Class;
		private var exploreParam:String;
		private var combatParam:String;
		
		public function ChangeToNpcAction(id:String, explore:Class, exploreParam:String, combat:Class, combatParam:String, otherXml:XML) {
			this.id = id;
			this.exploreBrainClass = explore;
			this.combatBrainClass = combat;
			this.exploreParam = exploreParam;
			this.combatParam = combatParam;
			this.commonXml = otherXml;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			var otherXml:XML = actionXml.copy();
			for each (var attributeName:String in ["explore", "exploreParam", "combat", "combatParam", "id", "x", "y", "spot"]) {
				if (otherXml.@[attributeName].length() > 0) {
					delete otherXml.@[attributeName];
				}
			}
			return new ChangeToNpcAction(actionXml.@id, UtilBrain.exploreBrainClassFromString(actionXml.@explore), actionXml.@exploreParam,
				UtilBrain.combatBrainClassFromString(actionXml.@combat), actionXml.@combatParam, otherXml);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var entityWithId:SimpleEntity = context.entityWithScriptId(id);
			if (entityWithId is ComplexEntity) {
				var entity:ComplexEntity = ComplexEntity(entityWithId);
				if (entity.isReallyPlayer) {
					if (entity == context.room.mainPlayerCharacter) {
						Alert.show("Error! Cannot change main player character to NPC, must make someone else main first.");
						return null;
					}
					entity.setBrain(false, combatBrainClass, combatParam);
					entity.setBrain(true, exploreBrainClass, exploreParam);
					entity.setCommonPropertiesFromXml(commonXml);
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