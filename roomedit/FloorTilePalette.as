package angel.roomedit {
	import angel.common.*;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	//UNDONE: FloorTile now has .tileName, this class hasn't been revised to use it
	
	public class FloorTilePalette extends Sprite implements IRoomEditorPalette {
		
		private static const LABEL_WIDTH:int = Tileset.TILE_WIDTH;
		private static const LABEL_HEIGHT:int = 18;
		private static const X_GUTTER:int = 1;
		private static const Y_GUTTER:int = 5;
		private static const ITEM_HEIGHT:int = (Tileset.TILE_HEIGHT + LABEL_HEIGHT + Y_GUTTER);
		private static const ITEM_WIDTH:int = Tileset.TILE_WIDTH + X_GUTTER;
		public static const XSIZE:int = Tileset.TILE_WIDTH * 3;
		public static const YSIZE:int = Math.ceil((Tileset.TILES_IN_SET + 1) / 3) * ITEM_HEIGHT;
		public static const BACKCOLOR:uint = 0xffffff;
		public static const SELECT_COLOR:uint = 0x00ffff;
		
		private var catalog:Catalog;
		private var tileset:Tileset;
		private var tilesetId:String;
		private var uniqueTileNames:Vector.<NameAndCount>;
		
		private var selectedTileName:String = "";
		private var selection:Sprite = null;
		private var editingTileNames:Boolean = false;
		
		public function FloorTilePalette(catalog:Catalog, tilesetId:String, editNames:Boolean = false) {
			this.catalog = catalog;
			editingTileNames = editNames;
			graphics.lineStyle(2, 0x000000);
			graphics.beginFill(BACKCOLOR, 1);
			graphics.drawRect(0, 0, XSIZE, YSIZE);
			
			changeTileset(tilesetId);
			addEventListener(MouseEvent.CLICK, clickListener);
		}

		public function applyToTile(tile:FloorTileEdit):void {
			var index:int = tileset.tileIndexForName(selectedTileName);
			tile.setTile(catalog, tilesetId, index);
		}		
		
		public function changeTileset(tilesetId:String):void {
			if (tilesetId != this.tilesetId) {
				this.tilesetId = tilesetId;
				this.tileset = (tilesetId == "" ? new Tileset() : catalog.retrieveTileset(tilesetId));
				buildListOfUniqueTileNames();
			}
			
			removeAllChildren();
			if (editingTileNames) {
				createPaletteItemsForEditMode();
			} else {
				createPaletteItemsForNormalMode();
			}
		}
		
		private function buildListOfUniqueTileNames():void {
			uniqueTileNames = new Vector.<NameAndCount>();
			uniqueTileNames.push(new NameAndCount("", 0));
			for (var i:int = 0; i < Tileset.TILES_IN_SET; i++) {
				var tileName:String = tileset.tileName(i);
				for (var j:int = 0; j < uniqueTileNames.length; j++) {
					if (uniqueTileNames[j].name == tileName) {
						uniqueTileNames[j].count++;
						break;
					} else if (uniqueTileNames[j].name > tileName) {
						uniqueTileNames.splice(j, 0, new NameAndCount(tileName, 1));
						break;
					}
				}
				if (j == uniqueTileNames.length) {
					uniqueTileNames.push(new NameAndCount(tileName, 1));
				}
			}
		}
		
		
		private function createPaletteItemsForNormalMode():void {
			for (var i:int = 0; i < uniqueTileNames.length; i++) {
				var foo:Sprite = createNormalPaletteItem(i);
				addChild(foo);
				foo.x = (i % 3) * ITEM_WIDTH;
				foo.y = Math.floor(i / 3) * ITEM_HEIGHT;
				if (i == 0) {
					moveHilight(foo);
				}
			}
			selectedTileName = "";
		}
		
		private function createPaletteItemsForEditMode():void {
			for (var i:int = 0; i < Tileset.TILES_IN_SET; i++) {
				var foo:Sprite = createEditablePaletteItem(i);
				addChild(foo);
				foo.x = (i % 3) * ITEM_WIDTH;
				foo.y = Math.floor(i / 3) * ITEM_HEIGHT;
			}
			selectedTileName = "";		
		}

		public function setEditMode(editNames:Boolean):void {
			editingTileNames = editNames;
			changeTileset(tilesetId);
		}

		public function setTileNamesFromPalette():void {
			for (var i:int = 0; i < numChildren; i++) {
				var child:DisplayObject = getChildAt(i);
				if (child is SpriteWithIndex) {
					var item:SpriteWithIndex = (child as SpriteWithIndex);
					var tileIndex:int = item.index;
					tileset.setTileName(tileIndex, (item.getChildAt(1) as TextField).text);
				}
			}
			
		}
		
		private function removeAllChildren():void {
			while (numChildren > 0) {
				removeChildAt(0);
			}			
		}
		
		private function clickListener(event:MouseEvent):void {
			if (!editingTileNames && (event.target is SpriteWithIndex)) {
				var foo:SpriteWithIndex = (event.target as SpriteWithIndex);
				selectedTileName = uniqueTileNames[foo.index].name;
				moveHilight(foo);
			}
		}
		
		private function moveHilight(newSelection:Sprite):void {
			if (selection != null) {
				selection.graphics.beginFill(BACKCOLOR, 1);
				selection.graphics.drawRect(0, 0, selection.width, selection.height);
			}
			selection = newSelection;
			if (newSelection != null) {
				selection.graphics.beginFill(SELECT_COLOR, 1);
				selection.graphics.drawRect(0, 0, selection.width, selection.height);
			}
		}
		
		private function createNormalPaletteItem(uniqueTileNameIndex:int):SpriteWithIndex {
			var tileName:String = uniqueTileNames[uniqueTileNameIndex].name;
			var label:String = tileName;
			if (uniqueTileNames[uniqueTileNameIndex].count > 1) {
				label += " (" + uniqueTileNames[uniqueTileNameIndex].count + ")";
			}
			var tileIndex:int = tileset.tileIndexForName(tileName);
			var item:SpriteWithIndex = createPaletteItem(label, tileset.tileBitmapData(tileIndex), false);
			item.index = uniqueTileNameIndex;
			item.mouseChildren = false;
			return item;
		}
		
		private function createEditablePaletteItem(tileIndex:int):SpriteWithIndex {
			var item:SpriteWithIndex = createPaletteItem(tileset.tileName(tileIndex), tileset.tileBitmapData(tileIndex), true);
			item.index = tileIndex;
			return item;
		}
		
		private function createPaletteItem(labelText:String, image:BitmapData, editable:Boolean=false):SpriteWithIndex {
			var foo:SpriteWithIndex = new SpriteWithIndex();
			
			var tile:FloorTile = new FloorTile(image);
			foo.addChild(tile);			
			var label:TextField = createPaletteLabel(labelText, editable);
			label.y = tile.height;
			foo.addChild(label);

			//foo.graphics.beginFill(BACKCOLOR, 1);
			//foo.graphics.drawRect(0, 0, foo.width, foo.height);
			return foo;
		}
		
		private function createPaletteLabel(text:String, editable:Boolean=false, textColor:uint = 0):TextField {
			var myTextField:TextField = new TextField();
			myTextField.textColor = textColor;
			myTextField.selectable = editable;
			myTextField.width = LABEL_WIDTH;
			myTextField.height = LABEL_HEIGHT;
			var myTextFormat:TextFormat = new TextFormat();
			myTextFormat.size = LABEL_HEIGHT - 4;
			myTextFormat.align = TextFormatAlign.CENTER;
			myTextField.defaultTextFormat = myTextFormat;
			myTextField.text = text;
			myTextField.type = (editable ? TextFieldType.INPUT : TextFieldType.DYNAMIC);
			myTextField.border = editable;
			return myTextField;
		}
		
	} // end class FloorTilePalette
		
}

	// Helper classes!
	class NameAndCount {
		public var name:String;
		public var count:int;
		public function NameAndCount(name:String, count:int) {
			this.name = name;
			this.count = count;
		}
	}

	import flash.display.Sprite;
	class SpriteWithIndex extends Sprite {
		public var index:int;
	}