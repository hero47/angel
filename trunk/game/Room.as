package angel.game {
	import angel.common.Catalog;
	import angel.common.Floor;
	import angel.common.FloorTile;
	import angel.common.Prop;
	import angel.common.PropImage;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.ui.Keyboard;

	public class Room extends Sprite {
		static public const UNPAUSED_ENTER_FRAME:String = "unpausedEnterFrame"; // only triggers when not paused
		
		static private const SCROLL_SPEED:Number = 3;
		
		public var floor:Floor;
		public var decorationsLayer:Sprite;	// for things painted over the floor, such as movement dots
		// contentsLayer is set transparent to mouse when we're looking for tile clicks, for movement.
		// Later, when we have modes where they'll be picking targets, we can set its mouseChildren to true
		// and detect clicks on entities.

		private var contentsLayer:Sprite;
		public var cells:Vector.<Vector.<Cell>>;
		public var playerCharacter:Entity;
		public var size:Point;
		public var mode:RoomMode;
		
		private var tileWithFilter:FloorTile;
		//private var entityWithFilter:Entity; // not yet, but will be needed for future story
		private var scrollingTo:Point = null;
				
		public function Room(floor:Floor) {
			this.floor = floor;
			addChild(floor);
			
			decorationsLayer = new Sprite();
			decorationsLayer.mouseEnabled = false;
			addChild(decorationsLayer);
			
			contentsLayer = new Sprite();
			contentsLayer.mouseEnabled = false;
			contentsLayer.mouseChildren = false;
			addChild(contentsLayer);
			
			size = floor.size;
			cells = new Vector.<Vector.<Cell>>(size.x);
			for (var i:int = 0; i < size.x; i++) {
				cells[i] = new Vector.<Cell>(size.y);
				for (var j:int = 0; j < size.y; j++) {
					cells[i][j] = new Cell();
				}
			}
			
			addEventListener(Event.ENTER_FRAME, enterFrameListener);
			//addEventListener(Event.ADDED_TO_STAGE, finishInit);
			
		}
		
		/*
		private function finishInit(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, finishInit);

		}
		*/
		
		public function scrollToCenter(tileLoc:Point, instant:Boolean=false):void {
			var desiredCenter:Point = Floor.centerOf(tileLoc);
			scrollingTo = new Point(stage.stageWidth / 2 - desiredCenter.x - Floor.FLOOR_TILE_X/2, 
									stage.stageHeight / 2 - desiredCenter.y - Floor.FLOOR_TILE_Y / 2 );
			if (instant) {
				this.x = scrollingTo.x;
				this.y = scrollingTo.y;
				scrollingTo = null;
			}
		}
	
		public function moveHilight(tile:FloorTile, color:uint):void {
			if (tileWithFilter != null) {
				tileWithFilter.filters = [];
			}
			/*
			if (entityWithFilter != null) {
				entityWithFilter.filters = [];
				entityWithFilter = null;
			}
			*/
			tileWithFilter = tile;
			if (tileWithFilter != null) {
				var glow:GlowFilter = new GlowFilter(color, 1, 15, 15, 10, 1, true, false);
				tileWithFilter.filters = [ glow ];
				/* 
				// NOTE: when we get to this story, it will want to only light up entities that respond to clicks
				// and that filtering may be done in the RoomMode rather than here
				var cell:Cell = cells[tileWithFilter.location.x][tileWithFilter.location.y];
				if (cell != null) {
					entityWithFilter = cell.firstOccupant();
					if (entityWithFilter != null) {
						entityWithFilter.filters = [ glow ];
					}
				}
				*/
			}
		}
		
		public function toggleVisibility():void {
			contentsLayer.alpha = 1.5 - contentsLayer.alpha;
		}
		
		//CONSIDER: should entity.addToRoom add itself to the contentsLayer, or do we want the ability to
		//be in the room but not yet on stage?
		public function addEntity(entity:Entity, location:Point):void {
			cells[location.x][location.y].add(entity);
			contentsLayer.addChild(entity);
			entity.addToRoom(this, location);
		}
		
		public function forEachEntity(callWithEntity:Function):void {
			for (var i:int = 0; i < size.x; i++) {
				for (var j:int = 0; j < size.y; j++) {
					for each (var prop:Prop in cells[i][j].contents) {
						if (prop is Entity) {
							callWithEntity(prop);
						}
					}
				}
			}
		}

		public function addPlayerCharacter(entity:Entity, location:Point): void {
			if (playerCharacter != null) {
				playerCharacter.isPlayerControlled = false;
			}
			addEntity(entity, location);
			playerCharacter = entity;
			playerCharacter.isPlayerControlled = true;
		}
		
		// This will generally be called by the entity as it crosses the boundary between one floor tile
		// and another during movement.
		public function changeEntityLocation(entity:Entity, newLocation:Point):void {
			if (entity.personalTileHilight != null) {
				//CONSIDER: if mouse is over one of these tiles, do we need to special-case mouse hilight???
				floor.tileAt(entity.location).filters = [];
				floor.tileAt(newLocation).filters = [ entity.personalTileHilight ];
			}
			cells[entity.location.x][entity.location.y].remove(entity);
			cells[newLocation.x][newLocation.y].add(entity);
			/*
			if (entityWithFilter == entity) {
				entityWithFilter.filters = [];
				entityWithFilter = null;
			}
			*/
		}
		
		public function updatePersonalTileHilight(entity:Entity):void {
			if (entity.personalTileHilight == null) {
				//CONSIDER: if mouse is over one of these tiles, do we need to special-case mouse hilight???
				floor.tileAt(entity.location).filters = [];
			} else {
				floor.tileAt(entity.location).filters = [ entity.personalTileHilight ];
			}
		}
		
		public function solid(location:Point):uint {
			if ((location.x < 0) || (location.x >= size.x) || (location.y < 0) || (location.y >= size.y)) {
				return Prop.HARD_SOLID;
			}
			return cells[location.x][location.y].solid();
		}
		
		private function enterFrameListener(event:Event):void {
			stage.focus = stage;
			dispatchEvent(new Event(UNPAUSED_ENTER_FRAME));
			if (scrollingTo != null) {
				var vector:Point = new Point(scrollingTo.x - this.x, scrollingTo.y - this.y);
				if (vector.length <= SCROLL_SPEED) {
					this.x = scrollingTo.x;
					this.y = scrollingTo.y;
					scrollingTo = null;
				} else {
					vector.normalize(SCROLL_SPEED);
					this.x += vector.x;
					this.y += vector.y;
				}
			}
		}
		
		public function changeModeTo(newModeClass:Class):void {
			if (mode != null) {
				mode.cleanup();
			}
			mode = new newModeClass(this);
		}
		
		private static const exploreBrain:Object = { fidget:BrainFidget, wander:BrainWander };
		private static const combatBrain:Object = { wander:CombatBrainWander };
		
		public function fillContentsFromXml(catalog:Catalog, contentsXml:XML):void {
			for each (var propXml:XML in contentsXml.prop) {
				var propName:String = propXml;
				addPropByName(catalog, propName, new Point(propXml.@x, propXml.@y));
			}
			for each (var walkerXml:XML in contentsXml.walker) {
				var walkerName:String = walkerXml;
				var walker:Walker = addWalkerByName(catalog, walkerName, new Point(walkerXml.@x, walkerXml.@y));
				var exploreSetting:String = walkerXml.@explore;
				walker.exploreBrainClass = exploreBrain[exploreSetting];
				var combatSetting:String = walkerXml.@combat;
				walker.combatBrainClass = combatBrain[combatSetting];
			}
			
		}
		
		public function addPropByName(catalog:Catalog, id:String, location:Point):void {
			var propImage:PropImage = catalog.retrievePropImage(id);
			var prop:Entity = Entity.createFromPropImage(propImage);
			addEntity(prop, location);
		}
		
		public function addWalkerByName(catalog:Catalog, id:String, location:Point):Walker {
			var entity:Walker = new Walker(catalog.retrieveWalkerImage(id));
			entity.solid = Prop.SOLID;
			addEntity(entity, location);
			return entity;
		}
		
	} // end class Room

}