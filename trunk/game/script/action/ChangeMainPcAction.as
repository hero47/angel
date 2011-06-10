package angel.game.script.action {
	import angel.common.Alert;
	import angel.game.brain.BrainFollow;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ChangeMainPcAction implements IAction {
		private var id:String;
		
		public static const TAG:String = "changeMainPc";
		
		public function ChangeMainPcAction(id:String) {
			this.id = id;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "id", actionXml)) {
				return null;
			}
			return new ChangeMainPcAction(actionXml.@id);
			
		}
		
		/* INTERFACE angel.game.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var newMainPc:ComplexEntity = context.charWithScriptId(id, TAG);
			var oldMainPc:ComplexEntity = context.room.mainPlayerCharacter;
			if ((newMainPc == null) || (newMainPc == oldMainPc)) {
				return null; // already is main pc, or already gave error; no need to do anything
			}
			if (newMainPc.isReallyPlayer) {
				context.room.changeMainPlayerCharacterTo(newMainPc);
				oldMainPc.setBrain(true, BrainFollow, id);
				newMainPc.setBrain(true, null, null);
			} else {
				context.scriptError(id + " is not a player character.", TAG);
			}
			return null;
		}
		
	}

}