package angel.game.script.action {
	import angel.common.Alert;
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class RemoveFromInventoryAction implements IAction {
		private var id:String;
		private var itemText:String;
		
		public static const TAG:String = "removeFromInventory";
		
		public function RemoveFromInventoryAction(id:String, itemText:String) {
			this.id = id;
			this.itemText = itemText;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "id", actionXml) || script.requires("removeFromInventory", "list", actionXml)) {
				return null;
			}
			return new RemoveFromInventoryAction(actionXml.@id, actionXml.@list);
		}
		
		/* INTERFACE angel.game.script.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var entity:ComplexEntity = context.charWithScriptId(id, TAG);
			if (entity != null) {
				entity.inventory.removeFromAnywhereByText(itemText, context.messages);
			}
			return null;
		}
		
	}

}