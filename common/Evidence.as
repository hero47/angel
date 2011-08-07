package angel.common {
	import angel.game.inventory.CanBeInInventory;
	import angel.game.inventory.IInventoryResource;
	import angel.game.Settings;
	import flash.display.BitmapData;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Evidence implements CanBeInInventory {
		protected var myId:String;
		public var name:String;
		private var iconBitmapData:BitmapData;
		
		public function Evidence(resource:InventoryResourceBase, id:String) {
			this.myId = id;
			this.name = resource.displayName;
			this.iconBitmapData = resource.iconBitmapData;
		}
		
		/* INTERFACE angel.game.inventory.CanBeInInventory */
		
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
			var resource:IInventoryResource = Settings.catalog.retrieveInventoryResource(myId);
			var copy:CanBeInInventory = new resource.itemClass(resource, myId);
			return copy;
		}
		
		public function stacksWith(other:CanBeInInventory):Boolean {
			return ((other != null) && (other.id == myId));
		}
		
		public function imageBitmapData():BitmapData {
			var resource:EvidenceResource = EvidenceResource(Settings.catalog.retrieveInventoryResource(myId));
			return resource.imageBitmapData;
		}
		
	}

}