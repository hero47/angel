package angel.game.script.action {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class AddToInventoryAction implements IAction {
		private var id:String;
		private var itemText:String;
		
		public function AddToInventoryAction(id:String, itemText:String) {
			this.id = id;
			this.itemText = itemText;
		}
		
		public static function createFromXml(actionXml:XML):IAction {
			if ((actionXml.@id.length() == 0) || (actionXml.@list.length() == 0)) {
				Alert.show("Script error: AddToInventory requires id and list");
				return null;
			}
			return new AddToInventoryAction(actionXml.@id, actionXml.@list);
		}
		
		/* INTERFACE angel.game.script.action.IAction */
		
		public function doAction(context:ScriptContext):Object {
			var entity:ComplexEntity = ComplexEntity(context.entityWithScriptId(id));
			if (entity == null) {
				Alert.show("Script error: no character " + id + " in room for addToInventory");
			} else {
				entity.inventory.addToPileFromText(itemText);
			}
			return null;
		}
		
	}

}