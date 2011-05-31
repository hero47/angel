package angel.common {
	import flash.display.BitmapData;
	import angel.common.CatalogEntry;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Currently this is the only type of inventory item we have.
	// Later this may expand into a general class for inventory items, or it may become a subclass of such a class.
	public class WeaponResource implements ICatalogedResource {
		private var entry:CatalogEntry;
		
		public var displayName:String = Defaults.GUN_DISPLAY_NAME;
		public var damage:int = Defaults.GUN_DAMAGE;
		
		public function WeaponResource() {
			
		}
		
		/* INTERFACE angel.common.ICatalogedResource */
		
		public function get catalogEntry():CatalogEntry {
			return entry;
		}
		
		public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry):void {
			// We don't have graphics for weapons yet, so this is the only version there is
			this.entry = entry;
			Util.setTextFromXml(this, "displayName", entry.xml, "displayName");
			Util.setIntFromXml(this, "damage", entry.xml, "damage");
			entry.xml = null;
		}
		
		public function dataFinishedLoading(bitmapData:BitmapData):void {
			// We don't have graphics for weapons yet, so this is irrelevant
			Assert.fail("Weapon should never load data from file");
			
		}
		
	}

}