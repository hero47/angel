package angel.game.script.action {
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
		
		public static const TAG:String = "changeToNpc";
		
		public function ChangeToNpcAction(id:String, explore:Class, exploreParam:String, combat:Class, combatParam:String, otherXml:XML) {
			this.id = id;
			this.exploreBrainClass = explore;
			this.combatBrainClass = combat;
			this.exploreParam = exploreParam;
			this.combatParam = combatParam;
			this.commonXml = otherXml;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "id", actionXml)) {
				return null;
			}
			var otherXml:XML = actionXml.copy();
			for each (var attributeName:String in ["explore", "exploreParam", "combat", "combatParam", "id", "x", "y", "spot"]) {
				if (otherXml.@[attributeName].length() > 0) { // delete these
					delete otherXml.@[attributeName];
				}
			}
			return new ChangeToNpcAction(actionXml.@id, UtilBrain.exploreBrainClassFromString(actionXml.@explore), actionXml.@exploreParam,
				UtilBrain.combatBrainClassFromString(actionXml.@combat), actionXml.@combatParam, otherXml);
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var entity:ComplexEntity = context.charWithScriptId(id, TAG);
			if (entity != null) {
				if (entity.isReallyPlayer) {
					if (entity == context.room.mainPlayerCharacter) {
						context.scriptError("Cannot change main player character to NPC, must make someone else main first.", TAG);
						return null;
					}
					entity.setBrain(false, combatBrainClass, combatParam);
					entity.setBrain(true, exploreBrainClass, exploreParam);
					entity.setCommonPropertiesFromXml(commonXml);
					entity.changePlayerControl(false, ComplexEntity.factionFromName(commonXml.@faction));
				}
			} 
			return null;
		}
		
	}

}