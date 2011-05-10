package angel.common {
import flash.display.Bitmap;
import flash.display.BitmapData;


	public class CatalogEntry {
		
		public static const NO_TYPE:int = 0;
		public static const PROP:int = 1;
		public static const WALKER:int = 2;
		public static const TILESET:int = 3;
		public static const xmlTag:Vector.<String> = Vector.<String>(["unknown", "prop", "walker", "tileset"]);
		
		public var filename:String;
		public var type:int;
		public var data:ICatalogedResource;	// null if not yet loaded
		public var xml:XML;	// CONSIDER: store this in more compact type-specific format?
		
		public function CatalogEntry(filename:String, type:int) {
			this.filename = filename;
			this.type = type;
		}
	
	}

}