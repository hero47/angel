package angel.roomedit {
	import angel.common.*;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	public class FloorEdit extends Floor {

		private var palette:FloorTilePalette;
		private var notBlank:Boolean = false;
		private var dragging:Boolean = false;
		
		public function FloorEdit(sizeX:int, sizeY:int) {
			super();
			myTileset = new Tileset();
			resize(sizeX, sizeY);
			addEventListener(MouseEvent.CLICK, clickListener);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			addEventListener(MAP_LOADED_EVENT, mapLoadedListener);
		}

		public function attachPalette(palette:FloorTilePalette):void {
			this.palette = palette;
		}
		
		public function clear():void {
			notBlank = false;
			for (var i:int = 0; i < xy.x; i++) {
				for (var j:int = 0; j < xy.y; j++) {
					floorGrid[i][j].tileName = "";
					floorGrid[i][j].bitmapData = myTileset.tileDataNamed("");
				}
			}
			setTileImagesFromNames();
		}

		private function mapLoadedListener(event:Event):void {
			notBlank = true;
		}
		
		public function get tileset():Tileset {
			return myTileset;
		}
						
		public function launchLoadRoomDialog():void {
			new FileChooser(loadFloorFromXmlFile);
		}
		
		// Puts up dialog for user to select save location, then writes data to the file.
		public function launchChangeSizeDialog():void {
			KludgeDialogBox.init(stage);
			var options:Object = new Object();
			options.buttons = ["OK", "Cancel"];
			options.inputs = ["X:", "Y:"];
			options.callback = userEnteredSize;
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
			
			if (notBlank && ((newSize.x < xy.x) || (newSize.y < xy.y))) {
				var alertOptions:Object = new Object();
				alertOptions.buttons = ["OK", "Cancel"];
				alertOptions.callback = confirmChangeSizeCallback;
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
		
		override protected function resize(newX:int, newY:int):void {
			super.resize(newX, newY);
			graphics.clear();
			// Draw a background to recognize mouse movements so Wm doesn't leap off a tall building
			// Or maybe not.
			//graphics.beginFill(0xffffff, 1);
			//graphics.drawRect( -(newY + 1) * FLOOR_TILE_X, -2 * FLOOR_TILE_Y,
			//		(newY +newY + 4) * FLOOR_TILE_X,  (newX + newY + 4) * FLOOR_TILE_Y);
		}
		
		private function clickListener(event:MouseEvent):void {
			if (dragging) {
				return;
			}
			if (event.target is FloorTile) {
				changeTile(event.target as FloorTile);
			}
		}
		
		private function continuePaintDrag(event:MouseEvent):void {
			if (event.target is FloorTile) {
				changeTile(event.target as FloorTile);
			}
		}
		
		private function changeTile(floorTile:FloorTile):void {
			var newName:String = palette.selectedTileName;
			floorTile.tileName = newName;
			floorTile.bitmapData = myTileset.tileDataNamed(newName);
			notBlank = (newName != "");
		}
		
		private function mouseDownListener(event:MouseEvent):void {
			if (event.shiftKey) {
				addEventListener(MouseEvent.MOUSE_UP, endDrag);
				startDrag();
				dragging = true;
			} else {
				if (event.target is FloorTile) {
					addEventListener(MouseEvent.MOUSE_MOVE, continuePaintDrag);
					addEventListener(MouseEvent.MOUSE_UP, endPaintDrag);
				}
				dragging = false;
			}
		}

		private function endDrag(event:MouseEvent):void {
			removeEventListener(MouseEvent.MOUSE_UP, endDrag);
			stopDrag();
		}
		
		private function endPaintDrag(event:MouseEvent):void {
			removeEventListener(MouseEvent.MOUSE_MOVE, continuePaintDrag);
			removeEventListener(MouseEvent.MOUSE_UP, endPaintDrag);
		}
		
		public function saveRoomAsXmlFile():void {
			var roomXml:XML = new XML(<room/>);
			roomXml.@x = xy.x;
			roomXml.@y = xy.y;
			roomXml.appendChild( myTileset.xml );
			for (var i:int = 0; i < xy.y; i++) {
				roomXml.appendChild( createRowXml(i) );
			}
			saveXmlToFile(roomXml);
		}

		private function createRowXml(row:int):XML {
			var xml:XML = <floor/>;
			xml.@row = row;
			for (var i:int = 0; i < xy.x; i++) {
				var nameXml:XML = <name/>
				if (floorGrid[i][row].tileName != null) {
					nameXml.appendChild(floorGrid[i][row].tileName);
				}
				xml.appendChild(nameXml);
			}
			return xml;
		}
		
		// UNDONE: This really belongs in a util class somewhere
		public static function saveXmlToFile(xml:XML):void {
			// convert xml to binary data
			var ba:ByteArray = new ByteArray( );
			ba.writeUTFBytes( xml );
 
			// save to disk
			var fr:FileReference = new FileReference( );
			fr.save( ba, 'room.xml' );
		}


	} //end class FloorEdit
	
}
