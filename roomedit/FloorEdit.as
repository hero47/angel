package angel.roomedit {
	import angel.common.*;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	public class FloorEdit extends Floor {
		public static const RESIZE_EVENT:String = "floorResized";

		private var palette:IRoomEditorPalette;
		public var paintWhileDragging:Boolean;
		private var hasBeenEdited:Boolean = false;
		private var dragging:Boolean = false;
		
		public function FloorEdit(sizeX:int, sizeY:int) {
			super();
			myTileset = new Tileset();
			resize(sizeX, sizeY);
			addEventListener(MouseEvent.CLICK, clickListener);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			addEventListener(MAP_LOADED_EVENT, mapLoadedListener);
		}

		public function attachPalette(palette:IRoomEditorPalette):void {
			this.palette = palette;
		}
		
		public function clear():void {
			hasBeenEdited = false;
			for (var i:int = 0; i < xy.x; i++) {
				for (var j:int = 0; j < xy.y; j++) {
					floorGrid[i][j].tileName = "";
					floorGrid[i][j].bitmapData = myTileset.tileDataNamed("");
				}
			}
			setTileImagesFromNames();
		}

		private function mapLoadedListener(event:Event):void {
			hasBeenEdited = true;
		}
		
		public function get tileset():Tileset {
			return myTileset;
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
			
			if (hasBeenEdited && ((newSize.x < xy.x) || (newSize.y < xy.y))) {
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
			dispatchEvent(new Event(RESIZE_EVENT));
			
			// Draw a background to recognize mouse movements so Wm doesn't leap off a tall building
			// Or maybe not.
			//graphics.clear();
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
			palette.applyToTile(floorTile);
			hasBeenEdited = true;
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
			var xml:XML = new XML(<floor/>);
			xml.@x = xy.x;
			xml.@y = xy.y;
			xml.@id = myTilesetId;
			for (var i:int = 0; i < xy.y; i++) {
				xml.appendChild( buildRowXml(i) );
			}
			return xml;
		}

		private function buildRowXml(row:int):XML {
			var xml:XML = <floorTiles/>;
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
		



	} //end class FloorEdit
	
}
