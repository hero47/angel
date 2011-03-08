package angel.common {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Loader;
	import flash.events.IOErrorEvent;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileReference;	
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import angel.roomedit.FileChooser;

	public class Tileset {
		private static const TILESET_X_TILES:int = 4;
		private static const TILESET_Y_TILES:int = 5;
		public static const TILES_IN_SET:int = (TILESET_X_TILES * TILESET_Y_TILES);
		private static const TILESET_X:int = 256;
		private static const TILESET_Y:int = 160;
		public static const TILE_WIDTH:int = TILESET_X / TILESET_X_TILES;
		public static const TILE_HEIGHT:int = TILESET_Y / TILESET_Y_TILES;
		
		private static var defaultTileData:BitmapData = null;
		
		private var filename:String;
		
		
		private var callbackWithTilesetWhenComplete:Function;
		private var tiles:Vector.<BitmapData>;
		private var tileNames:Vector.<String>;
		
		public function Tileset() {
			Assert.assertTrue(TILE_WIDTH == TILE_HEIGHT * 2, "Code tagged tile-width-is-twice-height will break!");
			if (defaultTileData == null) {
				defaultTileData = new BitmapData(TILE_WIDTH, TILE_HEIGHT, true, 0); // fully transparent
				
				var blankTileImage:Shape = new Shape();
				
				blankTileImage.graphics.lineStyle(0, 0xffffff);
				blankTileImage.graphics.moveTo(TILE_WIDTH/2, 0);
				blankTileImage.graphics.lineTo(TILE_WIDTH, TILE_HEIGHT / 2);
				blankTileImage.graphics.lineTo(TILE_WIDTH / 2, TILE_HEIGHT);
				blankTileImage.graphics.lineTo(0, TILE_HEIGHT / 2);
				blankTileImage.graphics.lineTo(TILE_WIDTH/2, 0);
				
				blankTileImage.graphics.beginFill(0xffffff, 1);
				blankTileImage.graphics.drawCircle(TILE_WIDTH / 2, TILE_HEIGHT / 2, 2);
				
				defaultTileData.draw(blankTileImage);
			}
			
			createBlankTiles();
		}
		
		private function createBlankTiles():void {
			tiles = new Vector.<BitmapData>(TILES_IN_SET);
			for (var i:int = 0; i < TILES_IN_SET; i++) {
				tiles[i] = defaultTileData;
			}
			tileNames = new Vector.<String>(TILES_IN_SET);
			filename = null;
		}

		private function createDefaultTileNames():void {
			tileNames = new Vector.<String>(TILES_IN_SET);
			for (var i:int = 0; i < tiles.length; i++) {
				tileNames[i] = String.fromCharCode("A".charCodeAt(0) + i);
				//tileNames[i] = "tile" + String(i + 1);
			}
		}

		public function tileData(i:int):BitmapData {
			return tiles[i];
		}
		
		public function tileName(i:int):String {
			return (tileNames[i] == null ? "" : tileNames[i]);
		}

		public function setTileName(i:int, newName:String):void {
			tileNames[i] = newName;
		}
		
		public function randomTileName():String {
			return tileNames[Math.floor(Math.random() * tiles.length)];
		}	

		// Return the BitmapData for a random tile tagged with the given name, or defaultTileData if none match
		public function tileDataNamed(name:String):BitmapData {
			if (name != null && name.length > 0) {
				var matches:Vector.<BitmapData> = new Vector.<BitmapData>();
				var i:int = 0;
				do {
					i = tileNames.indexOf(name, i);
					if (i >= 0) {
						matches.push(tiles[i]);
						i++;
					}
				} while (i >= 0);
				
				if (matches.length > 0) {
					return matches[ Math.floor(Math.random() * matches.length) ];
				}
			}
			return defaultTileData;
		}

        private function nameMatches(element:*, index:int, arr:Array):Boolean {
            return (element.manager == true);
        }

		
		//callback function takes Tileset as parameter
		public function getFilenameAndLoad(callbackWithTilesetWhenComplete:Function):void {
			this.callbackWithTilesetWhenComplete = callbackWithTilesetWhenComplete;
			createDefaultTileNames();
			new FileChooser(tilesetLoadedIntoByteArray, null, true);
		}

		private function tilesetLoadedIntoByteArray(filename:String, bytes:ByteArray):void {
			this.filename = filename;
			LoaderWithErrorCatching.LoadBytes(bytes, tilesetAvailableAsBitmap);
		}
		
		private function tilesetAvailableAsBitmap(event:Event):void {
			var compoundBitmap:Bitmap = event.target.content;
			if ((compoundBitmap.width != TILESET_X) || (compoundBitmap.height != TILESET_Y)) {
				Alert.show("WARNING: Tileset bitmap is not " + TILESET_X + "x" + TILESET_Y + ".  Please fix!");
			}
			tiles = createTilesFromCompoundBitmap(compoundBitmap);
			compoundBitmap.bitmapData.dispose();
			if (tileNames == null) {
				createDefaultTileNames();
			}
			callbackWithTilesetWhenComplete(this);
		}
		
		public function get xml():XML {
			var tilesetXml:XML = <tileset/>;
			tilesetXml.@file = filename;
			for (var i:int = 0; i < tileNames.length; i++) {
				var nameXml:XML = <name/>
				nameXml.appendChild(tileNames[i]);
				tilesetXml.appendChild(nameXml);
			}
			return tilesetXml;
		}

		public function initFromXml(xml:XML, callbackWithTilesetWhenComplete:Function):void {
			this.callbackWithTilesetWhenComplete = callbackWithTilesetWhenComplete;
			createBlankTiles();
			
			var tilesetXmlList:XMLList = xml.tileset;
			if (tilesetXmlList.length() > 1) {
				Alert.show("XML file has multiple tilesets; not supported yet.");
			}
			var tilesetXml:XML = tilesetXmlList[0];
			filename = tilesetXml.@file;
			var names:XMLList = tilesetXml.name;
			var i:int = 0;
			for each (var name:String in names) {
				tileNames[i++] = name;
			}

			LoaderWithErrorCatching.LoadBytesFromFile(filename, tilesetAvailableAsBitmap);
		}

		private function createTilesFromCompoundBitmap(tilesetBitmap:Bitmap):Vector.<BitmapData> {
			var bitmapData:BitmapData = tilesetBitmap.bitmapData;
			
			var theseTiles:Vector.<BitmapData> = new Vector.<BitmapData>(TILES_IN_SET);
			var zerozero:Point = new Point(0, 0);
			var i:int = 0;
			for (var tileY:int = 0; tileY < TILESET_Y_TILES; tileY++) {
				for (var tileX:int = 0; tileX < TILESET_X_TILES; tileX++) {
					var sourceRect:Rectangle = new Rectangle(tileX*TILE_WIDTH, tileY*TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT);
					var tileData:BitmapData = new BitmapData(TILE_WIDTH, TILE_HEIGHT);
					tileData.copyPixels(bitmapData, sourceRect, zerozero);
					theseTiles[i++] = tileData;
				}
			}
			return theseTiles;
		}
		
		public function cleanup():void {
			for (var i:int = 0; i < TILES_IN_SET; i++) {
				if (tiles[i] !== defaultTileData) {
					tiles[i].dispose();
					tiles[i] = defaultTileData;
				}
			}
			tileNames = null;
		}
		
	} // end class Tileset
	
}