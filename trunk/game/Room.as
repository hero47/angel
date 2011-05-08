package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.Floor;
	import angel.common.FloorTile;
	import angel.common.Prop;
	import angel.common.PropImage;
	import angel.common.Util;
	import angel.game.conversation.ConversationData;
	import angel.game.conversation.ConversationInterface;
	import angel.game.test.ConversationNonAutoTest;
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
		public var mainPlayerCharacter:ComplexEntity;
		public var size:Point;
		public var mode:RoomMode;

		public var activeUi:IRoomUi;
		private var disabledUi:IRoomUi;
		private var lastUiPlayer:ComplexEntity;
		private var dragging:Boolean = false;
		private var gameIsPaused:Boolean = false;
		private var pauseTimer:Timer;
		private var pauseTimerInternalCallback:Function;
		
		private var tileWithFilter:FloorTile;
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
			forEachComplexEntity(function(entity:ComplexEntity):void {
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
			trace("Pausing", milliseconds);
			Assert.assertTrue(!gameIsPaused, "Pause when already paused");
			gameIsPaused = true;
			
/*
 * We're seeing a mysterious intermittant non-reproducible bug where occasionally the
 * game will just get stuck in pause.  I've specifically seen this happen after
 * a player character reserved fire; traces showed "Pausing 1000" but the trace in
 * the callback function was never executed.  I had added code in the room's EnterFrame
 * handler to detect this case, try restarting the timer, and if the pause went on
 * too long generate a timer event itself; this is what the trace showed.
			
PC-barbara-1 reserve fire
Pausing 1000
Seconds paused aprx: 1 Should pause: 1
Error! Game is paused but timer isn't running.  Starting it.
Seconds paused aprx: 2 Should pause: 1
Error! Game is paused but timer isn't running.  Starting it.
Seconds paused aprx: 3 Should pause: 1
Error! Pause is stuck. Attempting unstick.
Error! Game is paused but timer isn't running.  Starting it.
Seconds paused aprx: 4 Should pause: 1
Error! Pause is stuck. Attempting unstick.
...

 * My next attempt at a patch is to stash a reference to the function that the timer
 * should be calling, and call that directly in the "attempting unstick" case.
 * 
 * I wish I had an explanation for this!
 * It is feeling like a bug in Flash's timer handling, but myriads of people use timers,
 * so it's more likely something I'm doing wrong.
 */
			
			Assert.assertTrue(pauseTimer == null, "Overwriting pauseTimer");
			pauseTimer = new Timer(milliseconds, 1);
			pauseTimerInternalCallback = function(event:TimerEvent):void {
				trace("Pause timer complete");
				pauseTimer = null;
				pauseTimerInternalCallback = null;
				Assert.assertTrue(gameIsPaused, "Something unpaused us before pause timer expired");
				gameIsPaused = false;
				if (callback != null) {
					callback();
				}
			}
			pauseTimer.addEventListener(TimerEvent.TIMER_COMPLETE, pauseTimerInternalCallback, false, 0, true );
			pauseTimer.start();
		}
		
		public function get paused():Boolean {
			return gameIsPaused;
		}
		
		public function startConversation(entity:SimpleEntity, conversationData:ConversationData):void {
			var conversation:ConversationInterface = new ConversationInterface(entity, conversationData);
			stage.addChild(conversation); // Conversation takes over ui when added to stage, removes itself & restores when finished
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
		
		public function restoreLastUi():void {
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
			if (tileWithFilter != null) {
				tileWithFilter.filters = [];
			}
			tileWithFilter = tile;
			if (tileWithFilter != null) {
				var glow:GlowFilter = new GlowFilter(color, 1, 15, 15, 10, 1, true, false);
				tileWithFilter.filters = [ glow ];
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
			var entity:SimpleEntity = entityInRoomWithId(entityId);
			if (entity != null) {
				if (mode != null) {
					mode.entityWillBeRemovedFromRoom(entity);
				}
				var location:Point = entity.location;
				cells[location.x][location.y].remove(entity);		
				entity.dispatchEvent(new EntityEvent(EntityEvent.REMOVED_FROM_ROOM, true, false, entity));
				entity.cleanup();
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
			entity.changePlayerControl(true);
		}
		
		// This will generally be called by the entity as it crosses the boundary between one floor tile
		// and another during movement.
		public function changeEntityLocation(entity:ComplexEntity, oldLocation:Point, newLocation:Point):void {
			cells[oldLocation.x][oldLocation.y].remove(entity);
			cells[newLocation.x][newLocation.y].add(entity);
			
			if (!entity.location.equals(newLocation)) {
				// If this is called by the entity as part of gradual movement, it will already have set its own
				// location along with appropriate depth.  If not, we need to directly set the location, which will
				// put entity at the center-of-tile depth.
				entity.location = newLocation;
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
		
		private var debugPauseCount:int;
		private function enterFrameListener(event:Event):void {
			stage.focus = stage;
			if (!gameIsPaused) {
				dispatchEvent(new Event(UNPAUSED_ENTER_FRAME));
			}
			handleScrolling();
			
			if (gameIsPaused) {
				if (!pauseTimer.running) {
					trace("Error! Game is paused but timer isn't running.  Starting it.");
					Alert.show("Error! Game is paused but timer isn't running.  Starting it.");
					pauseTimer.start();
				} else {
					debugPauseCount++;
					var atSecond:Boolean = (debugPauseCount % Settings.FRAMES_PER_SECOND) == 0;
					if (atSecond) {
						trace("Seconds paused aprx:", debugPauseCount / Settings.FRAMES_PER_SECOND, "Should pause:", int(pauseTimer.delay / 1000));
						if (debugPauseCount / Settings.FRAMES_PER_SECOND > pauseTimer.delay / 1000 + 1) {
							trace("Error! Pause is stuck. Attempting unstick.");
							Alert.show("Error! Pause is stuck. Attempting unstick.");
							pauseTimerInternalCallback(null);
						}
					}
				}
			} else {
				if (debugPauseCount > 0) {
					trace("reached unpaused frame after pausing");
				}
				debugPauseCount = 0;
			}
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
		
		public function scrollToCenter(tileLoc: Point):void {
			scrollingTo = PositionOfRoomToCenterTile(tileLoc);
		}

		public function snapToCenter(tileLoc: Point):void {
			scrollingTo = null;
			var whereToMove: Point = PositionOfRoomToCenterTile(tileLoc);
			this.x = whereToMove.x;
			this.y = whereToMove.y;
		}
	
		private function PositionOfRoomToCenterTile(tileLoc: Point): Point {
			var desiredTileCenter:Point = Floor.centerOf(tileLoc);
			return new Point(stage.stageWidth / 2 - desiredTileCenter.x - Floor.FLOOR_TILE_X / 2, 
							 stage.stageHeight / 2 - desiredTileCenter.y - Floor.FLOOR_TILE_Y / 2 );
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
			for each (var walkerXml: XML in contentsXml.walker) {
				addEntityUsingItsLocation(Walker.createFromRoomContentsXml(walkerXml, version, catalog));
			}
		}
		
	} // end class Room

}