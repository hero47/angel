package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Floor;
	import angel.common.KludgeDialogBox;
	import angel.common.SimplerButton;
	import angel.common.Util;
	import fl.controls.ComboBox;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
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
		private var paletteHolder:Sprite;
		
		private static const TILE_PALETTE_INDEX:int = 0;
		private static const PROP_PALETTE_INDEX:int = 1;
		private static const NPC_PALETTE_INDEX:int = 2;
		private static const tabLabels:Vector.<String> = Vector.<String>(["Tiles", "Props", "NPCs"]);
		private var paletteTabs:Vector.<TextField> = new Vector.<TextField>(3);
		private var palettes:Vector.<Sprite> = new Vector.<Sprite>(3);
		private var visibleOnlyWhenPaletteIsTileset:Vector.<DisplayObject> = new Vector.<DisplayObject>();
		
		public function RoomEditUI(catalog:CatalogEdit) {
			this.catalog = catalog;
			
			floor = new FloorEdit(catalog, DEFAULT_FLOORSIZE_X, DEFAULT_FLOORSIZE_Y);
			floor.addEventListener(Event.INIT, mapLoadedListener);
			
			room = new RoomLight(floor, catalog);
			addChild(room);
			room.x = 430;
			room.y = 55;
			
			// Do these AFTER room so they float on top of it
			initPaletteHolder();
			initButtons();
			
			var tilesPalette:FloorTilePalette = new FloorTilePalette(catalog, "");
			tilesPalette.y = EditorSettings.PALETTE_LABEL_HEIGHT;
			paletteHolder.addChild(tilesPalette);
			palettes[TILE_PALETTE_INDEX] = tilesPalette;
			
			var propPalette:PropPalette = new PropPalette(catalog, room);
			propPalette.y = EditorSettings.PALETTE_LABEL_HEIGHT;
			paletteHolder.addChild(propPalette);
			palettes[PROP_PALETTE_INDEX] = propPalette;
			
			var npcPalette:NpcPalette = new NpcPalette(catalog, room);
			npcPalette.y = EditorSettings.PALETTE_LABEL_HEIGHT;
			paletteHolder.addChild(npcPalette);
			palettes[NPC_PALETTE_INDEX] = npcPalette;
			
			switchPaletteTo(paletteTabs[TILE_PALETTE_INDEX]);		
			
			addEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
		}
		
		private function addedToStageListener(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageListener);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
		}
		
		// For God-only-knows what reason, the version of Keyboard class for Flex compilation is missing all
		// of the letter-key constants.  The version in CS5 has them.  ?????
		public static const KEYBOARD_V:uint = 86;
		private function keyDownListener(event:KeyboardEvent):void {
			switch (event.keyCode) {
				case KEYBOARD_V:
					room.toggleVisibility();
				break;
			}
		}
		
		override public function set visible(value:Boolean):void {
			super.visible = value;
			if (value) {
				stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
			} else {
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
			}
		}
		
		private function initPaletteHolder():void {
			paletteHolder = new Sprite();
			paletteHolder.graphics.beginFill(EditorSettings.PALETTE_BACKCOLOR, 1);
			paletteHolder.graphics.drawRect(0, 0, EditorSettings.PALETTE_XSIZE, EditorSettings.PALETTE_YSIZE + EditorSettings.PALETTE_LABEL_HEIGHT);
			paletteHolder.x = 5;
			paletteHolder.y = 30;
			
			paletteTabs = new Vector.<TextField>();
			var tab:TextField;
			
			for (var i:int = 0; i < 3; i++) {
				tab = Util.textBox(tabLabels[i], EditorSettings.PALETTE_XSIZE / 3);
				tab.x = EditorSettings.PALETTE_XSIZE / 3 * i;
				tab.background = true;
				tab.border = true;
				tab.addEventListener(MouseEvent.CLICK, switchPalette);
				paletteHolder.addChild(tab);
				paletteTabs[i] = tab;
			}
			addChild(paletteHolder);
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
			
			button = new SimplerButton("Change tileset", clickedAddTileset);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			visibleOnlyWhenPaletteIsTileset.push(button);
			
			button = new SimplerButton("Fill", clickedFill);
			button.x = left;
			button.y = 5;
			button.width = 60;
			addChild(button);
			left += button.width + 5;
			visibleOnlyWhenPaletteIsTileset.push(button);
			
			button = new SimplerButton("Shuffle tiles", clickedRedisplay);
			button.x = left;
			button.y = 5;
			button.width = 100;
			addChild(button);
			left += button.width + 5;
			visibleOnlyWhenPaletteIsTileset.push(button);
			
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
					callback:changeTilesetCallback };
			var text:String = "Select tileset:";
			KludgeDialogBox.show(text, options);
		}
		private function changeTilesetCallback(buttonClicked:String, values:Array):void {
			if (buttonClicked != "OK") {
				return;
			}
			var tilesetId:String = tilesetCombo.value;
			tilesetCombo = null;
			(palettes[TILE_PALETTE_INDEX] as FloorTilePalette).changeTileset(tilesetId);
		}
		
		private function clickedClear(event:Event):void {
			floor.clear();
			room.removeAllProps();
		}
		
		private function clickedFill(event:Event):void {
			floor.fillEmptyTilesWithCurrentSelection();
		}

		private function clickedRedisplay(event:Event):void {
			floor.setTileImagesFromNames();
		}
		
		private function clickedZoomIn(event:Event):void {
			room.scaleX += 0.1;
			room.scaleY += 0.1;
		}
		
		private function clickedZoomOut(event:Event):void {
			if (room.scaleX > 0.1) {
				room.scaleX -= 0.1;
				room.scaleY -= 0.1;
			}
		}

		private function clickedSize(event:Event):void {
			floor.launchChangeSizeDialog();
		}
		
		private function mapLoadedListener(event:Event):void {
			(palettes[TILE_PALETTE_INDEX] as FloorTilePalette).changeTileset(floor.getMostCommonTilesetId());
		}

		private function clickedEditCatalog(event:Event):void {
			(parent as Main).editCatalog();
		}

		private function switchPaletteTo(palette:DisplayObject):void {
			for (var i:int = 0; i < paletteTabs.length; i++) {
				if (paletteTabs[i] == palette) {
					paletteTabs[i].backgroundColor = EditorSettings.PALETTE_BACKCOLOR;
					palettes[i].visible = true;
					floor.attachPalette(palettes[i] as IRoomEditorPalette);
					var isTile:Boolean = (palettes[i] is FloorTilePalette);
					for each (var it:DisplayObject in visibleOnlyWhenPaletteIsTileset) {
						it.visible =  isTile;
					}
				} else {
					paletteTabs[i].backgroundColor = 0x888888;
					palettes[i].visible = false;
				}
			}
		}

		private function switchPalette(event:Event):void {
			switchPaletteTo(event.target as DisplayObject);
		}

		
	}

}