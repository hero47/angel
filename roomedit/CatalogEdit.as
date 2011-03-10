package angel.roomedit {
	import angel.common.Catalog;
	import angel.common.CatalogEntry;
	import flash.events.Event;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	

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
		
		override protected function catalogXmlLoaded(event:Event):void {
			// Cache catalog xml so we can re-save it later, rather than re-creating
			// This should hopefully preserve any comments & formatting the author may have inserted
			catalogXml = new XML(event.target.data);
			super.catalogXmlLoaded(event);
		}
		
		public function save():void {
			saveXmlToFile(catalogXml, "AngelCatalog.xml");
		}
		
		// UNDONE: This really belongs in a util class somewhere
		public static function saveXmlToFile(xml:XML, defaultFilename:String):void {
			// convert xml to binary data
			var ba:ByteArray = new ByteArray( );
			ba.writeUTFBytes( xml );
 
			// save to disk
			var fr:FileReference = new FileReference( );
			fr.save( ba, defaultFilename );
		}
		
		public function changeXml(id:String):void {
			var entry:CatalogEntry = lookup[id];
			var tag:String = CatalogEntry.xmlTag[entry.type];
		}
		
		public function allPropNames():Array {
			var all:Array = new Array();
			for (var foo:String in lookup) {
				var entry:CatalogEntry = lookup[foo];
				if (entry.type == CatalogEntry.PROP) {
					all.push(foo);
				}
			}
			all.sort();
			return all;
		}
		
	}

}