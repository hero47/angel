package angel.game.combat {
	import angel.common.InventoryResourceBase;
	import angel.common.WeaponResource;
	import angel.game.inventory.CanBeInInventory;
	import angel.game.Settings;
	import flash.display.BitmapData;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatUsableBase {
		protected var myId:String;
		public var name:String;
		private var iconBitmapData:BitmapData;
		
		public function CombatUsableBase(resource:InventoryResourceBase, id:String) {
			this.myId = id;
			this.name = resource.displayName;
			this.iconBitmapData = resource.iconBitmapData;
		}
		
		public function get id():String {
			return myId;
		}
		
		public function get displayName():String {
			return name;
		}
		
		public function get iconData():BitmapData {
			return iconBitmapData;
		}
		
		public function clone():CanBeInInventory {
			var resource:WeaponResource = Settings.catalog.retrieveWeaponResource(id);
			var copy:CanBeInInventory = new resource.itemClass(resource, id);
			return copy;
		}
		
	}

}