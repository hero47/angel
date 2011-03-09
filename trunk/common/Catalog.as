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
		
		public static const PROP:int = 1;
		public static const WALKER:int = 2;
		public static const TILESET:int = 3;
		
		public var loaded:Boolean = false;
		
		protected var lookup:Object = new Object(); // associative array mapping name to CatalogEntry
		
		public function Catalog() {
		}

		
		// Loads data from specified file.
		// NOTE: File must be in the same directory that we're running from!
		public function loadFromXmlFile(filename:String):void {
			LoaderWithErrorCatching.LoadFile(filename, catalogXmlLoaded);
		}
		
		private var xml:XML; // hold xml until tileset loaded
		private function catalogXmlLoaded(event:Event):void {
			var duplicateNames:String = "";
			xml = new XML(event.target.data);
			for each (var propXml:XML in xml.prop) {
				addCatalogEntry(propXml, propXml.@file, PROP, duplicateNames);
			}
			for each (var walkerXml:XML in xml.walker) {
				addCatalogEntry(walkerXml, walkerXml.@file, WALKER, duplicateNames);
			}
			if (duplicateNames.length > 0) {
				duplicateNames = "WARNING: Duplicate name(s) in catalog:\n" + duplicateNames;
				Alert.show(duplicateNames);
			}
			loaded = true;
			dispatchEvent(new Event(CATALOG_LOADED_EVENT));
		}
		
		// add the specified entry. If it's a duplicate, replace previous one and add to duplicateNames for reporting
		private function addCatalogEntry(lookupName:String, filename:String, type:int, duplicateNames:String):void {
			if (lookup[lookupName] != undefined) {
				duplicateNames += lookupName + "\n";
			}
			var entry:CatalogEntry = new CatalogEntry();
			entry.filename = filename;
			entry.type = type;
			lookup[lookupName] = entry;			
		}
		
		// call the function, passing bitmapData as parameter
		public function retrieveBitmapData(propName:String, callback:Function):void {
			var entry:CatalogEntry = lookup[propName];
		
			if (entry == null) {
				Alert.show("Error: " + propName + " not in catalog.");
				entry = new CatalogEntry();
				lookup[propName] = entry;
				entry.bitmapData = makeDefaultBitmap(propName);
			}
			if (entry.bitmapData != null) {
				callback(entry.bitmapData);
				return;
			}
			
			LoaderWithErrorCatching.LoadBytesFromFile(entry.filename,
				function(event:Event):void {
					var bitmap:Bitmap = event.target.content;
					entry.bitmapData = bitmap.bitmapData;
					verifyCorrectSize(entry);
					callback(entry.bitmapData);
				}, function():void {
					entry.bitmapData = makeDefaultBitmap(propName);
					callback(entry.bitmapData);
				} 
			);
			
		}
		
		private function verifyCorrectSize(entry:CatalogEntry):void {
			if (entry.type == PROP) {
				if ((entry.bitmapData.width != Prop.WIDTH) || (entry.bitmapData.height != Prop.HEIGHT)) {
					Alert.show("Warning: prop file " + entry.filename + " has wrong dimensions!");
				}
			} else {
				if ((entry.bitmapData.width != Prop.WIDTH * 9) || (entry.bitmapData.height != Prop.HEIGHT * 3)) {
					Alert.show("Warning: walker file " + entry.filename + " has wrong dimensions!");
				}
			}
		}

		private function makeDefaultBitmap(propName:String):BitmapData {
			var bitmapData:BitmapData = new BitmapData(Prop.WIDTH, Prop.HEIGHT, false, 0xff00ff);
			var myTextField:TextField = new TextField();
			myTextField.selectable = false;
			myTextField.text = propName;
			myTextField.type = TextFieldType.DYNAMIC;
			bitmapData.draw(myTextField);
			return bitmapData;
		}
		
	} // end class Catalog

}
