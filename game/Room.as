package angel.game {
	import angel.common.Floor;
	import angel.common.FloorTile;
	import angel.common.Prop;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
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
			addEventListener(Event.ADDED_TO_STAGE, finishInit);
			
		}
		
		private function finishInit(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, finishInit);

		}
		
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
		
		//CONSIDER: should entity.addToRoom add itself to the contentsLayer, or do we want the ability to
		//be in the room but not yet on stage?
		public function addEntity(entity:Entity, location:Point):void {
			cells[location.x][location.y].add(entity);
			contentsLayer.addChild(entity);
			entity.addToRoom(this, location);
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
		public function changePropLocation(prop:Prop, newLocation:Point):void {
			cells[prop.location.x][prop.location.y].remove(prop);
			cells[newLocation.x][newLocation.y].add(prop);
			if (prop == playerCharacter) {
				mode.playerMoved(newLocation);
			}
		}
		
		public function playerFinishedMoving():void {
			mode.playerMoved(null);
		}
		
		public function solid(location:Point):Boolean {
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
	} // end class Room

}