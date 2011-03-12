package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Floor;
	import angel.common.KludgeDialogBox;
	import angel.common.SimplerButton;
	import fl.controls.ComboBox;
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class RoomEditUI extends Sprite {
		public static const DEFAULT_FLOORSIZE_X:int = 10;
		public static const DEFAULT_FLOORSIZE_Y:int = 10;
		
		private var catalog:CatalogEdit;
		private var room:RoomLight;
		private var floor:FloorEdit;
		public var tilesPalette:FloorTilePalette;
		public var propPalette:PropPalette;
		
		private var propButton:SimplerButton;
		private var tilesButton:SimplerButton;
		
		public function RoomEditUI(catalog:CatalogEdit) {
			this.catalog = catalog;
			
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
			
			propButton = new SimplerButton("Prop", clickedProp);
			tilesButton = new SimplerButton("Tiles", clickedProp);
			propButton.x = tilesButton.x = left;
			propButton.y = tilesButton.y = 5;
			propButton.width = tilesButton.width = 50;
			addChild(propButton);
			addChild(tilesButton);
			tilesButton.visible = false;
			left += propButton.width + 5;
			
			button = new SimplerButton("Load room", clickedLoadRoom);
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
			
			button = new SimplerButton("Add tileset", clickedAddTileset);
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
			
			button = new SimplerButton("Edit Catalog", clickedEditCatalog);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
		}
		
		private function clickedLoadRoom(event:Event):void {
			room.launchLoadRoomDialog();
		}

		private function clickedSaveRoom(event:Event):void {
			room.saveRoomAsXmlFile();			
		}

		private var tilesetCombo:ComboBox;
		private function clickedAddTileset(event:Event):void {
			var tilesetChooser:Sprite = catalog.createChooser(CatalogEntry.TILESET);
			tilesetCombo = ComboBox(tilesetChooser.getChildAt(0));
			KludgeDialogBox.init(stage);
			var options:Object = { buttons:["OK", "Cancel"], inputs:[], customControl:tilesetChooser,
					callback:addTilesetCallback };
			var text:String = "Select tileset:";
			KludgeDialogBox.show(text, options);
		}
		private function addTilesetCallback(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			var tilesetId:String = tilesetCombo.value;
			tilesetCombo = null;
			tilesPalette.changeTileset(catalog.retrieveTileset(tilesetId));
			floor.changeTileset(catalog, tilesetId);
		}
		
		private function clickedClear(event:Event):void {
			floor.clear();
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

		private function clickedEditCatalog(event:Event):void {
			(parent as Main).editCatalog();
		}


		
	}

}