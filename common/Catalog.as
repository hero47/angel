package angel.common {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.utils.Dictionary;

	// Initially, this will permanently cache each BitmapData created from the files.
	// Later, we'll want some sort of resource management to count usage and unload when no longer needed.
	public class Catalog extends EventDispatcher {
		public static const CATALOG_LOADED_EVENT:String = "catalogLoaded";
		
		public var loaded:Boolean = false;
		
		protected var lookup:Object = new Object(); // associative array mapping name to CatalogEntry
		protected var collectMessages:String = null; // if not null, suppress warning/error messages and stash them here instead
		
		public function Catalog() {
		}

		public function entry(id:String):CatalogEntry {
			return lookup[id];
		}
		
		// Loads data from specified file.
		// NOTE: File must be in the same directory that we're running from!
		public function loadFromXmlFile(filename:String):void {
			LoaderWithErrorCatching.LoadFile(filename, catalogXmlLoaded);
		}
		
		protected function catalogXmlLoaded(event:Event):void {
			var duplicateNames:String = "";
			var xml:XML = new XML(event.target.data);
			var entry:CatalogEntry;
			for each (var propXml:XML in xml.prop) {
				entry = addCatalogEntry(propXml.@id, propXml.@file, CatalogEntry.PROP, duplicateNames);
				if (entry != null) {
					entry.xml = propXml;
				}
			}
			for each (var walkerXml:XML in xml.walker) {
				entry = addCatalogEntry(walkerXml.@id, walkerXml.@file, CatalogEntry.WALKER, duplicateNames);
				if (entry != null) {
					entry.xml = walkerXml;
				}
			}
			for each (var tilesetXml:XML in xml.tileset) {
				entry = addCatalogEntry(tilesetXml.@id, tilesetXml.@file, CatalogEntry.TILESET, duplicateNames);
				if (entry != null) {
					entry.xml = tilesetXml;
				}
			}
			if (duplicateNames.length > 0) {
				message("WARNING: Duplicate name(s) in catalog:\n" + duplicateNames);
			}
			loaded = true;
			dispatchEvent(new Event(CATALOG_LOADED_EVENT));
		}
		
		protected function message(text:String):void {
			if (collectMessages != null) {
				Alert.show(text);
			} else {
				collectMessages += text;
			}
		}
		
		// add the specified entry. If it's a duplicate, add to duplicateNames for reporting & return null
		public function addCatalogEntry(id:String, filename:String, type:int, duplicateNames:String = null):CatalogEntry {
			if (lookup[id] != undefined) {
				if (duplicateNames != null) {
					duplicateNames += id + "\n";
				}
				return null;
			}
			var entry:CatalogEntry  = new CatalogEntry(filename, type);
			lookup[id] = entry;
			return entry;
		}
		
		// call the function, passing bitmapData as parameter
		public function retrievePropImage(propId:String):PropImage {
			return loadOrRetrieveCatalogEntry(propId, CatalogEntry.PROP, PropImage) as PropImage;
		}
		
		// call the function, passing walkerImage as parameter
		public function retrieveWalkerImage(walkerId:String):WalkerImage {
			return loadOrRetrieveCatalogEntry(walkerId, CatalogEntry.WALKER, WalkerImage) as WalkerImage;
		}

		// call the function, passing tileset as parameter
		public function retrieveTileset(tilesetId:String):Tileset {
			return loadOrRetrieveCatalogEntry(tilesetId, CatalogEntry.TILESET, Tileset) as Tileset;
		}
		
		// finishEntry takes CatalogEntry with data set to bitmapData (and xml if appropriate),
		// and replaces data with the finished object to cache
		private function loadOrRetrieveCatalogEntry(id:String, type:int, resourceClass:Class):ICatalogedResource {
			var entry:CatalogEntry = lookup[id];
			var inCatalog:Boolean = true;
		
			if (entry == null) {
				inCatalog = false;
				message("Error: " + id + " not in catalog.");
				entry = new CatalogEntry(id, type);
				lookup[id] = entry;
			}
			
			Assert.assertTrue(entry.type == type, "Catalog entry " + id + " is wrong type.");
			
			if (entry.data != null) {
				return entry.data;
			}

			entry.data = new resourceClass();
			entry.data.prepareTemporaryVersionForUse(id, entry);

			if (inCatalog) {
				LoaderWithErrorCatching.LoadBytesFromFile(entry.filename,
					function(event:Event):void {
						var bitmap:Bitmap = event.target.content;
						warnIfBitmapIsWrongSize(entry, bitmap.bitmapData);
						entry.data.dataFinishedLoading(bitmap.bitmapData);
					}
				);
			}

			return entry.data;
		}
		
		private function warnIfBitmapIsWrongSize(entry:CatalogEntry, bitmapData:BitmapData):void {
			var typeName:String;
			var correctWidth:int;
			var correctHeight:int;
			switch (entry.type) {
				case CatalogEntry.PROP:
					typeName = "Prop";
					correctWidth = Prop.WIDTH;
					correctHeight = Prop.HEIGHT;
				break;
				case CatalogEntry.WALKER:
					typeName = "Walker";
					correctWidth = Prop.WIDTH * 9;
					correctHeight = Prop.HEIGHT * 3;
				break;
				case CatalogEntry.TILESET:
					typeName = "Tileset";
					correctWidth = Tileset.TILESET_X;
					correctHeight = Tileset.TILESET_Y;
				break;
			}
			if ((bitmapData.width != correctWidth) || (bitmapData.height != correctHeight)) {
				message("Warning: " + typeName + " file " + entry.filename + " is not " +
						correctWidth + "x" + correctHeight + ".  Please fix!");
			}
		}
		
		private function makeDefaultTileset(id:String):Tileset {
			return new Tileset();
		}
		
	} // end class Catalog

}
