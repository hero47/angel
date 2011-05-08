package angel.roomedit {
	import angel.common.Catalog;
	import angel.common.CatalogEntry;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Util;
	import fl.controls.ComboBox;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	

	public class CatalogEdit extends Catalog {
		
		private var filename:String;
		private var catalogXml:XML;
		
		public function CatalogEdit() {
			
		}
		
		override public function loadFromXmlFile(filename:String):void {
			// Cache filename so we can use it later to re-save
			this.filename = filename;
			super.loadFromXmlFile(filename);
		}
		
		override protected function catalogXmlLoaded(event:Event, filename:String):void {
			// Cache catalog xml so we can re-save it later, rather than re-creating
			// This should hopefully preserve any comments & formatting the author may have inserted
			catalogXml = new XML(event.target.data);
			super.catalogXmlLoaded(event, filename);
		}
		
		public function save():void {
			Util.saveXmlToFile(catalogXml, "AngelCatalog.xml");
		}
		
		public function appendXml(newXml:XML):void {
			catalogXml.appendChild(newXml);
		}

		public function changeXml(id:String, newXml:XML):void {
			var entry:CatalogEntry = lookup[id];
			var tag:String = CatalogEntry.xmlTag[entry.type];
			
			var current:XMLList = catalogXml[tag].(@id == id);
			
			current[0] = newXml;
		}
		
		public function changeXmlAttribute(id:String, attribute:String, newValue:String):void {
			var entry:CatalogEntry = lookup[id];
			var tag:String = CatalogEntry.xmlTag[entry.type];
			
			var current:XMLList = catalogXml[tag].(@id == id);
			current[0].@[attribute] = newValue;
		}
		
		public function deleteXmlAttribute(id:String, attribute:String):void {
			var entry:CatalogEntry = lookup[id];
			var tag:String = CatalogEntry.xmlTag[entry.type];
			
			var current:XMLList = catalogXml[tag].(@id == id);
			if (current[0].@[attribute].length() > 0) {
				delete current[0].@[attribute];
			}
		}
		
		// Create a combobox holding all catalog ids for the given CatalogEntry type.
		// Due to pecularities of ComboBox, we embed it in a holder object.
		public function createChooser(type:int, width:int = 200):ComboHolder {
			var combo:ComboBox = new ComboBox();
			combo.width = width;
			
			var allNamesOfThisType:Array = allNames(type);
			for (var i:int = 0; i < allNamesOfThisType.length; i++) {
				combo.addItem( { label:allNamesOfThisType[i] } );
			}
			
			return new ComboHolder(width, combo);
		}
		
		public function allNames(type:int):Array {
			var all:Array = new Array();
			for (var foo:String in lookup) {
				var entry:CatalogEntry = lookup[foo];
				if (entry.type == type) {
					all.push(foo);
				}
			}
			all.sort();
			return all;
		}
		
		// throw away the cached data for this id, so it will be reloaded from file when requested, and set its catalog xml
		// to match current in-memory catalog xml
		// NOTE: this is not resource manager, just a quick-and-dirty for editor!  I'm not even looking at possible memory leaks.
		public function discardCachedData(id:String):void {
			var entry:CatalogEntry = lookup[id];
			if (entry != null) {
				entry.data = null;
				var tag:String = CatalogEntry.xmlTag[entry.type];
				var current:XMLList = catalogXml[tag].(@id == id);
				entry.xml = current[0];
				trace(entry.xml);
			}
		}
		
		// NOTE: this is not resource manager, just a quick-and-dirty for editor!  I'm not even looking at possible memory leaks.
		public function changeFilename(id:String, newFilename:String):void {
			var entry:CatalogEntry = lookup[id];
			if (entry != null) {
				changeXmlAttribute(id, "file", newFilename);
				entry.filename = newFilename;
				LoaderWithErrorCatching.LoadBytesFromFile(entry.filename,
					function(event:Event, filename:String):void {
						var bitmap:Bitmap = event.target.content;
						warnIfBitmapIsWrongSize(entry, bitmap.bitmapData);
						entry.data.dataFinishedLoading(bitmap.bitmapData);
					}
				);
			}
		}
		
		public function getFilenameFromId(id:String):String {
			var entry:CatalogEntry = lookup[id];
			if (entry == null) {
				return null;
			}
			return entry.filename;
		}
		
	}

}