package angel.game.script.action {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class AddToInventoryAction implements IAction {
		private var id:String;
		private var itemText:String;
		
		public static const TAG:String = "addToInventory";
		
		public function AddToInventoryAction(id:String, itemText:String) {
			this.id = id;
			this.itemText = itemText;
		}
		
		public static function createFromXml(actionXml:XML, script:Script):IAction {
			if (script.requires(TAG, "id", actionXml) || script.requires(TAG, "list", actionXml)) {
				return null;
			}
			return new AddToInventoryAction(actionXml.@id, actionXml.@list);
		}
		
		/* INTERFACE angel.game.script.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var entity:ComplexEntity = context.charWithScriptId(id, TAG);
			if (entity != null) {
				entity.inventory.addToPileFromText(itemText, context.messages);
			}
			return null;
		}
		
	}

}