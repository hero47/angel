package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.Floor;
	import angel.common.FloorTile;
	import angel.common.Prop;
	import angel.common.Util;
	import angel.game.script.ConversationData;
	import angel.game.script.ConversationInterface;
	import angel.game.script.RoomScripts;
	import angel.game.script.Script;
	import angel.game.test.ConversationNonAutoTest;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;

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
		public var mainPlayerCharacter:ComplexEntity;
		public var size:Point;
		public var mode:RoomMode;
		private var spots:Object = new Object(); // associative array mapping from spotId to location

		public var activeUi:IRoomUi;
		private var disabledUi:IRoomUi;
		private var lastUiPlayer:ComplexEntity;
		private var dragging:Boolean = false;
		
		private var conversationInProgress:ConversationInterface;
		private var roomScripts:RoomScripts;
		
		private var pauseGameTimeUntil:int = 0;
		private var gameTimePauseCallback:Function;		
		
		private var tileWithHilight:FloorTile;
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
		
		public function cleanup():void {
			removeEventListener(Event.ENTER_FRAME, enterFrameListener);
			if (mode != null) {
				mode.cleanup();
				mode = null;
			}
			Assert.assertTrue(activeUi == null, "UI didn't get shut down by mode cleanup");
			while (contentsLayer.numChildren > 0) {
				//NOTE: if/when we add things like tossed grenades, they will be props and this will fail
				var entity:SimpleEntity = SimpleEntity(contentsLayer.getChildAt(0));
				//UNDONE: See comment on SimpleEntity.detachFromRoom()
				entity.detachFromRoom();
			}
			contentsLayer = null;
			cells = null;
			// UNDONE: Does floor need a cleanup?
			floor = null;
			if (parent != null) {
				parent.removeChild(this);
			}
			if (roomScripts != null) {
				roomScripts.cleanup();
			}
			if (Settings.currentRoom == this) {
				Settings.currentRoom = null;
			}
		}
		
		public function changeModeTo(newModeClass:Class, entering:Boolean = false):void {
			forEachComplexEntity(function(entity:ComplexEntity):void {
				if (entity.moving()) {
					entity.movement.endMoveImmediately();
				}
			} );
			if (mode != null) {
				mode.cleanup();
			}
			mode = (newModeClass == null ? null : new newModeClass(this));
			if (entering) {
				roomScripts.runOnEnter();
			}
		}
		
		public function pauseGameTimeIndefinitely():void {
			trace("Pausing game time indefinitely");
			Assert.assertTrue(!gameTimeIsPaused, "Pause indefinitely when already paused");
			pauseGameTimeUntil = int.MAX_VALUE;
		}
		
		public function pauseGameTimeForFixedDelay(seconds:Number, callback:Function = null):void {
			trace("Pausing game time for", seconds, "seconds", (callback == null) ? "no callback" : "with callback");
			if (gameTimeIsPaused) { // Something is screwed up, but try to continue gracefully
				pauseGameTimeUntil = 0;
				if (gameTimePauseCallback != null) {
					Assert.fail("Pause when already paused! Calling original callback.");
					var temp:Function = gameTimePauseCallback;
					gameTimePauseCallback = null;
					temp();
				} else {
					Assert.fail("Pause when already paused! No callback on first pause.");
				}
			}
			pauseGameTimeUntil = getTimer() + seconds * 1000;
			Assert.assertTrue(gameTimePauseCallback == null, "Overwriting game time pause callback");
			gameTimePauseCallback = callback;
		}
		
		public function get gameTimeIsPaused():Boolean {
			return (pauseGameTimeUntil > 0);
		}
		
		// For use when mode change makes pause & callback obsolete
		public function unpauseGameTimeAndDeleteCallback():void {
			trace("Deleting game time pause & callback");
			pauseGameTimeUntil = 0;
			gameTimePauseCallback = null;
		}
		
		private function handlePauseAndAdvanceGameTimeIfNotPaused():void {
			var currentTime:int = getTimer();
			if ((pauseGameTimeUntil > 0) && (pauseGameTimeUntil <= currentTime)) {
				pauseGameTimeUntil = 0;
				trace("Game time pause expired;", gameTimePauseCallback == null ? "no callback" : "calling callback");
				if (gameTimePauseCallback != null) {
					// Inside callback we may pause again, so we need to set the callback to null BEFORE calling it
					var temp:Function = gameTimePauseCallback;
					gameTimePauseCallback = null;
					temp();
				}
				
			}
			if (!gameTimeIsPaused) {
				dispatchEvent(new Event(UNPAUSED_ENTER_FRAME));
			}			
		}
		
		public function startConversation(entity:SimpleEntity, conversationData:ConversationData):void {
			if (conversationInProgress != null) {
				Alert.show("Error! Cannot start a conversation inside another conversation.");
			} else {
				conversationInProgress = new ConversationInterface(entity, conversationData);
				stage.addChild(conversationInProgress); // Conversation takes over ui when added to stage, removes itself & restores when finished
			}
		}
		
		/********** Player UI-related  ****************/
		// CONSIDER: Move this into a class, have the things that now implement IRoomUi subclass it?
		
		// It appears that under hard-to-reproduce conditions, we can have a UI event pending, disable the UI, and
		// then go on to process the UI event.  To avoid this, all of these UI listeners are going to check for
		// null ui.  Yuck.
		
		
		// call this when player-controlled part of the turn begins, to allow player to enter move
		public function enableUi(newUi:IRoomUi, player:ComplexEntity):void {
			activeUi = newUi;
			lastUiPlayer = player;
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
			
			if (activeUi != null) {
				disabledUi = activeUi;
				activeUi.disable();
				activeUi = null;
			}
		}
			
		//UNDONE
		public function restoreUiAfterConversation():void {
			Assert.assertTrue(lastUiPlayer.room == this, "Active player was removed from room. This WILL break things.");
			conversationInProgress = null;
			enableUi(disabledUi, lastUiPlayer);
			disabledUi = null;
		}
		
		
		private function keyDownListener(event:KeyboardEvent):void {
			if (activeUi == null) {
				return;
			}
			switch (event.keyCode) {
				case Util.KEYBOARD_V:
					toggleVisibility();
				break;
				
				case Util.KEYBOARD_I:
					lastUiPlayer.inventory.showInventoryInAlert();
				break;
				
				case Keyboard.HOME:
					new ConversationNonAutoTest();
				break;
				
				default:
					activeUi.keyDown(event.keyCode);
				break;
			}
		}
		
		private function mouseMoveListener(event:MouseEvent):void {
			if (activeUi == null) {
				return;
			}
			activeUi.mouseMove(event.target as FloorTile);
		}

		private function mouseDownListener(event:MouseEvent):void {
			if (activeUi == null) {
				return;
			}
			if (event.shiftKey) {
				addEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
				startDrag();
				dragging = true;
			} else {
				dragging = false;
			}
		}

		private function mouseUpListener(event:MouseEvent):void {
			if (activeUi == null) {
				return;
			}
			removeEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			stopDrag();
		}
		
		private function mouseClickListener(event:MouseEvent):void {
			if (activeUi == null) {
				return;
			}
			if (event.ctrlKey) {
				// Temporary since Flash Projector doesn't support right-button events.
				// If/when we switch to AIR this will be replaced with a real right click listener.
				rightClickListener(event);
				return;
			}
			if (!dragging && (event.target is FloorTile)) {
				activeUi.mouseClick(event.target as FloorTile);
			}
		}
		
		private function rightClickListener(event:MouseEvent):void {
			if (activeUi == null) {
				return;
			}
			if (!(event.target is FloorTile)) {
				return;
			}
			var tile:FloorTile = event.target as FloorTile;
			var slices:Vector.<PieSlice> = activeUi.pieMenuForTile(tile);
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
		
		public function moveHilight(tile:FloorTile, color:uint):void {
			if (tileWithHilight != null) {
				tileWithHilight.filters = [];
			}
			tileWithHilight = tile;
			if (tileWithHilight != null) {
				var glow:GlowFilter = new GlowFilter(color, 1, 15, 15, 10, 1, true, false);
				tileWithHilight.filters = [ glow ];
			}
		}
		
		public function updateToolTip(location:Point):void {
			var character:ComplexEntity = firstComplexEntityIn(location);
			if (character == null) {
				ToolTip.removeToolTip();
			} else {
				var tipLocation:Point = character.centerOfImage();
				ToolTip.displayToolTip(this, character.displayName, tipLocation.x, tipLocation.y);
			}
		}
		
		public function toggleVisibility():void {
			contentsLayer.alpha = 1.5 - contentsLayer.alpha;
		}
		
		//CONSIDER: should entity.addToRoom add itself to the contentsLayer, or do we want the ability to
		//be in the room but not yet on stage?
		public function addEntity(entity:SimpleEntity, location:Point):void {
			cells[location.x][location.y].add(entity);
			contentsLayer.addChild(entity);
			entity.addToRoom(this, location);
			if (mode != null) {
				mode.entityAddedToRoom(entity);
			}
		}

		public function addEntityUsingItsLocation(entity:SimpleEntity):void {
			addEntity(entity, entity.location);
		}
		
		public function removeEntityWithId(entityId:String):void {
			removeEntity( entityInRoomWithId(entityId) );
		}
		
		public function removeEntity(entity:SimpleEntity):void {
			if (entity != null) {
				if (mode != null) {
					mode.entityWillBeRemovedFromRoom(entity);
				}
				var location:Point = entity.location;
				cells[location.x][location.y].remove(entity);		
				entity.dispatchEvent(new EntityEvent(EntityEvent.REMOVED_FROM_ROOM, true, false, entity));
				entity.detachFromRoom();
			}
		}
		
		public function entityInRoomWithId(entityId:String):SimpleEntity {
			for (var i:int = 0; i < size.x; i++) {
				for (var j:int = 0; j < size.y; j++) {
					for each (var prop:Prop in cells[i][j].contents) {
						if ((prop is SimpleEntity) && (SimpleEntity(prop).id == entityId)) {
							return SimpleEntity(prop);
						}
					}
				}
			}
			return null;
		}
		
		public function forEachComplexEntity(callWithEntity:Function, filter:Function = null):void {
			for (var i:int = 0; i < size.x; i++) {
				for (var j:int = 0; j < size.y; j++) {
					for each (var prop:Prop in cells[i][j].contents) {
						if ((prop is ComplexEntity) && ((filter == null) || (filter(prop)))) {
							callWithEntity(prop);
						}
					}
				}
			}
		}
		
		public function forEachEntityIn(location:Point, callWithEntity:Function, filter:Function = null):void {
			cells[location.x][location.y].forEachEntity(callWithEntity, filter);
		}
		
		public function firstEntityIn(location:Point, filter:Function = null):SimpleEntity {
			return cells[location.x][location.y].firstEntity(filter);
		}

		public function firstComplexEntityIn(location:Point, filter:Function = null):ComplexEntity {
			return cells[location.x][location.y].firstComplexEntity(filter);
		}

		public function addPlayerCharacter(entity:ComplexEntity, location:Point): void {
			if (mainPlayerCharacter == null) {
				mainPlayerCharacter = entity;
			}
			addEntity(entity, location);
			if (!entity.isReallyPlayer) {
				entity.changePlayerControl(true);
			}
		}
		
		// This will generally be called by the entity as it crosses the boundary between one floor tile
		// and another during movement.
		public function changeEntityLocation(entity:SimpleEntity, oldLocation:Point, newLocation:Point):void {
			cells[oldLocation.x][oldLocation.y].remove(entity);
			cells[newLocation.x][newLocation.y].add(entity);
			
			if (!entity.location.equals(newLocation)) {
				// If this is called by the entity as part of gradual movement, it will already have set its own
				// location along with appropriate depth.  If not, we need to directly set the location, which will
				// put entity at the center-of-tile depth.
				entity.location = newLocation;
				entity.dispatchEvent(new EntityEvent(EntityEvent.LOCATION_CHANGED_DIRECTLY, true, false, entity));
			}
		}
		
		public function solidness(x:int, y:int):uint {
			if ((x < 0) || (x >= size.x) || (y < 0) || (y >= size.y)) {
				return Prop.OFF_MAP;
			}
			return cells[x][y].solidness();
		}
		
		public function blocksSight(x:int, y:int):Boolean {
			return (solidness(x,y) & Prop.TALL) != 0;
		}
		
		public function blocksGrenade(x:int, y:int):Boolean {
			return (solidness(x,y) & Prop.FILLS_TILE) != 0;
		}
		
		public function spotLocation(spotId:String):Point {
			return spots[spotId];
		}
		
		public function spotLocationWithDefault(spotId:String):Point {
			var location:Point = spotLocation(spotId);
			return (location == null ? new Point(0, 0) : location);
		}
		
		public function spotsMatchingLocation(location:Point):Vector.<String> {
			var matches:Vector.<String> = new Vector.<String>();
			for (var spotId:String in spots) {
				if (location.equals(spots[spotId])) {
					matches.push(spotId);
				}
			}
			return matches;
		}
		
		public function addOrMoveSpot(spotId:String, location:Point):void {
			spots[spotId] = location;
		}
		
		public function removeSpot(spotId:String):void {
			delete spots[spotId];
		}
		
		private function enterFrameListener(event:Event):void {
			stage.focus = stage;
			handlePauseAndAdvanceGameTimeIfNotPaused();
			handleScrolling();
		}						
			
		private function handleScrolling():void {
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
		
		public function scrollToCenter(tileLoc:Point):void {
			scrollingTo = PositionOfRoomToCenterTile(tileLoc);
		}

		public function snapToCenter(tileLoc:Point):void {
			scrollingTo = null;
			var whereToMove:Point = PositionOfRoomToCenterTile(tileLoc);
			this.x = whereToMove.x;
			this.y = whereToMove.y;
		}
	
		private function PositionOfRoomToCenterTile(tileLoc: Point): Point {
			var desiredTileCenter:Point = Floor.centerOf(tileLoc);
			return new Point(Settings.STAGE_WIDTH / 2 - desiredTileCenter.x - Floor.FLOOR_TILE_X / 2, 
							 Settings.STAGE_HEIGHT / 2 - desiredTileCenter.y - Floor.FLOOR_TILE_Y / 2 );
		}
		
		public static function createFromXml(xml:XML, filename:String = ""):Room {
			if (xml.floor.length() == 0) {
				Alert.show("Invalid room file " + filename);
				return null;
			}
			
			var floor:Floor = new Floor();
			floor.loadFromXml(Settings.catalog, xml.floor[0]);
			
			var room:Room = new Room(floor);
			
			if (xml.contents.length() > 0) {
				room.initContentsFromXml(Settings.catalog, xml.contents[0]);
			}
			if (xml.spots.length() > 0) {
				room.initSpotsFromXml(xml.spots[0]);
			}
			room.roomScripts = new RoomScripts(room, xml, filename);
			
			return room;
		}
		
		public function addPlayerCharactersFromSettings(startSpot:String = null):void {
			var startLoc:Point;
			if ((startSpot == null) || (startSpot == "")) {
				startSpot = "start";
			}
			startLoc = spotLocationWithDefault(startSpot);
			
			snapToCenter(startLoc);
			
			for each (var entity:ComplexEntity in Settings.pcs) {
				// UNDONE: start followers near main PC instead of stacked on the same square
				addPlayerCharacter(entity, startLoc);
			}
		}
		
		// During development we'll support reading (but not writing) some older formats.
		// Eventually we'll get rid of all but the final version... and then, if we ever
		// release and continue development, support the release version plus future. ;)
		// To save headaches, I'll attempt to make most changes be additions with reasonable
		// defaults, so most changes won't require a new version.
		public function initContentsFromXml(catalog:Catalog, contentsXml: XML):void {
			var version:int = int(contentsXml.@version);
			
			for each (var propXml: XML in contentsXml.prop) {
				addEntityUsingItsLocation(SimpleEntity.createFromRoomContentsXml(propXml, version, catalog));
			}
			
			//UNDONE For backwards compatibility; remove this eventually
			for each (var walkerXml: XML in contentsXml.walker) {
				addEntityUsingItsLocation(ComplexEntity.createFromRoomContentsXml(walkerXml, version, catalog));
			}
			
			for each (var charXml: XML in contentsXml.char) {
				addEntityUsingItsLocation(ComplexEntity.createFromRoomContentsXml(charXml, version, catalog));
			}
		}

		public function initSpotsFromXml(spotsXml:XML):void {
			spots = new Object();
			for each (var spotXml:XML in spotsXml.spot) {
				var id:String = spotXml.@id;
				if (spots[id] != null) {
					Alert.show("Error! Duplicate spot id " + id);
				}
				spots[id] = new Point(spotXml.@x, spotXml.@y);
			}
		}
		
	} // end class Room

}