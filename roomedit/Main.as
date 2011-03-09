package angel.roomedit {
	import angel.common.*;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class Main extends Sprite {

		public static const DEFAULT_FLOORSIZE_X:int = 10;
		public static const DEFAULT_FLOORSIZE_Y:int = 10;
		
		private var catalog:CatalogEdit;
		private var room:RoomLight;
		private var floor:FloorEdit;
		public var tilesPalette:FloorTilePalette;
		public var propPalette:PropPalette;
		
		private var editNamesButton:SimplerButton;
		private var finishedEditNamesButton:SimplerButton;
		
		private var propButton:SimplerButton;
		private var tilesButton:SimplerButton;

		public function Main():void {
			Alert.init(stage);
			catalog = new CatalogEdit();
			catalog.addEventListener(Catalog.CATALOG_LOADED_EVENT, catalogLoadedListener);
			catalog.loadFromXmlFile("AngelCatalog.xml");
		}
		
		private function catalogLoadedListener(event:Event):void {
			catalog.removeEventListener(Catalog.CATALOG_LOADED_EVENT, catalogLoadedListener);
			
			floor = new FloorEdit(DEFAULT_FLOORSIZE_X, DEFAULT_FLOORSIZE_Y);
			floor.addEventListener(Floor.MAP_LOADED_EVENT, mapLoadedListener);
			
			room = new RoomLight(floor, catalog);
			addChild(room);
			room.x = 430;
			room.y = 55;
			
			tilesPalette = new FloorTilePalette(floor.tileset);
			tilesPalette.x = 5;
			tilesPalette.y = 30;
			addChild(tilesPalette);
			floor.attachPalette(tilesPalette);
			floor.paintWhileDragging = true;
			
			propPalette = new PropPalette(room, catalog);
			propPalette.x = 5;
			propPalette.y = 30;
			addChild(propPalette);
			propPalette.visible = false;
			
			initButtons();
		}
		
		private function initButtons():void {
			var button:SimplerButton;
			var left:int = 10;
			
			button = new SimplerButton("Load room", clickedLoadRoom);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			
			button = new SimplerButton("Load tileset", clickedLoadTileset);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			
			button = new SimplerButton("Save room", clickedSaveRoom);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			
			button = new SimplerButton("Clear", clickedClear);
			button.x = left;
			button.y = 5;
			button.width = 60;
			addChild(button);
			left += button.width + 5;
			
			button = new SimplerButton("Redisplay", clickedRedisplay);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			
			editNamesButton = new SimplerButton("Edit Names", clickedEditNames);
			finishedEditNamesButton = new SimplerButton("Done Editing", clickedEditNames, 0xff0000);
			editNamesButton.x = finishedEditNamesButton.x = left;
			editNamesButton.y = finishedEditNamesButton.y = 5;
			editNamesButton.width = finishedEditNamesButton.width = 100;
			addChild(editNamesButton);
			addChild(finishedEditNamesButton);
			finishedEditNamesButton.visible = false;
			left += editNamesButton.width + 5;
			
			button = new SimplerButton("Size", clickedSize);
			button.x = left;
			button.y = 5;
			button.width = 50;
			addChild(button);
			left += button.width + 5;
			
			button = new SimplerButton("In", clickedZoomIn, 0x000080);
			button.x = left;
			button.y = 5;
			button.width = 30;
			addChild(button);
			left += button.width;			
			button = new SimplerButton("Out", clickedZoomOut, 0x000080);
			button.x = left;
			button.y = 5;
			button.width = 30;
			addChild(button);
			left += button.width + 5;
			
			propButton = new SimplerButton("Prop", clickedProp);
			tilesButton = new SimplerButton("Tiles", clickedProp);
			propButton.x = tilesButton.x = left;
			propButton.y = tilesButton.y = 5;
			propButton.width = tilesButton.width = 50;
			addChild(propButton);
			addChild(tilesButton);
			tilesButton.visible = false;
			left += propButton.width + 5;
		}
		
		private function clickedLoadRoom(event:Event):void {
			room.launchLoadRoomDialog();
		}
		
		private function clickedLoadTileset(event:Event):void {
			var tileset:Tileset = new Tileset();
			tileset.getFilenameAndLoad(changeTilesetCallback);
		}

		private function changeTilesetCallback(newTileset:Tileset):void {
			floor.changeTileset(newTileset);
			tilesPalette.changeTileset(floor.tileset);
		}

		private function clickedSaveRoom(event:Event):void {
			room.saveRoomAsXmlFile();			
		}
		
		private function clickedClear(event:Event):void {
			floor.clear();
		}

		private function clickedEditNames(event:Event):void {
			var edit:Boolean = editNamesButton.visible;
			floor.visible = !edit;
			tilesPalette.setEditMode(edit);
			editNamesButton.visible = !edit;
			finishedEditNamesButton.visible = edit;
			if (!edit) {
				floor.setTileImagesFromNames();
			}
		}

		private function clickedRedisplay(event:Event):void {
			floor.setTileImagesFromNames();
		}
		
		private function clickedZoomIn(event:Event):void {
			floor.scaleX += 0.1;
			floor.scaleY += 0.1;
		}
		
		private function clickedZoomOut(event:Event):void {
			if (floor.scaleX > 0.1) {
				floor.scaleX -= 0.1;
				floor.scaleY -= 0.1;
			}
		}

		private function clickedSize(event:Event):void {
			floor.launchChangeSizeDialog();
		}
		
		private function mapLoadedListener(event:Event):void {
			tilesPalette.changeTileset(floor.tileset);
		}
		
		private function clickedProp(event:Event):void {
			var showProp:Boolean = propButton.visible;
			propButton.visible = !showProp;
			tilesButton.visible = showProp;
			propPalette.visible = showProp;
			tilesPalette.visible = !showProp;
			floor.attachPalette(showProp ? propPalette : tilesPalette);
			floor.paintWhileDragging = !showProp;
		}


		
	} // end class Main
	
}