package angel.game.script.condition {
	import angel.common.Alert;
	import angel.game.ComplexEntity;
	import angel.game.script.Script;
	import angel.game.script.ScriptContext;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class InventoryHasCondition implements ICondition {
		private var id:String;
		private var itemText:String;
		private var desiredValue:Boolean = true;
		
		public static const TAG:String = "inventoryHas";
		
		public function InventoryHasCondition(id:String, itemText:String) {
			this.id = id;
			this.itemText = itemText;
		}
		
		public static function isSimpleCondition():Boolean {
			return false;
		}
		
		public static function createFromXml(conditionXml:XML, script:Script):ICondition {
			if (script.requires(TAG, "id", conditionXml) || script.requires(TAG, "list", conditionXml)) {
				return null;
			}
			return new InventoryHasCondition(conditionXml.@id, conditionXml.@list);
		}
		
		
		/* INTERFACE angel.game.script.condition.ICondition */
		
		public function isMet(context:ScriptContext):Boolean {
			var entity:ComplexEntity = context.charWithScriptId(id, TAG);
			if (entity == null) {
				return false;
			}
			return (entity.inventory.hasByText(itemText, context.messages) ? desiredValue : !desiredValue);
		}
		
		public function reverseMeaning():void {
			desiredValue = false;
		}
		
	}

}