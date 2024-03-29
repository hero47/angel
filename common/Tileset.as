package angel.common {
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class Tileset extends ImageResourceBase implements ICatalogedResource{
		
		protected static const TILESET_X_TILES:int = 4;
		protected static const TILESET_Y_TILES:int = 5;
		public static const TILES_IN_SET:int = (TILESET_X_TILES * TILESET_Y_TILES);
		public static const TILESET_X:int = 256;
		public static const TILESET_Y:int = 160;
		public static const TILE_WIDTH:int = TILESET_X / TILESET_X_TILES;	// 64
		public static const TILE_HEIGHT:int = TILESET_Y / TILESET_Y_TILES;	// 32
		
		private static var defaultTileData:BitmapData = null;
		
		public static const TAG:String = "tileset";
		
		protected var tiles:Vector.<BitmapData>;
		protected var tileNames:Vector.<String>;
		
		public function Tileset() {
			Assert.assertTrue(TILE_WIDTH == TILE_HEIGHT * 2, "Code tagged tile-width-is-twice-height will break!");
			getDefaultTileData();
			
			createBlankTiles();
		}
		
		public static function getDefaultTileData():BitmapData {
			if (defaultTileData == null) {
				defaultTileData = new BitmapData(TILE_WIDTH, TILE_HEIGHT, true, 0); // fully transparent
				
				var blankTileImage:Shape = new Shape();
				blankTileImage.graphics.lineStyle(0, 0xffffff);
				blankTileImage.graphics.beginFill(0x000000, 1);
				drawTileOutline(blankTileImage.graphics);
				blankTileImage.graphics.beginFill(0xffffff, 1);
				blankTileImage.graphics.drawCircle(TILE_WIDTH / 2, TILE_HEIGHT / 2, 2);
				
				defaultTileData.draw(blankTileImage);
			}
			return defaultTileData;
		}
		
		public static function drawTileOutline(graphics:Graphics):void {
			graphics.moveTo(TILE_WIDTH/2, 0);
			graphics.lineTo(TILE_WIDTH, TILE_HEIGHT / 2);
			graphics.lineTo(TILE_WIDTH / 2, TILE_HEIGHT);
			graphics.lineTo(0, TILE_HEIGHT / 2);
			graphics.lineTo(TILE_WIDTH/2, 0);			
		}
		
		override public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void {
			super.prepareTemporaryVersionForUse(id, entry, errors);
			if (entry.xml != null) {
				fillNamesFromXml(entry.xml);
				entry.xml = null;
			}
			createTilesToDrawOnLater();
		}
		
		override protected function expectedBitmapSize():Point {
			return new Point(TILESET_X, TILESET_Y);
		}
		
		// Copy new images onto the already-existing tiles (which may already be displayed)
		public function dataFinishedLoading(bitmapData:BitmapData, param:Object = null):void {
			var zerozero:Point = new Point(0, 0);
			var i:int = 0;
			for (var tileY:int = 0; tileY < TILESET_Y_TILES; tileY++) {
				for (var tileX:int = 0; tileX < TILESET_X_TILES; tileX++) {
					tiles[i].fillRect(tiles[i].rect, 0);
					var sourceRect:Rectangle = new Rectangle(tileX*TILE_WIDTH, tileY*TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT);
					tiles[i++].copyPixels(bitmapData, sourceRect, zerozero);
				}
			}
			bitmapData.dispose();
		}
		
		public function tileBitmapData(i:int):BitmapData {
			if (i < 0) {
				return defaultTileData;
			}
			return tiles[i];
		}
		
		public function fillNamesFromXml(tilesetXml:XML):void {
			var names:XMLList = tilesetXml.name;
			var i:int = 0;
			for each (var name:String in names) {
				tileNames[i++] = name;
			}
		}
		
		// Fill the tileset with references to the default image.  This is a temporary state, and it may
		// get phased out completely later in development?
		private function createBlankTiles():void {
			tiles = new Vector.<BitmapData>(TILES_IN_SET);
			for (var i:int = 0; i < TILES_IN_SET; i++) {
				tiles[i] = defaultTileData;
			}
			tileNames = new Vector.<String>(TILES_IN_SET);
			entry = null;
		}
		
		// Create brand-new tile images and copy the default image onto them, so we can start displaying them.
		// Note the difference between this and filling the tileset with references to the default image!
		// Later, when the real data is loaded, we'll copy it onto these and the display will update itself.
		private function createTilesToDrawOnLater():void {
			var sourceRect:Rectangle = new Rectangle(0, 0, TILE_WIDTH, TILE_HEIGHT);
			var zerozero:Point = new Point(0, 0);
			tiles = new Vector.<BitmapData>(TILES_IN_SET);
			for (var i:int = 0; i < TILES_IN_SET; i++) {
				tiles[i] = new BitmapData(TILE_WIDTH, TILE_HEIGHT);
				tiles[i].copyPixels(defaultTileData, sourceRect, zerozero);
			}
		}
		
		public function createDefaultTileNames():void {
			tileNames = new Vector.<String>(TILES_IN_SET);
			for (var i:int = 0; i < tiles.length; i++) {
				tileNames[i] = String.fromCharCode("A".charCodeAt(0) + i);
				//tileNames[i] = "tile" + String(i + 1);
			}
		}
		
		public function renderAsXml(id:String):XML {
			var tilesetXml:XML = <tileset/>;
			tilesetXml.@file = entry.filename;
			tilesetXml.@id = id;
			for (var i:int = 0; i < tileNames.length; i++) {
				var nameXml:XML = <name/>
				nameXml.appendChild(tileNames[i]);
				tilesetXml.appendChild(nameXml);
			}
			return tilesetXml;
		}

		public function disposeResource():void {
			for (var i:int = 0; i < TILES_IN_SET; i++) {
				if (tiles[i] !== defaultTileData) {
					tiles[i].dispose();
					tiles[i] = defaultTileData;
				}
			}
		}
		
		/************* Tilename stuff, this may all move to an EditTileset class later ***************/

		public function tileName(i:int):String {
			return (tileNames[i] == null ? "" : tileNames[i]);
		}

		public function setTileName(i:int, newName:String):void {
			tileNames[i] = newName;
		}
		
		public function randomTileName():String {
			return tileNames[Math.floor(Math.random() * tiles.length)];
		}	

		// Return the index for a random tile tagged with the given name, or -1 if none match
		public function tileIndexForName(name:String):int {
			if (name != null && name.length > 0) {
				var matches:Vector.<int> = new Vector.<int>();
				var i:int = 0;
				do {
					i = tileNames.indexOf(name, i);
					if (i >= 0) {
						matches.push(i);
						i++;
					}
				} while (i >= 0);
				
				if (matches.length > 0) {
					return matches[ Math.floor(Math.random() * matches.length) ];
				}
			}
			return -1;
		}

	
		
	} // end class Tileset
	
}