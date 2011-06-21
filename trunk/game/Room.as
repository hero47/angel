package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.Floor;
	import angel.common.FloorTile;
	import angel.common.Prop;
	import angel.common.SimplerButton;
	import angel.common.Util;
	import angel.game.combat.RoomCombat;
	import angel.game.event.EntityQEvent;
	import angel.game.event.QEvent;
	import angel.game.script.ConversationData;
	import angel.game.script.ConversationInterface;
	import angel.game.script.RoomTriggers;
	import angel.game.script.ScriptContext;
	import angel.game.script.TriggerMaster;
	import angel.game.test.ConversationNonAutoTest;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;

	//NOTE: Room automatically starts itself running when it goes on stage.
	
	public class Room extends Sprite {
		static public const GAME_ENTER_FRAME:String = "gameEnterFrame";
		static public const ROOM_ENTER_FRAME:String = "roomEnterFrame";
		static public const ROOM_ENTER_UNPAUSED_FRAME:String = "unpausedEnterFrame"; // only triggers when not paused
		static public const ROOM_INIT:String = "roomInit";
		
		static private const SCROLL_SPEED:Number = 3;
		
		public var floor:Floor;
		public var decorationsLayer:Sprite;	// for things painted over the floor, such as movement dots
		// contentsLayer is set transparent to mouse when we're looking for tile clicks, for movement.
		// Later, when we have modes where they'll be picking targets, we can set its mouseChildren to true
		// and detect clicks on entities.

		public var contentsLayer:Sprite;
		
		public var filename:String;
		private var quitButton:SimplerButton;
		
		public var cells:Vector.<Vector.<Cell>>;
		public var mainPlayerCharacter:ComplexEntity;
		public var size:Point;
		public var mode:IRoomMode;
		private var spots:Object = new Object(); // associative array mapping from spotId to location

		public var activeUi:IRoomUi;
		private var suspendedUi:IRoomUi;
		private var suspendedUiPlayer:ComplexEntity;
		private var dragging:Boolean = false;
		
		private var conversationInProgress:ConversationInterface;
		private var triggers:RoomTriggers;
		
		private var gamePauseStack:Vector.<PauseInfo> = new Vector.<PauseInfo>(); // LIFO stack with exceptions
		
		private var tileWithHilight:FloorTile;
		private var scrollingTo:Point = null;
		public var preCombatSave:SaveGame;
		public var resumedFromSave:Boolean;
				
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
			
			addEventListener(Event.ADDED_TO_STAGE, finishInit);
		}
		
		private function finishInit(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, finishInit);
			Settings.gameEventQueue.addListener(this, parent, GAME_ENTER_FRAME, enterFrameListener);
			
			quitButton = new SimplerButton("Exit Game", clickedQuit);
			quitButton.x = 5;
			quitButton.y = stage.stageHeight - quitButton.height - 5;
			parent.addChildAt(quitButton, parent.getChildIndex(this)+1);
			
			if (!resumedFromSave) {
				Settings.gameEventQueue.dispatch(new QEvent(this, ROOM_INIT));
			}
		}
		
		public function cleanup():void {
			Settings.gameEventQueue.removeAllListenersOwnedBy(this);
			if (mode != null) {
				mode.cleanup();
				mode = null;
			}
			Assert.assertTrue(activeUi == null, "UI didn't get shut down by mode cleanup");
			while (contentsLayer.numChildren > 0) {
				//NOTE: if/when we add things like tossed grenades, they will be props and this will fail
				var entity:SimpleEntity = SimpleEntity(contentsLayer.getChildAt(0));
				entity.cleanup();
			}
			contentsLayer = null;
			cells = null;
			// UNDONE: Does floor need a cleanup?
			floor = null;
			if (parent != null) {
				parent.removeChild(this);
			}
			if (triggers != null) {
				Settings.triggerMaster.cleaningUpRoom(this);
				triggers.cleanup();
			}
			
			quitButton.cleanup();
			
			Assert.assertTrue(Settings.gameEventQueue.numberOfListenersOn(this) == 0, "Room still has listeners after cleanup");
			if (Settings.gameEventQueue.numberOfListenersOn(this) > 0) {
				Settings.gameEventQueue.debugTraceListenersOn(this, "After room cleanup, listeners on room:");
			}
		}
		
		public function changeModeTo(newModeClass:Class):void {
			if (newModeClass == RoomCombat) {
				preCombatSave = new SaveGame();
				preCombatSave.collectGameInfo(this);
			} else {
				preCombatSave = null;
			}
			forEachComplexEntity(function(entity:ComplexEntity):void {
				if (entity.moving()) {
					entity.movement.endMoveImmediately();
				}
			} );
			if (mode != null) {
				mode.cleanup();
			}
			mode = (newModeClass == null ? null : new newModeClass(this));
		}
		
		public function pauseGameTimeIndefinitely(pauseOwner:Object):void {
			gamePauseStack.push(new PauseInfo(int.MAX_VALUE, pauseOwner));
		}
		
		public function pauseGameTimeForFixedDelay(seconds:Number, pauseOwner:Object, callback:Function = null):void {
			gamePauseStack.push(new PauseInfo(getTimer() + seconds * 1000, pauseOwner, callback));
		}
		
		public function gameTimeIsPaused():Boolean {
			return (gamePauseStack.length > 0);
		}
		
		// For use when mode change makes callbacks obsolete
		public function unpauseAndDeleteAllOwnedBy(owner:Object):void {
			var i:int = 0;
			while (i < gamePauseStack.length) {
				if (gamePauseStack[i].pauseOwner == owner) {
					gamePauseStack.splice(i, 1);
				} else {
					++i;
				}
			}
		}
		
		public function unpauseFromLastIndefinitePause(owner:Object):void {
			if (gamePauseStack.length < 1) {
				Assert.fail("unpause indefinite when not paused");
				return;
			}
			for (var i:int = gamePauseStack.length - 1; i >= 0; --i) {
				var lastPauseInfo:PauseInfo = gamePauseStack[i];
				if ((lastPauseInfo.pauseUntil == int.MAX_VALUE) && (lastPauseInfo.pauseOwner == owner)) {
					gamePauseStack.splice(i, 1);
					return;
				}
			}
			Assert.fail("unpause: pause not found!");
		}
		
		private function handlePauseAndAdvanceGameTimeIfNotPaused():void {
			var currentTime:int = getTimer();
			var stayPaused:Boolean = false;
			while (gameTimeIsPaused() && !stayPaused) {
				var lastPauseInfo:PauseInfo = gamePauseStack[gamePauseStack.length - 1];
				if (lastPauseInfo.pauseUntil > currentTime) {
					stayPaused = true;
				} else {
					gamePauseStack.pop();
					if (lastPauseInfo.callback != null) {
						lastPauseInfo.callback();
					}
				}
			}
			
			Settings.gameEventQueue.dispatch(new QEvent(this, ROOM_ENTER_FRAME));
			if (!gameTimeIsPaused()) {
				Settings.gameEventQueue.dispatch(new QEvent(this, ROOM_ENTER_UNPAUSED_FRAME));
			}			
		}
		
		public function startConversation(context:ScriptContext, conversationData:ConversationData):void {
			if (conversationInProgress != null) {
				Alert.show("Error! Cannot start a conversation inside another conversation.");
			} else {
				quitButton.visible = false;
				conversationInProgress = new ConversationInterface(context, conversationData);
				stage.addChild(conversationInProgress); // Conversation takes over ui when added to stage, removes itself & restores when finished
			}
		}
		
		public function endConversation(converse:ConversationInterface, originalRoom:Room):void {
			conversationInProgress = null;
			restoreUiAfterSuspend(converse, originalRoom);
			quitButton.visible = true;
		}
		
		/********** Player UI-related  ****************/
		// CONSIDER: Move this into a class, have the things that now implement IRoomUi subclass it?
		
		// It appears that under hard-to-reproduce conditions, we can have a UI event pending, disable the UI, and
		// then go on to process the UI event.  To avoid this, all of these UI listeners are going to check for
		// null ui.  Yuck.
		
		
		// call this when player-controlled part of the turn begins, to allow player to enter move
		public function enableUi(newUi:IRoomUi, player:ComplexEntity):void {
			activeUi = newUi;
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
				activeUi.disable();
				activeUi = null;
			}
		}
			
		//UNDONE
		public function restoreUiAfterSuspend(suspender:Object, suspendedRoom:Room):void {
			if (suspendedRoom != this) {
				return;
			}
			unpauseFromLastIndefinitePause(suspender);
			if (suspendedUi != null) {
				Assert.assertTrue(suspendedUiPlayer.room == this, "Active player was removed from room. This WILL break things.");
				enableUi(suspendedUi, suspendedUiPlayer);
				suspendedUi = null;
				suspendedUiPlayer = null;
			}
		}
		
		public function suspendUi(suspender:Object):void {
			Assert.assertTrue(suspendedUi == null, "Double suspend, we will lose original ui");
			pauseGameTimeIndefinitely(suspender);
			if (activeUi != null) {
				suspendedUi = activeUi;
				suspendedUiPlayer = activeUi.currentPlayer;
				disableUi();
			}
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
					new ConversationNonAutoTest(this);
				break;
				case Keyboard.PAGE_UP:
					Settings.gameEventQueue.debugTraceListeners(null, "Game event listeners");
				break;
				case Util.KEYBOARD_R:
					forEachComplexEntity(function(entity:ComplexEntity):void { entity.revive(); } );
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
				activeUi.mouseMove(event.target as FloorTile); // It's possible to get here without mousemove, so fake one first.
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
			activeUi.mouseMove(tile); // It's possible to get here without mousemove, so fake one first.
			
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

		public function activePlayer():ComplexEntity {
			if (mode == null) {
				return mainPlayerCharacter;
			}
			return mode.activePlayer();
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
				Settings.gameEventQueue.dispatch(new EntityQEvent(entity, EntityQEvent.REMOVED_FROM_ROOM));
				entity.cleanup();
			}
		}
		
		public function changeMainPlayerCharacterTo(entity:ComplexEntity):void {
			var oldMainPc:ComplexEntity = mainPlayerCharacter;
			mainPlayerCharacter = entity;
			Settings.gameEventQueue.dispatch(new EntityQEvent(entity, EntityQEvent.BECAME_MAIN_PC, oldMainPc));
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
		
		public function forEachEntity(callWithEntity:Function, filter:Function = null):void {
			for (var i:int = 0; i < size.x; i++) {
				for (var j:int = 0; j < size.y; j++) {
					if (cells[i][j].contents == null) {
						continue;
					}
					var contents:Vector.<Prop> = cells[i][j].contents.concat(); // clone in case callback deletes something
					for each (var prop:Prop in contents) {
						if ((prop is SimpleEntity) && ((filter == null) || (filter(prop)))) {
							callWithEntity(prop);
						}
					}
				}
			}
		}
		
		public function forEachComplexEntity(callWithEntity:Function, filter:Function = null):void {
			forEachEntity(callWithEntity, function(entity:SimpleEntity):Boolean {
				return ((entity is ComplexEntity) && ((filter == null) || (filter(entity))));
			} );
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
				entity.changePlayerControl(true, ComplexEntity.FACTION_FRIEND);
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
				Settings.gameEventQueue.dispatch(new EntityQEvent(entity, EntityQEvent.LOCATION_CHANGED_DIRECTLY));
			}
		}
		
		// If ignoreInvisible is true, pretend anything invisible doesn't exist.
		public function solidness(x:int, y:int, ignoreInvisible:Boolean = false):uint {
			if ((x < 0) || (x >= size.x) || (y < 0) || (y >= size.y)) {
				return Prop.OFF_MAP;
			}
			return cells[x][y].solidness(ignoreInvisible);
		}
		
		public function blocksSight(x:int, y:int):Boolean {
			return (solidness(x,y) & Prop.TALL) != 0;
		}
		
		public function blocksThrown(x:int, y:int):Boolean {
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
		
		private function enterFrameListener(event:QEvent):void {
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
		
		public static function createFromXmlExceptContents(xml:XML, filename:String = ""):Room {
			if (xml.floor.length() == 0) {
				Alert.show("Invalid room file " + filename);
				return null;
			}
			
			var floor:Floor = new Floor();
			floor.loadFromXml(Settings.catalog, xml.floor[0]);
			
			var room:Room = new Room(floor);
			room.filename = filename;
			
			if (xml.spots.length() > 0) {
				room.initSpotsFromXml(xml.spots[0]);
			}
			
			room.triggers = new RoomTriggers(room, xml, filename);
			Settings.triggerMaster.changeRoom(room);
			
			return room;
		}
		
		public static function createFromXml(xml:XML, save:SaveGame, filename:String = ""):Room {
			var room:Room = createFromXmlExceptContents(xml, filename);
			if (xml.contents.length() > 0) {
				room.initContentsFromXml(Settings.catalog, xml.contents[0]);
			}
			save.addPlayerCharactersToRoom(room);
			
			return room;
		}
		
		// During development we'll support reading (but not writing) some older formats.
		// Eventually we'll get rid of all but the final version... and then, if we ever
		// release and continue development, support the release version plus future. ;)
		// To save headaches, I'll attempt to make most changes be additions with reasonable
		// defaults, so most changes won't require a new version.
		public function initContentsFromXml(catalog:Catalog, contentsXml: XML):void {
			
			for each (var propXml: XML in contentsXml.prop) {
				addEntityUsingItsLocation(SimpleEntity.createFromRoomContentsXml(propXml, catalog));
			}
			
			for each (var charXml: XML in contentsXml.char) {
				addEntityUsingItsLocation(ComplexEntity.createFromRoomContentsXml(charXml, catalog));
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
		
		public function createContentsXml():XML {
			var xml:XML = <contents />;
			forEachEntity( function(entity:SimpleEntity):void { entity.appendXMLSaveInfo(xml); }, notPlayer );
			return xml;
		}
		
		private function notPlayer(entity:SimpleEntity):Boolean {
			var complex:ComplexEntity = entity as ComplexEntity;
			return ((complex == null) || (!complex.isReallyPlayer));
		}
		
		private function clickedQuit(event:Event):void {
			if (preCombatSave != null) {
				var options:Object = { buttons:["Yes", "No"], callback:combatQuitCallback };
				Alert.show("Combat state is not saved!\nYou will be returned to the state just before combat!\nAre you certain you want to exit during combat?", options);
				return;
			}
			var save:SaveGame = new SaveGame();
			save.collectGameInfo(this);
			new GameMenu(Main(this.parent), true, save);
		}
		
		private function combatQuitCallback(buttonName:String):void {
			if (buttonName != "Yes") {
				return;
			}
			new GameMenu(Main(this.parent), true, preCombatSave);
		}
		
		public function revertToPreCombatSave():void {
			if (preCombatSave != null) {
				preCombatSave.resumeSavedGame(IAngelMain(this.parent));
			} else {
				new GameMenu(IAngelMain(this.parent), true, null);
			}
		}
		
	} // end class Room

}

class PauseInfo {
	public var pauseUntil:int;
	public var pauseOwner:Object;
	public var callback:Function;
	public function PauseInfo(pauseUntil:int, pauseOwner:Object, callback:Function = null) {
		this.pauseUntil = pauseUntil;
		this.pauseOwner = pauseOwner;
		this.callback = callback;
	}
}