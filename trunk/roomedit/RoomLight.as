package angel.roomedit {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.CatalogEntry;
	import angel.common.Floor;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Prop;
	import angel.common.RoomContentResource;
	import angel.common.Util;
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
		public var spotLayer:Sprite;
		public var spots:Object = new Object(); // associative array mapping from spotId to location
		public var currentFilename:String;
		public var scriptXml:XML;
		private var catalog:CatalogEdit;
		private var contentsLayer:Sprite;
		private var propGrid:Vector.<Vector.<ContentItem>>;
		private var xy:Point = new Point();
		
		
		private static const DEFAULT_SCRIPT:XML = 
<script>
	<comment>
		*** Room script goes here ***
	</comment>
</script>;
		
		public function RoomLight(floor:FloorEdit, catalog:CatalogEdit) {
			this.floor = floor;
			this.catalog = catalog;
			addChild(floor);
			resize(floor.size.x, floor.size.y);
			floor.addEventListener(FloorEdit.RESIZE_EVENT, floorResized);
			
			spotLayer = new Sprite();
			spotLayer.mouseEnabled = false;
			addChild(spotLayer);
			
			contentsLayer = new Sprite();
			contentsLayer.mouseEnabled = false;
			contentsLayer.mouseChildren = false;
			addChild(contentsLayer);
			
		}
		
		public function toggleVisibility():void {
			contentsLayer.alpha = 1.5 - contentsLayer.alpha;
		}

		public function snapToCenter(tileLoc:Point):void {
			var whereToMove:Point = PositionOfRoomToCenterTile(tileLoc);
			this.x = whereToMove.x;
			this.y = whereToMove.y;
		}
	
		private function PositionOfRoomToCenterTile(tileLoc: Point): Point {
			var desiredTileCenter:Point = Floor.centerOf(tileLoc);
			return new Point(stage.stageWidth / 2 - desiredTileCenter.x - Floor.FLOOR_TILE_X / 2, 
							 stage.stageHeight / 2 - desiredTileCenter.y - Floor.FLOOR_TILE_Y / 2 );
		}

		// Add something at the given location.  If there's already something there, this replaces previous content.
		// type is CatalogEntry type for saving (all content items are turned into props for room editor)
		public function addContentItem(prop:Prop, type:Class, id:String, location:Point, attributes:Object = null):void {
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
		
		private static const contentItemXmlAttributes:Vector.<String> = Vector.<String>(
				["explore", "exploreParam", "combat", "combatParam", "script", "faction", "down"]);
		public function addContentItemByName(type:Class, id:String, location:Point, xml:XML):void {
			trace("adding", id);
			
			var attributes:Object = null;
			for each (var attributeName:String in contentItemXmlAttributes) {
				if (String(xml.@[attributeName]) != "") {
					if (attributes == null) {
						attributes = new Object();
					}
					attributes[attributeName] = String(xml.@[attributeName]);
					trace("  added attribute", attributeName, attributes[attributeName]);
				}
			}
			
			//UNDONE This converts older format of file, delete it eventually
			if (String(xml.@talk) != "") {
				if (attributes == null) {
					attributes = new Object();
				}
				attributes["script"] = String(xml.@talk);
				trace("  converted attribute talk to script", attributes["script"]);				
			}
			
			var down:Boolean = (attributes != null) && (attributes["down"] == "yes");
			var resource:RoomContentResource = catalog.retrieveRoomContentResource(id, type);
			var bitmapData:BitmapData = resource.standardImage(down);
			var prop:Prop = Prop.createFromBitmapData(bitmapData);
			
			addContentItem(prop, type, id, location, attributes);
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
		
		public function propAt(loc:Point):Prop {
			if ((loc != null) && (propGrid[loc.x][loc.y] != null)) {
				return propGrid[loc.x][loc.y].prop;
			}
			return null;
		}

		public function attributesOfItemAt(loc:Point):Object {
			if (propGrid[loc.x][loc.y] != null) {
				return propGrid[loc.x][loc.y].attributes;
			}
			return null;
		}
		
		public function idOfItemAt(loc:Point):String {
			if (propGrid[loc.x][loc.y] != null) {
				return propGrid[loc.x][loc.y].id;
			}
			return null;
		}
		
		public function typeOfItemAt(loc:Point):Class {
			if (propGrid[loc.x][loc.y] != null) {
				return propGrid[loc.x][loc.y].type;
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
		
		private function roomXmlLoaded(event:Event, param:Object, filename:String):void {
			var xml:XML = Util.parseXml(event.target.data, filename);
			if (xml == null) {
				return;
			}
			
			if (xml.floor.length() == 0) {
				Alert.show("Invalid room file.");
				return;
			}
			
			scriptXml = xml.script[0];
			if (scriptXml == null) {
				scriptXml = DEFAULT_SCRIPT;
			}
			
			
			currentFilename = filename;
			floor.loadFromXml(catalog, xml.floor[0]);
			if (xml.contents.length() > 0) {
				initContentsFromXml(xml.floor.@x, xml.floor.@y, xml.contents[0]);
			}
			if (xml.spots.length() > 0) {
				initSpotsFromXml(xml.spots[0]);
			}
			dispatchEvent(new Event(Event.INIT));
		}
	
		// we take new size in parameters rather than retrieving from floor in case floor hasn't
		// finished loading yet when this is called
		public function initContentsFromXml(newx:int, newy:int, contentsXml:XML):void {
			var version:int = int(contentsXml.@version);
			resize(0, 0); // removes all existing props
			resize(newx, newy);
			
			// During development we'll support reading (but not writing) some older formats.
			// Eventually we'll get rid of all but the final version... and then, if we ever
			// release and continue development, support the release version plus future. ;)
			// To save headaches, I'll attempt to make most changes be additions with reasonable
			// defaults, so most changes won't require a new version.
			
			initContentsFromXmlVersion1(contentsXml);
		}

		public function initContentsFromXmlVersion1(contentsXml:XML):void {
			var id:String;
			for each (var propXml:XML in contentsXml.prop) {
				id = propXml.@id;
				addContentItemByName(CatalogEntry.PROP, id, new Point(propXml.@x, propXml.@y), propXml);
			}
			
			for each (var charXml:XML in contentsXml.char) {
				id = charXml.@id;
				addContentItemByName(CatalogEntry.CHARACTER, id, new Point(charXml.@x, charXml.@y), charXml);
			}
		}
		
		// version 1
		public function buildContentsXml():XML {
			var xml:XML = <contents/>;
			xml.@version = "1";
			for (var i:int = 0; i < propGrid.length; i++) {
				for (var j:int = 0; j < propGrid[i].length; j++) {
					if (propGrid[i][j] != null) {
						var propXml:XML = new XML("<" + propGrid[i][j].type.TAG + "/>");
						propXml.@id = propGrid[i][j].id;
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
						xml.appendChild(propXml);
					}
				}
			}
			return xml;
		}

		public function initSpotsFromXml(spotsXml:XML):void {
			spots = new Object();
			for each (var spotXml:XML in spotsXml.spot) {
				var id:String = spotXml.@id;
				if (spots[id] != null) {
					Alert.show("Error! Duplicate spot id " + id + " in " + currentFilename);
				}
				spots[id] = new Point(spotXml.@x, spotXml.@y);
			}
		}
		
		public function buildSpotsXml():XML {
			var xml:XML = <spots/>;
			for (var id:String in spots) {
				var location:Point = spots[id];
				var spotXml:XML = <spot/>;
				spotXml.@id = id;
				spotXml.@x = location.x;
				spotXml.@y = location.y;
				xml.appendChild(spotXml);
			}
			return xml;
		}
		
		public function saveRoomAsXmlFile():void {
			var roomXml:XML = new XML(<room/>);
			roomXml.appendChild( scriptXml );
			roomXml.appendChild( buildSpotsXml() );
			roomXml.appendChild( buildContentsXml() );
			roomXml.appendChild( floor.buildFloorXml() );
			Util.saveXmlToFile(roomXml, currentFilename == null ? "room.xml" : currentFilename);
		}

		
	} // end class RoomLight
		
}
import angel.common.Prop;

class ContentItem {
	public var prop:Prop; // All content items are turned into props in room editor
	public var type:Class;
	public var id:String;
	public var attributes:Object; // associative array mapping attribute name to value
	public function ContentItem(prop:Prop, type:Class, id:String, attributes:Object = null) {
		this.prop = prop;
		this.type = type;
		this.id = id;
		this.attributes = (attributes == null ? new Object() : attributes);
	}
}