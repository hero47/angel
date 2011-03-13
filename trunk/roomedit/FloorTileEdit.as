package angel.roomedit {
	import angel.common.Catalog;
	import angel.common.FloorTile;
	import angel.common.Tileset;
	import flash.display.BitmapData;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// FloorTile plus additional data needed only in editor
	public class FloorTileEdit extends FloorTile {
		
		public var tileName:String;
		public var tileset:Tileset;
		public var tilesetId:String;
		public var indexInTileset:int;
		
		private static const emptyTileset:Tileset = new Tileset();
		
		public function FloorTileEdit(roomX:int = -1, roomY:int = -1) {
			super(Tileset.getDefaultTileData(), roomX, roomY);
			tileset = emptyTileset;
			tilesetId = "";
			tileName = "";
			indexInTileset = 0;
		}

		public function setTile(catalog:Catalog, tilesetId:String, index:int):void {
			var tileset:Tileset = (tilesetId == "" ? emptyTileset : catalog.retrieveTileset(tilesetId));
			var tileName:String = tileset.tileName(index);
			this.tilesetId = tilesetId;
			this.tileset = tileset;
			this.tileName = tileName;
			indexInTileset = index;
			bitmapData = tileset.tileBitmapData(indexInTileset);
		}
		
		// Randomize the tile image among those with the same name in this tileset
		public function rechooseImage(catalog:Catalog):void {
			indexInTileset = tileset.tileIndexForName(tileName);
			bitmapData = tileset.tileBitmapData(indexInTileset);			
		}
		
	}

}