package angel.common {
	import angel.game.inventory.IInventoryResource;
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
		private var presetXml:XML =
		<catalog>
			<char file="prp_grenade_landed.png" id="__grenade" health="1" top="96" />
		</catalog>
		
		public var loaded:Boolean = false;
		
		protected var lookup:Object = new Object(); // associative array mapping name to CatalogEntry
		
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
		
		protected function catalogXmlLoaded(event:Event, param:Object, filenameForErrors:String):void {
			var errors:MessageCollector = new MessageCollector();
			var xml:XML = Util.parseXml(event.target.data, filenameForErrors);
			if (xml == null) {
				return;
			}
			
			xml.appendChild(presetXml.children());
			
			var entry:CatalogEntry;
			for each (var propXml:XML in xml.prop) {
				entry = addCatalogEntry(propXml.@id, propXml.@file, propXml, CatalogEntry.PROP, errors);
			}
			for each (var charXml:XML in xml.char) {
				entry = addCatalogEntry(charXml.@id, charXml.@file, charXml, CatalogEntry.CHARACTER, errors);
			}
			for each (var weaponXml:XML in xml.weapon) {
				entry = addCatalogEntry(weaponXml.@id, weaponXml.@file, weaponXml, CatalogEntry.WEAPON, errors);
			}
			for each (var gizmoXml:XML in xml.gizmo) {
				entry = addCatalogEntry(gizmoXml.@id, gizmoXml.@file, gizmoXml, CatalogEntry.GIZMO, errors);
			}
			for each (var splashXml:XML in xml.splash) {
				entry = addCatalogEntry(splashXml.@id, splashXml.@file, splashXml, CatalogEntry.SPLASH, errors);
			}
			for each (var tilesetXml:XML in xml.tileset) {
				entry = addCatalogEntry(tilesetXml.@id, tilesetXml.@file, tilesetXml, CatalogEntry.TILESET, errors);
			}
			
			errors.endSection("WARNING: Duplicate name(s) in catalog:");
			errors.displayIfNotEmpty("Errors loading catalog!");
			loaded = true;
			dispatchEvent(new Event(Event.INIT));
		}
		
		// add the specified entry. If it's a duplicate, add to errors for reporting & return null
		public function addCatalogEntry(id:String, filename:String, xml:XML, type:Class, errors:MessageCollector = null):CatalogEntry {
			if (lookup[id] != undefined) {
				MessageCollector.collectOrShowMessage(errors, id);
				return null;
			}
			var entry:CatalogEntry = new CatalogEntry(filename, type);
			entry.xml = xml;
			lookup[id] = entry;
			return entry;
		}
		
		public function retrievePropResource(id:String, errors:MessageCollector = null):PropResource {
			return loadOrRetrieveCatalogEntry(id, PropResource, errors) as PropResource;
		}
		
		public function retrieveCharacterResource(id:String, errors:MessageCollector = null):CharResource {
			return loadOrRetrieveCatalogEntry(id, CharResource, errors) as CharResource;
		}
		
		public function retrieveWeaponResource(id:String, errors:MessageCollector = null):WeaponResource {
			return loadOrRetrieveCatalogEntry(id, WeaponResource, errors) as WeaponResource;
		}
		
		public function retrieveSplashResource(id:String, errors:MessageCollector = null):SplashResource {
			return loadOrRetrieveCatalogEntry(id, SplashResource, errors) as SplashResource;
		}

		public function retrieveTileset(tilesetId:String, errors:MessageCollector = null):Tileset {
			return loadOrRetrieveCatalogEntry(tilesetId, Tileset, errors) as Tileset;
		}
		
		public function retrieveInventoryResource(id:String, errors:MessageCollector = null):IInventoryResource {
			var entry:CatalogEntry = entry(id);
			if (entry == null) {
				MessageCollector.collectOrShowMessage(errors, "Unknown inventory item " + id);
				return null;
			}
			return loadOrRetrieveCatalogEntry(id, entry.type, errors) as IInventoryResource;
		}
		
		// finishEntry takes CatalogEntry with data set to bitmapData (and xml if appropriate),
		// and replaces data with the finished object to cache
		private function loadOrRetrieveCatalogEntry(id:String, type:Class, errors:MessageCollector = null):ICatalogedResource {
			var entry:CatalogEntry = lookup[id];
		
			if (entry == null) {
				MessageCollector.collectOrShowMessage(errors, "Error: " + id + " not in catalog.");
				entry = new CatalogEntry(null, type);
				lookup[id] = entry;
			}
			
			if (entry.type != type) {
				MessageCollector.collectOrShowMessage(errors, "Error! Catalog entry " + id + " is wrong type.");
			}
			
			if (entry.data != null) {
				return entry.data;
			}

			//UNDONE: remove this when catalog entries have stabilized
			temporaryMungeXmlForOldData(type, entry.xml, errors);
			
			entry.data = new type();
			entry.data.prepareTemporaryVersionForUse(id, entry, errors);


			return entry.data;
		}
		private function makeDefaultTileset(id:String):Tileset {
			return new Tileset();
		}
		
		
		//UNDONE: remove this when catalog entries have stabilized
		private function temporaryMungeXmlForOldData(type:Class, xml:XML, errors:MessageCollector):void {
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
					addCatalogEntry(weaponId, null, weaponXml, CatalogEntry.WEAPON, errors);
				}
				
				xml.@mainGun = weaponId;
			}
		}
			
	} // end class Catalog

}
