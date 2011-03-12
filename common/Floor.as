package angel.common {
	import angel.common.*;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	// (0,0) of floor is the top corner of tile (0,0)'s bounding box, which is at top center almost
	public class Floor extends Sprite {
		public static const MAP_LOADED_EVENT:String = "mapLoaded";
		
		public static const FLOOR_TILE_X:int = (Tileset.TILE_WIDTH / 2);
		public static const FLOOR_TILE_Y:int = (Tileset.TILE_HEIGHT / 2);
		

		protected var xy:Point = new Point();

		protected var floorGrid:Vector.<Vector.<FloorTile>>;
		protected var myTileset:Tileset;
		protected var myTilesetId:String;
		
		public function Floor() {
		}

		// Pixel coordinates of the tile's bounding box
		public static function tileBoxCornerOf(tileLoc:Point):Point {
			var coord:Point = new Point();
			coord.x = (tileLoc.x - tileLoc.y) * FLOOR_TILE_X;
			coord.y = (tileLoc.x + tileLoc.y) * FLOOR_TILE_Y;
			return coord;
		}

		// Pixel coordinates of the top corner of the tile
		public static function topCornerOf(tileLoc:Point):Point {
			var coord:Point = new Point();
			coord.x = (tileLoc.x - tileLoc.y + 1) * FLOOR_TILE_X;
			coord.y = (tileLoc.x + tileLoc.y) * FLOOR_TILE_Y;
			return coord;
		}

		// Pixel coordinates of the center of the tile
		public static function centerOf(tileLoc:Point):Point {
			var coord:Point = new Point();
			coord.x = (tileLoc.x - tileLoc.y + 1) * FLOOR_TILE_X;
			coord.y = (tileLoc.x + tileLoc.y + 1) * FLOOR_TILE_Y;
			return coord;
		}

		public function get size():Point {
			return xy;
		}
		
		//UNDONE: this will be replaced with addTileset
		public function changeTileset(catalog:Catalog, newTilesetId:String):void {
			myTilesetId = newTilesetId;
			myTileset = catalog.retrieveTileset(myTilesetId);
			setTileImagesFromNames();
		}

		// Re-pick images based on tile name.  If no tiles share names, then this will not change the images.
		public function setTileImagesFromNames():void {
			for (var i:int = 0; i < xy.x; i++) {
				for (var j:int = 0; j < xy.y; j++) {
					var floorTile:FloorTile = floorGrid[i][j];
					floorTile.bitmapData = myTileset.tileDataNamed(floorTile.tileName);
				}
			}			
		}
		
		protected function resize(newX:int, newY:int):void {
			var x:int;
			var y:int;
			
			if (floorGrid == null) {
				floorGrid = new Vector.<Vector.<FloorTile>>;
				xy.x = xy.y = 0;
			}
			
			if (floorGrid.length < newX) {
				floorGrid.length = newX;
			}
			for (x = 0; x < floorGrid.length; x++) {
				if (x < xy.x) { // column x has existing tiles
					if (x >= newX) { // column x is outside new bounds, remove those tiles
						removeTilesInRange(x, 0, xy.y);
					} else { // column x is inside new & old bounds, shorten or lengthen as needed
						if (newY < xy.y) { // column needs to be shortened
							removeTilesInRange(x, newY, xy.y);
						}
						floorGrid[x].length = newY;
					}
				} else { // need to add column x
					floorGrid[x] = new Vector.<FloorTile>(newY);
				}
			}
			if (floorGrid.length > newX) {
				floorGrid.length = newX;
			}			
			
			xy.x = newX;
			xy.y = newY;
			createTilesAsNeeded();
		}
		
		private function removeTilesInRange(x:int, yStart:int, yUpTo:int):void {
			for (var i:int = yStart; i < yUpTo; i++) {
				removeChild(floorGrid[x][i]);
			}
		}
		
		private function createTilesAsNeeded():void {
			for (var i:int = 0; i < xy.x; i++) {
				for (var j:int = 0; j < xy.y; j++) {
					if (floorGrid[i][j] == null) {
						var tile:FloorTile = new FloorTile(myTileset.tileDataNamed(""), "", i, j);
						floorGrid[i][j] = tile;
						tile.x = (i - j) * FLOOR_TILE_X;
						tile.y = (i + j) * FLOOR_TILE_Y;
						addChild(tile);
					}
				}
			}			
		}

		private function initFloorRowFromXml(floorXml:XML):void {
			var rowNum:int = floorXml.@row;
			var i:int = 0;
			var names:XMLList = floorXml.name;
			for each (var name:String in names) {
				floorGrid[i++][rowNum].tileName = name;
			}
			
		}
		
		public function loadFromXml(catalog:Catalog, floorXml:XML):void {
			myTilesetId = floorXml.tileset[0];
			myTileset = catalog.retrieveTileset(myTilesetId);
			
			resize(floorXml.@x, floorXml.@y);

			var floorRows:XMLList = floorXml.floorTiles;
			for each (var floorRowXml:XML in floorRows) {
				initFloorRowFromXml(floorRowXml)
			}
			setTileImagesFromNames();

			dispatchEvent(new Event(MAP_LOADED_EVENT));
		}
		
	} //end class Floor
	
}
