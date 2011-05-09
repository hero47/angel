package angel.roomedit {
	import angel.common.*;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	public class FloorEdit extends Floor {
		public static const RESIZE_EVENT:String = "floorResized";

		private var catalog:CatalogEdit;
		private var palette:IRoomEditorPalette;
		public var paintWhileDragging:Boolean;
		private var hasBeenEdited:Boolean = false;
		private var dragging:Boolean = false;
		private var tileWithFilter:FloorTile;
		
		public function FloorEdit(catalog:CatalogEdit, sizeX:int, sizeY:int) {
			super();
			this.catalog = catalog;
			resize(sizeX, sizeY);
			addEventListener(MouseEvent.CLICK, clickListener);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			addEventListener(MouseEvent.MOUSE_MOVE, updateTileHilight);
			addEventListener(Event.INIT, mapLoadedListener);
		}

		public function attachPalette(palette:IRoomEditorPalette):void {
			this.palette = palette;
			paintWhileDragging = palette.paintWhileDragging();
		}
		
		public function clear():void {
			hasBeenEdited = false;
			for (var i:int = 0; i < xy.x; i++) {
				for (var j:int = 0; j < xy.y; j++) {
					var tile:FloorTileEdit = (floorGrid[i][j] as FloorTileEdit);
					tile.setTile(catalog, "", 0);
				}
			}
		}
		
		public function fillEmptyTilesWithCurrentSelection():void {
			hasBeenEdited = true;
			for (var i:int = 0; i < xy.x; i++) {
				for (var j:int = 0; j < xy.y; j++) {
					var tile:FloorTileEdit = (floorGrid[i][j] as FloorTileEdit);
					if (tile.tileName == "") {
						palette.applyToTile(tile);
					}
				}
			}
		}
		
		public function getMostCommonTilesetId():String {
			var tilesetIds:Object = new Object(); // associative array mapping id to tilecount
			for (var i:int = 0; i < xy.x; i++) {
				for (var j:int = 0; j < xy.y; j++) {
					var tile:FloorTileEdit = (floorGrid[i][j] as FloorTileEdit);
					if (tile.tilesetId != "") {
						if (tilesetIds[tile.tilesetId] == undefined) {
							tilesetIds[tile.tilesetId] = 1;
						} else {
							tilesetIds[tile.tilesetId]++;
						}
					}
				}
			}
			var most:int = 0;
			var mostId:String = "";
			for (var id:String in tilesetIds) {
				if (tilesetIds[id] > most) {
					most = tilesetIds[id];
					mostId = id;
				}
			}
			return mostId;
		}

		private function mapLoadedListener(event:Event):void {
			hasBeenEdited = true;
		}

		// Re-pick images based on tile name.  If no tiles share names, then this will not change the images.
		public function setTileImagesFromNames():void {
			for (var i:int = 0; i < xy.x; i++) {
				for (var j:int = 0; j < xy.y; j++) {
					var tile:FloorTileEdit = (floorGrid[i][j] as FloorTileEdit);
					tile.rechooseImage(catalog);
				}
			}			
		}
		
		// Puts up dialog for user to select save location, then writes data to the file.
		public function launchChangeSizeDialog():void {
			KludgeDialogBox.init(stage);
			var options:Object = { buttons:["OK", "Cancel"], inputs:["X:", "Y:"], defaultValues:[xy.x, xy.y],
					callback:userEnteredSize };
			KludgeDialogBox.show("New size for map:", options);
		}


		private var newSize:Point; // for callback on size change		
		private function userEnteredSize(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			newSize = new Point(Math.floor(values[0]), Math.floor(values[1]));
			if ((newSize.x <= 0) || (newSize.y <= 0)) {
				Alert.show("Invalid size");
				return;
			}
			
			if (hasBeenEdited && ((newSize.x < xy.x) || (newSize.y < xy.y))) {
				var alertOptions:Object = { buttons:["OK", "Cancel"], callback:confirmChangeSizeCallback };
				Alert.show("WARNING! This size change will delete tiles. Proceed?", alertOptions);
			} else {
				resize(newSize.x, newSize.y);
			}
		}
		
		private function confirmChangeSizeCallback(choice:String):void {
			if (choice == "OK") {
				resize(newSize.x, newSize.y);
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
			dispatchEvent(new Event(RESIZE_EVENT));
			
			// Draw a background to recognize mouse movements so Wm doesn't leap off a tall building
			// Or maybe not.
			//graphics.clear();
			//graphics.beginFill(0xffffff, 1);
			//graphics.drawRect( -(newY + 1) * FLOOR_TILE_X, -2 * FLOOR_TILE_Y,
			//		(newY +newY + 4) * FLOOR_TILE_X,  (newX + newY + 4) * FLOOR_TILE_Y);
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
						var tile:FloorTileEdit = new FloorTileEdit(i, j);
						addTileAt(tile, i, j);
					}
				}
			}			
		}
		
		override protected function createFloorGrid(sizeX:int, sizeY:int):void {
			resize(sizeX, sizeY);
		}
		
		override protected function setTileFromXml(catalog:Catalog, x:int, y:int, tileXml:XML):void {
			var tile:FloorTileEdit = (floorGrid[x][y] as FloorTileEdit);
			var tilesetId:String = tileXml.@set;
			var index:int = tileXml.@i;
			tile.setTile(catalog, tilesetId, index);
		}
		
		private function clickListener(event:MouseEvent):void {
			if (dragging) {
				return;
			}
			if (event.target is FloorTileEdit) {
				changeTile(event.target as FloorTileEdit, event.ctrlKey);
			}
		}
		
		private function continuePaintDrag(event:MouseEvent):void {
			if (event.target is FloorTileEdit) {
				changeTile(event.target as FloorTileEdit);
			}
		}
		
		private function changeTile(tile:FloorTileEdit, remove:Boolean=false):void {
			palette.applyToTile(tile, remove);
			hasBeenEdited = true;
		}

		private function updateTileHilight(event:MouseEvent):void {
			if (event.target is FloorTile) {
				var tile:FloorTile = event.target as FloorTile;
				if (tileWithFilter != null) {
					tileWithFilter.filters = [];
				}
				tileWithFilter = tile;
				if (tile != null) {
					tileWithFilter.filters = [ new GlowFilter(0xffffff, 1, 15, 15, 10, 1, true, false) ];
				}
			}
			
		}

		private function mouseDownListener(event:MouseEvent):void {
			if (event.shiftKey) {
				addEventListener(MouseEvent.MOUSE_UP, endDrag);
				(parent as Sprite).startDrag();
				dragging = true;
			} else {
				if (event.target is FloorTile && paintWhileDragging) {
					addEventListener(MouseEvent.MOUSE_MOVE, continuePaintDrag);
					addEventListener(MouseEvent.MOUSE_UP, endPaintDrag);
				}
				dragging = false;
			}
		}

		private function endDrag(event:MouseEvent):void {
			removeEventListener(MouseEvent.MOUSE_UP, endDrag);
			(parent as Sprite).stopDrag();
		}
		
		private function endPaintDrag(event:MouseEvent):void {
			removeEventListener(MouseEvent.MOUSE_MOVE, continuePaintDrag);
			removeEventListener(MouseEvent.MOUSE_UP, endPaintDrag);
		}
		
		public function buildFloorXml():XML {
			var xml:XML = <floor/>;
			xml.@x = xy.x;
			xml.@y = xy.y;
			for (var i:int = 0; i < xy.y; i++) {
				xml.appendChild( buildRowXml(i) );
			}
			return xml;
		}

		private function buildRowXml(row:int):XML {
			var xml:XML = <floorTiles/>;
			xml.@row = row;
			for (var i:int = 0; i < xy.x; i++) {
				var tileXml:XML = <tile/>
				var tile:FloorTileEdit = (floorGrid[i][row] as FloorTileEdit);
				tileXml.@set = tile.tilesetId;
				tileXml.@i = tile.indexInTileset;
				xml.appendChild(tileXml);
			}
			return xml;
		}
		



	} //end class FloorEdit
	
}
