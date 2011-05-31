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
		
		protected function catalogXmlLoaded(event:Event, filename:String):void {
			var duplicateNames:String = "";
			var xml:XML = Util.parseXml(event.target.data, filename);
			if (xml == null) {
				return;
			}
			var entry:CatalogEntry;
			for each (var propXml:XML in xml.prop) {
				entry = addCatalogEntry(propXml.@id, propXml.@file, propXml, CatalogEntry.PROP, duplicateNames);
			}
			for each (var charXml:XML in xml.char) {
				entry = addCatalogEntry(charXml.@id, charXml.@file, charXml, CatalogEntry.CHARACTER, duplicateNames);
			}
			for each (var weaponXml:XML in xml.weapon) {
				//NOTE: weapons have no image yet; pass null for filename so we won't look for a file.
				entry = addCatalogEntry(weaponXml.@id, null, weaponXml, CatalogEntry.WEAPON, duplicateNames);
			}
			
			//UNDONE For backwards compatibility; remove this once old catalogs have been rewritten
			for each (var walkerXml:XML in xml.walker) {
				entry = addCatalogEntry(walkerXml.@id, walkerXml.@file, walkerXml, CatalogEntry.CHARACTER, duplicateNames);
			}
			
			for each (var tilesetXml:XML in xml.tileset) {
				entry = addCatalogEntry(tilesetXml.@id, tilesetXml.@file, tilesetXml, CatalogEntry.TILESET, duplicateNames);
			}
			
			if (duplicateNames.length > 0) {
				message("WARNING: Duplicate name(s) in catalog:\n" + duplicateNames);
			}
			loaded = true;
			dispatchEvent(new Event(Event.INIT));
		}
		
		protected function message(text:String):void {
			if (collectMessages == null) {
				Alert.show(text);
			} else {
				collectMessages += text;
			}
		}
		
		// add the specified entry. If it's a duplicate, add to duplicateNames for reporting & return null
		public function addCatalogEntry(id:String, filename:String, xml:XML, type:int, duplicateNames:String = null):CatalogEntry {
			if (lookup[id] != undefined) {
				if (duplicateNames != null) {
					duplicateNames += id + "\n";
				}
				return null;
			}
			var entry:CatalogEntry = new CatalogEntry(filename, type);
			entry.xml = xml;
			lookup[id] = entry;
			return entry;
		}
		
		public function retrievePropResource(id:String):RoomContentResource {
			return retrieveRoomContentResource(id, CatalogEntry.PROP);
		}
		
		public function retrieveCharacterResource(id:String):RoomContentResource {
			return retrieveRoomContentResource(id, CatalogEntry.CHARACTER);
		}
		
		public function retrieveRoomContentResource(id:String, type:int):RoomContentResource {
			return loadOrRetrieveCatalogEntry(id, type, RoomContentResource) as RoomContentResource;
		}
		
		public function retrieveWeaponResource(id:String):WeaponResource {
			return loadOrRetrieveCatalogEntry(id, CatalogEntry.WEAPON, WeaponResource) as WeaponResource;
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
				entry = new CatalogEntry(null, type);
				lookup[id] = entry;
			}
			
			if (entry.type != type) {
				Alert.show("Error! Catalog entry " + id + " is wrong type.");
				return null;
			}
			
			if (entry.data != null) {
				return entry.data;
			}

			//UNDONE: remove this when catalog entries have stabilized
			temporaryMungeXmlForOldData(type, entry.xml);
			
			entry.data = new resourceClass();
			entry.data.prepareTemporaryVersionForUse(id, entry);

			if (inCatalog && (entry.filename != null) && (entry.filename != "")) {
				LoaderWithErrorCatching.LoadBytesFromFile(entry.filename,
					function(event:Event, filename:String):void {
						var bitmap:Bitmap = event.target.content;
						warnIfBitmapIsWrongSize(entry, bitmap.bitmapData);
						entry.data.dataFinishedLoading(bitmap.bitmapData);
					}
				);
			}

			return entry.data;
		}
		
		protected function warnIfBitmapIsWrongSize(entry:CatalogEntry, bitmapData:BitmapData):void {
			if (entry.type == CatalogEntry.CHARACTER) {
				//NOTE: CatalogEntry.CHARACTER will check this itself since it can take several different sizes
				return;
			}
			var typeName:String;
			var correctWidth:int;
			var correctHeight:int;
			switch (entry.type) {
				case CatalogEntry.PROP:
					typeName = "Prop";
					correctWidth = Prop.WIDTH;
					correctHeight = Prop.HEIGHT;
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
		
		
		//UNDONE: remove this when catalog entries have stabilized
		private function temporaryMungeXmlForOldData(type:int, xml:XML):void {
			if (xml == null) {
				return;
			}
			
			//UNDONE: temporary code to allow using catalog entries from before weapons existed
			if ((type == CatalogEntry.CHARACTER) && (xml.@mainGun.length() == 0) && (xml.@damage.length() > 0)) {
				var damage:int = int(xml.@damage);
				var weaponId:String = "__temp_gun_" + damage;
				if (entry(weaponId) == null) {
					var weaponXml:XML = <weapon />;
					weaponXml.@displayName = weaponId;
					weaponXml.@damage = damage;
					addCatalogEntry(weaponId, null, weaponXml, CatalogEntry.WEAPON);
				}
				
				xml.@mainGun = weaponId;
			}
		}
			
	} // end class Catalog

}
