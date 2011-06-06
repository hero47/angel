package angel.game.script.condition {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class InventoryHasCondition implements ICondition {
		private var id:String;
		private var itemText:String;
		private var desiredValue:Boolean = true;
		
		public function InventoryHasCondition(id:String, itemText:String) {
			this.id = id;
			this.itemText = itemText;
		}
		
		public static function isSimpleCondition():Boolean {
			return false;
		}
		
		public static function createFromXml(conditionXml:XML):ICondition {
			if ((conditionXml.@id.length() == 0) || (conditionXml.@list.length() == 0)) {
				Alert.show("Script error: InventoryHas requires id and list");
				return null;
			}
			return new InventoryHasCondition(conditionXml.@id, conditionXml.@list);
		}
		
		
		/* INTERFACE angel.game.script.condition.ICondition */
		
		public function isMet(context:ScriptContext):Boolean {
			var entity:ComplexEntity = ComplexEntity(context.entityWithScriptId(id));
			if (entity == null) {
				Alert.show("Script error: no character " + id + " in room for inventoryHas");
				return false;
			}
			return (entity.inventory.hasByText(itemText) ? desiredValue : !desiredValue);
		}
		
		public function reverseMeaning():void {
			desiredValue = false;
		}
		
	}

}