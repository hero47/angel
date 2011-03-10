package angel.roomedit {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Prop;
	import angel.common.PropImage;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.utils.ByteArray;

	// If this gets enough in common with Room I might refactor to combine them & have an edit RoomMode
	public class RoomLight extends Sprite {

		public var floor:FloorEdit;
		private var catalog:CatalogEdit;
		private var contentsLayer:Sprite;
		private var propGrid:Vector.<Vector.<PropAndName>>;
		private var xy:Point = new Point();
		
		public function RoomLight(floor:FloorEdit, catalog:CatalogEdit) {
			this.floor = floor;
			this.catalog = catalog;
			addChild(floor);
			resize(floor.size.x, floor.size.y);
			floor.addEventListener(FloorEdit.RESIZE_EVENT, floorResized);
			
			contentsLayer = new Sprite();
			contentsLayer.mouseEnabled = false;
			contentsLayer.mouseChildren = false;
			addChild(contentsLayer);
			
		}

		public function addProp(prop:Prop, propName:String, location:Point):void {
			if (propGrid[location.x][location.y] != null) {
				contentsLayer.removeChild(propGrid[location.x][location.y].prop);
			}
			propGrid[location.x][location.y] = new PropAndName(prop, propName);
			contentsLayer.addChild(prop);
			prop.location = location;
		}

		private function floorResized(event:Event):void {
			resize(floor.size.x, floor.size.y);
		}
		
		// This has the same skeleton as Floor.resize; I should probably write some utility functions
		// for 2d vectors
		protected function resize(newX:int, newY:int):void {
			var x:int;
			var y:int;
			
			if (propGrid == null) {
				propGrid = new Vector.<Vector.<PropAndName>>;
				xy.x = xy.y = 0;
			}
			
			if (propGrid.length < newX) {
				propGrid.length = newX;
			}
			for (x = 0; x < propGrid.length; x++) {
				if (x < xy.x) { // column x has existing tiles
					if (x >= newX) { // column x is outside new bounds, remove those tiles
						removePropsInRange(x, 0, xy.y);
					} else { // column x is inside new & old bounds, shorten or lengthen as needed
						if (newY < xy.y) { // column needs to be shortened
							removePropsInRange(x, newY, xy.y);
						}
						propGrid[x].length = newY;
					}
				} else { // need to add column x
					propGrid[x] = new Vector.<PropAndName>(newY);
				}
			}
			if (propGrid.length > newX) {
				propGrid.length = newX;
			}			
			
			xy.x = newX;
			xy.y = newY;
		}
		
		private function removePropsInRange(x:int, yStart:int, yUpTo:int):void {
			for (var i:int = yStart; i < yUpTo; i++) {
				if (propGrid[x][i] != null) {
					contentsLayer.removeChild(propGrid[x][i].prop);
					propGrid[x][i] = null;
				}
			}
		}
		
		public function addPropByName(propName:String, location:Point):void {
			var propImage:PropImage = catalog.retrievePropImage(propName);
			var prop:Prop = Prop.createFromPropImage(propImage);
			addProp(prop, propName, location);
		}
		
		public function occupied(location:Point):Boolean {
			return (propGrid[location.x][location.y] != null);
		}
		
		public function removeProp(location:Point):void {
			if (propGrid[location.x][location.y] != null) {
				contentsLayer.removeChild(propGrid[location.x][location.y].prop);
				propGrid[location.x][location.y] = null;
			}
		}
		
		public function launchLoadRoomDialog():void {
			new FileChooser(loadRoomFromXmlFile);
		}
		
		// Loads data from specified file.
		// NOTE: File must be in the same directory that we're running from!
		public function loadRoomFromXmlFile(filename:String):void {
			LoaderWithErrorCatching.LoadFile(filename, roomXmlLoaded);
		}
		
		private function roomXmlLoaded(event:Event):void {
			var xml:XML = new XML(event.target.data);
			
			if (xml.floor.length() == 0) {
				Alert.show("Invalid room file.");
				return;
			}
			
			floor.loadFromXml(catalog, xml.floor[0]);
			initContentsFromXml(xml.floor.@x, xml.floor.@y, xml.contents[0]);
		}

		// we take new size in parameters rather than retrieving from floor in case floor hasn't
		// finished loading yet when this is called
		public function initContentsFromXml(newx:int, newy:int, xml:XML):void {
			resize(0, 0); // removes all existing props
			resize(newx, newy);
			for each (var propXml:XML in xml.prop) {
				var propName:String = propXml;
				addPropByName(propName, new Point(propXml.@x, propXml.@y));
			}
		}
		
		public function buildContentsXml():XML {
			var xml:XML = <contents/>;
			for (var i:int = 0; i < propGrid.length; i++) {
				for (var j:int = 0; j < propGrid[i].length; j++) {
					if (propGrid[i][j] != null) {
						var propXml:XML = <prop/>
						propXml.@x = i;
						propXml.@y = j;
						propXml.appendChild(propGrid[i][j].propName);
						xml.appendChild(propXml);
					}
				}
			}
			return xml;
		}
		
		public function saveRoomAsXmlFile():void {
			var roomXml:XML = new XML(<room/>);
			roomXml.appendChild( floor.buildFloorXml() );
			roomXml.appendChild( buildContentsXml() );
			CatalogEdit.saveXmlToFile(roomXml, "room.xml"); // should really be in a util class but I won't make one just for that
		}

		
	} // end class RoomLight
		
}
import angel.common.Prop;

class PropAndName {
	public var prop:Prop;
	public var propName:String;
	public function PropAndName(prop:Prop, propName:String) {
		this.prop = prop;
		this.propName = propName;
	}
}