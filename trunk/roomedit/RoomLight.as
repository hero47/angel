package angel.roomedit {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.CatalogEntry;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Prop;
	import angel.common.PropImage;
	import angel.common.WalkerImage;
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
		private var propGrid:Vector.<Vector.<ContentItem>>;
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
		
		public function toggleVisibility():void {
			contentsLayer.alpha = 1.5 - contentsLayer.alpha;
		}

		// Add something at the given location.  If there's already something there, this replaces previous content.
		// type is CatalogEntry type for saving (all content items are turned into props for room editor)
		public function addContentItem(prop:Prop, type:int, id:String, location:Point, attributes:Object = null):void {
			if (propGrid[location.x][location.y] != null) {
				contentsLayer.removeChild(propGrid[location.x][location.y].prop);
			}
			propGrid[location.x][location.y] = new ContentItem(prop, type, id, attributes);
			contentsLayer.addChild(prop);
			prop.location = location;
		}
		
		public function removeAllProps():void {
			var loc:Point = new Point();
			for (loc.x = 0; loc.x < xy.x; ++loc.x) {
				for (loc.y = 0; loc.y < xy.y; ++loc.y) {
					removeItemAt(loc);
				}
			}
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
				propGrid = new Vector.<Vector.<ContentItem>>;
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
					propGrid[x] = new Vector.<ContentItem>(newY);
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
		
		public function addPropByName(id:String, location:Point):void {
			var propImage:PropImage = catalog.retrievePropImage(id);
			var prop:Prop = Prop.createFromPropImage(propImage);
			addContentItem(prop, CatalogEntry.PROP, id, location);
		}
		
		public function addWalkerByName(id:String, location:Point, exploreBehavior:String, combatBehavior:String, talk:String):void {
			var walkerImage:WalkerImage = catalog.retrieveWalkerImage(id);
			var prop:Prop = Prop.createFromBitmapData(walkerImage.bitsFacing(1));
			var attributes:Object = null;
			if (exploreBehavior != "" || combatBehavior != "" || talk != "") {
				attributes = new Object();
				attributes["explore"] = exploreBehavior;
				attributes["combat"] = combatBehavior;
				attributes["talk"] = talk;
			}
			addContentItem(prop, CatalogEntry.WALKER, id, location, attributes);
		}
		
		public function occupied(location:Point):Boolean {
			return (propGrid[location.x][location.y] != null);
		}
		
		public function removeItemAt(location:Point):void {
			if (propGrid[location.x][location.y] != null) {
				contentsLayer.removeChild(propGrid[location.x][location.y].prop);
				propGrid[location.x][location.y] = null;
			}
		}
		
		// returns first location containing a content item with the given id, or null if none match
		public function find(id:String):Point {
			for (var i:int = 0; i < propGrid.length; i++) {
				for (var j:int = 0; j < propGrid[i].length; j++) {
					if (propGrid[i][j] != null && propGrid[i][j].id == id) {
						return new Point(i, j);
					}
				}
			}
			return null;
		}

		public function attributesOfItemAt(loc:Point):Object {
			if (propGrid[loc.x][loc.y] != null) {
				return propGrid[loc.x][loc.y].attributes;
			}
			return null;
		}

		public function setAttributesOfItemAt(loc:Point, attributes:Object):void {
			Assert.assertTrue(propGrid[loc.x][loc.y] != null, "Setting attributes for empty location");
			propGrid[loc.x][loc.y].attributes = attributes;
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
			dispatchEvent(new Event(Event.INIT));
		}

		// we take new size in parameters rather than retrieving from floor in case floor hasn't
		// finished loading yet when this is called
		public function initContentsFromXml(newx:int, newy:int, xml:XML):void {
			resize(0, 0); // removes all existing props
			resize(newx, newy);
			var id:String;
			for each (var propXml:XML in xml.prop) {
				id = propXml;
				addPropByName(id, new Point(propXml.@x, propXml.@y));
			}
			for each (var walkerXml:XML in xml.walker) {
				id = walkerXml;
				addWalkerByName(id, new Point(walkerXml.@x, walkerXml.@y), walkerXml.@explore, walkerXml.@combat, walkerXml.@talk);
			}
		}
		
		public function buildContentsXml():XML {
			var xml:XML = <contents/>;
			for (var i:int = 0; i < propGrid.length; i++) {
				for (var j:int = 0; j < propGrid[i].length; j++) {
					if (propGrid[i][j] != null) {
						var propXml:XML = new XML("<" + CatalogEntry.xmlTag[propGrid[i][j].type] + "/>");
						propXml.@x = i;
						propXml.@y = j;
						var attributes:Object = propGrid[i][j].attributes;
						if (attributes != null) {
							for (var att:String in attributes) {
								if (attributes[att] != "") {
									propXml.@[att] = attributes[att];
								}
							}
						}
						propXml.appendChild(propGrid[i][j].id);
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

class ContentItem {
	public var prop:Prop; // All content items are turned into props in room editor
	public var type:int;
	public var id:String;
	public var attributes:Object; // associative array mapping attribute name to value
	public function ContentItem(prop:Prop, type:int, id:String, attributes:Object = null) {
		this.prop = prop;
		this.type = type;
		this.id = id;
		this.attributes = (attributes == null ? new Object() : attributes);
	}
}