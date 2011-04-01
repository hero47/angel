package angel.game {
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.Floor;
	import angel.common.FloorTile;
	import angel.common.Prop;
	import angel.common.PropImage;
	import angel.common.Util;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.Timer;

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
		public var mainPlayerCharacter:Entity;
		public var size:Point;
		public var mode:RoomMode;

		public var ui:IRoomUi;
		private var dragging:Boolean = false;
		private var gameIsPaused:Boolean = false;
		
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
		
		
		private var changingModeTo:Class;
		public function changeModeTo(newModeClass:Class):void {
			if (mode != null) {
				mode.cleanup();
			}
			changingModeTo = newModeClass;
			ensureMovementFinishedThenChangeMode();
		}
		
		private function ensureMovementFinishedThenChangeMode(event:TimerEvent = null):void {
			if (event != null) {
				(event.target as Timer).removeEventListener(TimerEvent.TIMER_COMPLETE, ensureMovementFinishedThenChangeMode);
			}
			var someoneIsMoving:Boolean = false;
			forEachEntity(function(entity:Entity):void {
				someoneIsMoving ||= entity.moving;
			} );
			
			if (someoneIsMoving) {
				trace("Someone is moving, delay mode change");
				var timer:Timer = new Timer(1000, 1);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, ensureMovementFinishedThenChangeMode);
				timer.start();
			} else {
				mode = new changingModeTo(this);
			}
		}
		
		public function pause(milliseconds:int, callback:Function = null):void {
			trace("Pausing, callback = ", callback);
			Assert.assertTrue(!gameIsPaused, "Pause when already paused");
			gameIsPaused = true;
			
			var timer:Timer = new Timer(milliseconds, 1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(event:TimerEvent):void {
				trace("Pause timer complete");
				Assert.assertTrue(gameIsPaused, "Something unpaused us before pause timer expired");
				gameIsPaused = false;
				if (callback != null) {
					callback();
				}
			} );
			timer.start();
		}
		
		public function get paused():Boolean {
			return gameIsPaused;
		}
		
		/********** Player UI-related  ****************/
		// CONSIDER: Move this into a class, have the things that now implement IRoomUi subclass it?
		
		// call this when player-controlled part of the turn begins, to allow player to enter move
		public function enableUi(newUi:IRoomUi, player:Entity):void {
			ui = newUi;
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveListener);
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			addEventListener(MouseEvent.CLICK, mouseClickListener);
			//Right-button mouse events are only supported in AIR.  For now, while we're using Flash Projector,
			//we're substituting ctrl-click.
			//addEventListener(MouseEvent.RIGHT_CLICK, rightClickListener);
			
			newUi.enable(player);
		}
		
		public function disableUi():void {
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveListener);
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			removeEventListener(MouseEvent.CLICK, mouseClickListener);
			//removeEventListener(MouseEvent.RIGHT_CLICK, rightClickListener);
			
			removeEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			stopDrag();
			
			if (ui != null) {
				ui.disable();
			}
		}
		
		
		private function keyDownListener(event:KeyboardEvent):void {
			switch (event.keyCode) {
				case Util.KEYBOARD_V:
					toggleVisibility();
				break;
				
				default:
					ui.keyDown(event.keyCode);
				break;
			}
		}
		
		private function mouseMoveListener(event:MouseEvent):void {
			ui.mouseMove(event.target as FloorTile);
		}

		private function mouseDownListener(event:MouseEvent):void {
			if (event.shiftKey) {
				addEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
				startDrag();
				dragging = true;
			} else {
				dragging = false;
			}
		}

		private function mouseUpListener(event:MouseEvent):void {
			removeEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			stopDrag();
		}
		
		private function mouseClickListener(event:MouseEvent):void {
			if (event.ctrlKey) {
				// Temporary since Flash Projector doesn't support right-button events.
				// If/when we switch to AIR this will be replaced with a real right click listener.
				rightClickListener(event);
				return;
			}
			if (!dragging && (event.target is FloorTile)) {
				ui.mouseClick(event.target as FloorTile);
			}
		}
		
		private function rightClickListener(event:MouseEvent):void {
			if (!(event.target is FloorTile)) {
				return;
			}
			var tile:FloorTile = event.target as FloorTile;
			var slices:Vector.<PieSlice> = ui.pieMenuForTile(tile);
			launchPieMenu(tile, slices);
		}
		
		// Separating this out into a public function because Wm has specced bringing up pie menu on something
		// other than right-click in certain cases.  This is probably bad ui, but we'll see how it works out.
		public function launchPieMenu(tile:FloorTile, slices:Vector.<PieSlice>):void {			
			if (slices != null && slices.length > 0) {
				var tileCenterOnStage:Point = floor.localToGlobal(Floor.centerOf(tile.location));
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
				var pie:PieMenu = new PieMenu(tileCenterOnStage.x, tileCenterOnStage.y, slices, pieDismissed);
				stage.addChild(pie);
			}
		}
		
		private function pieDismissed():void {
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownListener);
		}

		/********************* end general ui **********************/
		
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
		
		public function forEachEntity(callWithEntity:Function, filter:Function = null):void {
			for (var i:int = 0; i < size.x; i++) {
				for (var j:int = 0; j < size.y; j++) {
					for each (var prop:Prop in cells[i][j].contents) {
						if (prop is Entity) {
							if (filter != null && !filter(prop)) {
								continue;
							}
							callWithEntity(prop);
						}
					}
				}
			}
		}
		
		public function forEachEntityIn(location:Point, callWithEntity:Function, filter:Function = null):void {
			cells[location.x][location.y].forEachEntity(callWithEntity, filter);
		}
		
		public function firstEntityIn(location:Point, filter:Function = null):Entity {
			return cells[location.x][location.y].firstEntity(filter);
		}

		public function addPlayerCharacter(entity:Entity, location:Point): void {
			if (mainPlayerCharacter == null) {
				mainPlayerCharacter = entity;
			}
			addEntity(entity, location);
			entity.isPlayerControlled = true;
		}
		
		// This will generally be called by the entity as it crosses the boundary between one floor tile
		// and another during movement.
		public function changeEntityLocation(entity:Entity, newLocation:Point):void {
			cells[entity.location.x][entity.location.y].remove(entity);
			cells[newLocation.x][newLocation.y].add(entity);
			moveMarkerIfNeeded(entity, newLocation);
			/*
			if (entityWithFilter == entity) {
				entityWithFilter.filters = [];
				entityWithFilter = null;
			}
			*/
		}
		
		public function moveMarkerIfNeeded(entity:Entity, newLocation:Point = null):void {
			if (entity.marker != null) {
				var tileCenter:Point = Floor.centerOf(newLocation == null ? entity.location : newLocation);
				entity.marker.x = tileCenter.x;
				entity.marker.y = tileCenter.y;
			}
		}
		
		public function solid(x:int, y:int):uint {
			if ((x < 0) || (x >= size.x) || (y < 0) || (y >= size.y)) {
				return Prop.OFF_MAP;
			}
			return cells[x][y].solid();
		}
		
		private function enterFrameListener(event:Event):void {
			stage.focus = stage;
			if (!gameIsPaused) {
				dispatchEvent(new Event(UNPAUSED_ENTER_FRAME));
			}
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
			var prop:Entity = Entity.createFromPropImage(propImage, id);
			addEntity(prop, location);
		}
		
		public function addWalkerByName(catalog:Catalog, id:String, location:Point):Walker {
			var entity:Walker = new Walker(catalog.retrieveWalkerImage(id), id);
			addEntity(entity, location);
			return entity;
		}
		
	} // end class Room

}