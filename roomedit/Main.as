package angel.roomedit {
	import angel.common.*;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class Main extends Sprite {

		public static const DEFAULT_FLOORSIZE_X:int = 10;
		public static const DEFAULT_FLOORSIZE_Y:int = 10;
		
		private var floor:FloorEdit;
		public var palette:FloorTilePalette;
		
		private var editNamesButton:SimplerButton;
		private var finishedEditNamesButton:SimplerButton;

		public function Main():void {
			Alert.init(stage);
			initButtons();

			floor = new FloorEdit(DEFAULT_FLOORSIZE_X, DEFAULT_FLOORSIZE_Y);
			addChild(floor);
			floor.x = 430;
			floor.y = 55;
			floor.addEventListener(Floor.MAP_LOADED_EVENT, mapLoadedListener);
			palette = new FloorTilePalette(floor.tileset);
			palette.x = 5;
			palette.y = 30;
			addChild(palette);
			floor.attachPalette(palette);
		}
		
		private function initButtons():void {
			var button:SimplerButton;
			var left:int = 10;
			
			button = new SimplerButton("Load room", clickedLoadRoom);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 10;
			
			button = new SimplerButton("Load tileset", clickedLoadTileset);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 10;
			
			button = new SimplerButton("Save room", clickedSaveRoom);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 10;
			
			button = new SimplerButton("Clear", clickedClear);
			button.x = left;
			button.y = 5;
			button.width = 80;
			addChild(button);
			left += button.width + 10;
			
			button = new SimplerButton("Redisplay", clickedRedisplay);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 10;
			
			editNamesButton = new SimplerButton("Edit Names", clickedEditNames);
			finishedEditNamesButton = new SimplerButton("Done Editing", clickedEditNames, 0xff0000);
			editNamesButton.x = finishedEditNamesButton.x = left;
			editNamesButton.y = finishedEditNamesButton.y = 5;
			editNamesButton.width = finishedEditNamesButton.width = 100;
			addChild(editNamesButton);
			addChild(finishedEditNamesButton);
			finishedEditNamesButton.visible = false;
			left += editNamesButton.width + 10;
			
			button = new SimplerButton("Size", clickedSize);
			button.x = left;
			button.y = 5;
			button.width = 50;
			addChild(button);
			left += button.width + 10;
			
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
			left += button.width + 10;
		}
		
		private function clickedLoadRoom(event:Event):void {
			floor.launchLoadRoomDialog();
		}
		
		private function clickedLoadTileset(event:Event):void {
			var tileset:Tileset = new Tileset();
			tileset.getFilenameAndLoad(changeTilesetCallback);
		}

		private function changeTilesetCallback(newTileset:Tileset):void {
			floor.changeTileset(newTileset);
			palette.changeTileset(floor.tileset);
		}

		private function clickedSaveRoom(event:Event):void {
			floor.saveRoomAsXmlFile();			
		}
		
		private function clickedClear(event:Event):void {
			floor.clear();
		}

		private function clickedEditNames(event:Event):void {
			var edit:Boolean = editNamesButton.visible;
			floor.visible = !edit;
			palette.setEditMode(edit);
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
			palette.changeTileset(floor.tileset);
		}
		
	} // end class Main
	
}