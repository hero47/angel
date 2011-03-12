package angel.roomedit {
	import angel.common.Catalog;
	import angel.common.CatalogEntry;
	import fl.controls.ComboBox;
	import flash.display.Sprite;
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
		
		public function appendXml(newXml:XML):void {
			catalogXml.appendChild(newXml);
			trace(catalogXml);
		}

		public function changeXml(id:String, newXml:XML):void {
			var entry:CatalogEntry = lookup[id];
			var tag:String = CatalogEntry.xmlTag[entry.type];
			
			var current:XMLList = catalogXml.tileset.(@id == id);
			
			current[0] = newXml;
		}
		
		// Create a combobox holding all catalog ids for the given CatalogEntry type.
		// Due to pecularities of ComboBox, we embed it in a Sprite.  The actual ComboBox is getChildAt(0) of the sprite!
		public function createChooser(type:int):Sprite {
			var combo:ComboBox = new ComboBox();
			combo.width = 200;
			
			var allNamesOfThisType:Array = allNames(type);
			for (var i:int = 0; i < allNamesOfThisType.length; i++) {
				combo.addItem( { label:allNamesOfThisType[i] } );
			}
			
			// WARNING: ComboBox violates all sorts of groundrules.  It changes parent's height to MORE than its
			// own height property.  Also, if its width is increased it sticks out  past the edge of its parent
			// without changing parent's width.
			// The best workaround I've found for this is to enclose it in a sprite (which fixes the height
			// problem) and draw an invisible line across the correct width.
			var foo:Sprite = new Sprite();
			foo.graphics.moveTo(0, 0);
			foo.graphics.lineTo(200, 0);
			foo.addChild(combo);
			return foo;
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
		
	}

}