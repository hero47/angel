package angel.common {
	import angel.game.Icon;
	import angel.game.inventory.CanBeInInventory;
	import angel.game.inventory.IInventoryResource;
	import flash.display.BitmapData;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class InventoryResourceBase extends ImageResourceBase implements IInventoryResource {		
		
		public var id:String;
		public var myItemClass:Class; // public so test can set it
		public var displayName:String = "unnamed";
		public var iconBitmapData:BitmapData;
		
		public function InventoryResourceBase() {
			
		}
		
		override public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void {
			super.prepareTemporaryVersionForUse(id, entry, errors);
			
			this.id = id;
			Util.setTextFromXml(this, "displayName", entry.xml, "displayName");
			//NOTE: subclass must set myItemClass and iconBitmapData!
		}
		
		protected function defaultBitmapData(iconClass:Class):BitmapData {
			var bitmapData:BitmapData = new BitmapData(Icon.STANDARD_ICON_SIZE, Icon.STANDARD_ICON_SIZE);
			Icon.copyIconData(iconClass, bitmapData);
			return bitmapData;
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData, param:Object = null):void {
			iconBitmapData.copyPixels(bitmapData, Icon.ICON_SIZED_RECTANGLE, Icon.ZEROZERO);
		}
		
		override protected function expectedBitmapSize():Point {
			return Icon.ICON_SIZED_POINT;
		}
		
		public function makeOne():CanBeInInventory {
			return new myItemClass(this, id);
		}
		
		public function get itemClass():Class {
			return myItemClass;
		}
		
	}

}