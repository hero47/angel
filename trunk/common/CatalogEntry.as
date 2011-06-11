package angel.common {
import flash.display.Bitmap;
import flash.display.BitmapData;


	//Catalog entries are created at init time for everything in the catalog, with null data.  The first time the game needs to
	//use any particular entry, it creates that resource (loading the image from a file) and keeps a reference to it in the
	//catalog entry.  Every later time that the game wants to use that same entry, the catalog returns that reference.
	//I'm expecting that as the game grows, eventually we will want to free up resources that are no longer in use;
	//at that time the CatalogEntry should be expanded to keep a usage count, free resources when the count drops to zero
	//(or possibly when it's remained at zero through some predetermined time, like a room change), and return the catalog
	//entry to the "not yet loaded" state.
	//
	//NOTE: Currently the cataloged resources that use XML for part of their initialization are deleting the xml once
	//they initialize themselves.  Before moving to the "resource management" stage, I need to either separate the "loaded
	//from file" vs. "created from xml" parts of the cataloged resource so I can keep the "created from xml" part when
	//freeing up the "loaded from file" part, or keep the xml so that the cataloged resource can use it again to
	//re-create itself after disposal.
	
	public class CatalogEntry {
		
		public static const PROP:Class = PropResource;
		public static const CHARACTER:Class = CharResource;
		public static const TILESET:Class = Tileset;
		public static const WEAPON:Class = WeaponResource;
		public static const SPLASH:Class = SplashResource;
		
		public var filename:String;
		public var type:Class;
		public var data:ICatalogedResource;	// null if not yet loaded
		public var xml:XML;	// CONSIDER: store this in more compact type-specific format?
		
		public function CatalogEntry(filename:String, type:Class) {
			this.filename = filename;
			this.type = type;
		}
	
	}

}