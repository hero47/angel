package angel.common {
	import angel.common.*;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	// (0,0) of floor is the top corner of tile (0,0)'s bounding box, which is at top center almost
	public class Floor extends Sprite {
		public static const FLOOR_TILE_X:int = (Tileset.TILE_WIDTH / 2);
		public static const FLOOR_TILE_Y:int = (Tileset.TILE_HEIGHT / 2);
		
		public static const SEEN:int = 0;
		public static const SEEN_BY_OTHER:int = 1;
		public static const UNSEEN:int = 2;
		private static const TRANSFORMS:Vector.<ColorTransform> = Vector.<ColorTransform>([
			new ColorTransform(),
			new ColorTransform(0.4, 0.4, 0.4, 1),
			new ColorTransform(0.2, 0.2, 0.2, 1)
		]);

		protected var xy:Point = new Point();

		protected var floorGrid:Vector.<Vector.<FloorTile>>;
		
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
		
		public function tileAt(tileLoc:Point):FloorTile {
			return floorGrid[tileLoc.x][tileLoc.y];
		}

		public function get size():Point {
			return xy;
		}
		
		public function get pixelRect():Rectangle {
			var left:Number = tileBoxCornerOf(new Point(0, xy.y - 1)).x;
			var width:Number = tileBoxCornerOf(new Point(xy.x + 1, 0)).x - left;
			var height:Number = tileBoxCornerOf(new Point(xy.x, xy.y)).y;
			return new Rectangle(left, 0, width, height);
		}
		
		public function addTileAt(tile:FloorTile, x:int, y:int):void {
			floorGrid[x][y] = tile;
			tile.x = (x - y) * FLOOR_TILE_X;
			tile.y = (x + y) * FLOOR_TILE_Y;
			addChild(tile);
		
		}
		
		// This version only reads the data needed for game.  FloorEdit overrides with a version that reads
		// additional data used only by the editor.
		protected function setTileFromXml(catalog:Catalog, x:int, y:int, tileXml:XML):void {
			var tilesetId:String = tileXml.@set;
			if (tilesetId == "") {
				floorGrid[x][y].bitmapData = Tileset.getDefaultTileData();
			} else {
				var index:int = tileXml.@i;
				var tileset:Tileset = catalog.retrieveTileset(tilesetId);
				floorGrid[x][y].bitmapData = tileset.tileBitmapData(index);
			}
		}
		
		// This version expects to only be called once; it does not remove or reuse any existing tiles.
		// The version for editor (FloorEdit) overrides it with one that does.
		protected function createFloorGrid(sizeX:int, sizeY:int):void {
			floorGrid = new Vector.<Vector.<FloorTile>>(sizeX);
			xy.x = sizeX;
			xy.y = sizeY;
			for (var x:int = 0; x < sizeX; x++) {
				floorGrid[x] = new Vector.<FloorTile>(sizeY);
				for (var y:int = 0; y < sizeY; y++) {
					var tile:FloorTile = new FloorTile(Tileset.getDefaultTileData(), x, y);
					addTileAt(tile, x, y);
				}
			}
		}
		
		private function initFloorRowFromXml(catalog:Catalog, floorXml:XML):void {
			var rowNum:int = floorXml.@row;
			var i:int = 0;
			var tiles:XMLList = floorXml.tile;
			for each (var tile:XML in tiles) {
				setTileFromXml(catalog, i++, rowNum, tile);
			}
			
		}
		
		public function loadFromXml(catalog:Catalog, floorXml:XML):void {
			createFloorGrid(floorXml.@x, floorXml.@y);
			var floorRows:XMLList = floorXml.floorTiles;
			for each (var floorRowXml:XML in floorRows) {
				initFloorRowFromXml(catalog, floorRowXml)
			}
			//setTileImagesFromNames();

			dispatchEvent(new Event(Event.INIT));
		}
		
		//returns previous value of seenState
		public function hideOrShow(tileX:int, tileY:int, desiredVisibility:int):int {
			//WARNING: checking if the colorTransform equals UNSEEN_COLOR_TRANSFORM always returns false -- even though
			//it's a static constant, it's somehow assigning different values each time!  And checking if redMultiplier
			//equals the redMultiplier of UNSEEN_COLOR_TRANSFORM fails, because the recalculated one is slightly off!
			//I had to give up and store a visibility constant with each tile.
			var oldVisibility:int = floorGrid[tileX][tileY].visibility;
			floorGrid[tileX][tileY].visibility = desiredVisibility;
			floorGrid[tileX][tileY].transform.colorTransform = TRANSFORMS[desiredVisibility];
			return oldVisibility;
		}
		
		public function visibility(tileX:int, tileY:int):int {
			return floorGrid[tileX][tileY].visibility;
		}
		
		public static function colorTransformFor(seenState:int):ColorTransform {
			return TRANSFORMS[seenState];
		}
		
		
	} //end class Floor
	
}
