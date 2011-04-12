package angel.game {
	import angel.common.Floor;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	/* WARNING: The minimap does not do any line-of-sight checking itself; it bases display on the enemy's visibility
	 * property.
	 * Currently (4/12/11) the visibility is adjusted as an entity begins moving to a new tile (EntityEvent.MOVED)
	 * and the minimap updates as an entity finishes moving to a new tile (EntityEvent.FINISHED_ONE_TILE_OF_MOVE) so
	 * this works out nicely.  If those ever get changed to listen for the same event, then we will need to fiddle
	 * with listener priorities to make sure that things are processed in the correct order!
	 */
	 
	public class Minimap extends Sprite {
		
		private static const WIDTH:int = 250;
		private static const HEIGHT:int = 150;
		private static const SCALE:int = 10;
		
		// WARNING: All of these icons must be the same size, with the image that appears on the map centered in the bitmap
		[Embed(source='../../../EmbeddedAssets/combat_minimap_enemy.png')]
		private static const enemyBitmap:Class;		
		[Embed(source = '../../../EmbeddedAssets/combat_minimap_mainPCb.png')]
		private static const mainPlayerBitmap:Class;
		[Embed(source = '../../../EmbeddedAssets/combat_minimap_secondaryPC.png')]
		private static const otherPlayerBitmap:Class;
		[Embed(source = '../../../EmbeddedAssets/combat_minimap_active.png')]
		private static const activeBitmap:Class;
		[Embed(source = '../../../EmbeddedAssets/combat_minimap_enemyDown.png')]
		private static const enemyDownBitmap:Class;
		[Embed(source = '../../../EmbeddedAssets/combat_minimap_PCDown.png')]
		private static const playerDownBitmap:Class;
		[Embed(source = '../../../EmbeddedAssets/combat_minimap_enemyLastSeen.png')]
		private static const enemyLastSeenBitmap:Class;
		
		
		private static const mainPlayerBitmapData:BitmapData = (new mainPlayerBitmap()).bitmapData;
		private static const otherPlayerBitmapData:BitmapData = (new otherPlayerBitmap()).bitmapData;
		private static const enemyBitmapData:BitmapData = (new enemyBitmap()).bitmapData;
		private static const enemyLastSeenBitmapData:BitmapData = (new enemyLastSeenBitmap()).bitmapData;
		private static const deadPlayerBitmapData:BitmapData = (new playerDownBitmap()).bitmapData;
		private static const deadEnemyBitmapData:BitmapData = (new enemyDownBitmap()).bitmapData;
		
		private var combat:RoomCombat;
		private var offsetX:int;
		private var offsetY:int;
		private var entityToMapIcon:Dictionary = new Dictionary();
		private var roomSprite:Sprite;
		private var mapMask:Shape;
		
		private var activeEntity:SimpleEntity;
		private var activeEntityMarker:Bitmap = new activeBitmap();
		
		public function Minimap(combat:RoomCombat) {
			this.combat = combat;
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			addEventListener(Event.ENTER_FRAME, scrollRoomSpriteToMatchRealRoom);
			combat.room.addEventListener(EntityEvent.FINISHED_ONE_TILE_OF_MOVE, someoneMoved);
			combat.room.addEventListener(EntityEvent.START_TURN, someoneStartedTurn);
			combat.room.addEventListener(EntityEvent.DEATH, someoneDied);
			
			roomSprite = new Sprite();
			addChild(roomSprite);
			
			var visibleWidthScaled:int = combat.room.stage.stageWidth / SCALE;
			var visibleHeightScaled:int = combat.room.stage.stageHeight / SCALE;
			offsetX = (WIDTH - visibleWidthScaled) / 2;
			offsetY = (HEIGHT - visibleHeightScaled) / 2;
			
			graphics.lineStyle(2, 0x888888, 0.75);
			graphics.beginFill(0x0, .75);
			graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, WIDTH/10);
			graphics.endFill();
			
			mapMask = new Shape();
			mapMask.graphics.beginFill(0xffffff, 1);
			mapMask.graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, WIDTH/10);
			mapMask.graphics.endFill();
			addChild(mapMask);
			this.mask = mapMask;
			
			
			graphics.lineStyle(1, 0x888888, 0.75);
			graphics.drawRect(offsetX, offsetY, visibleWidthScaled, visibleHeightScaled);
			
			// adjust offsets for icon size just once rather than every time we draw
			offsetX -= mainPlayerBitmapData.width / 2;
			offsetY -= mainPlayerBitmapData.height / 2;
			
			for (var i:int = 0; i < combat.fighters.length; i++) {
				var entity:ComplexEntity = combat.fighters[i];
				var bits:BitmapData = (i == 0 ? mainPlayerBitmapData :
									(entity.isPlayerControlled ? otherPlayerBitmapData : enemyBitmapData));
									
				if (entity.isPlayerControlled) {
					bits = (i == 0 ? mainPlayerBitmapData : otherPlayerBitmapData);
				} else {
					bits = (entity.visible ? enemyBitmapData : enemyLastSeenBitmapData);
				}
				var icon:Bitmap = new Bitmap(bits);
				setIconPositionFromEntityLocation(icon, entity);
				roomSprite.addChild(icon);
				entityToMapIcon[entity] = icon;
			}
			roomSprite.addChild(activeEntityMarker);
			activeEntity = combat.fighters[0];
			setIconPositionFromEntityLocation(activeEntityMarker, activeEntity);
		}
		
		public function cleanup():void {
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			removeEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			removeEventListener(Event.ENTER_FRAME, scrollRoomSpriteToMatchRealRoom);
			combat.room.removeEventListener(EntityEvent.FINISHED_ONE_TILE_OF_MOVE, someoneMoved);
			combat.room.removeEventListener(EntityEvent.START_TURN, someoneStartedTurn);
			combat.room.removeEventListener(EntityEvent.DEATH, someoneDied);
			if (parent != null) {
				parent.removeChild(this);
			}
		}
		
		private function setIconPositionFromEntityLocation(icon:Bitmap, entity:SimpleEntity):void {
			var mapLoc:Point = Floor.centerOf(entity.location);
			icon.x = Math.floor(mapLoc.x / SCALE) + offsetX;
			icon.y = Math.floor(mapLoc.y / SCALE) + offsetY;
		}
		
		private function adjustActiveEntityMarker():void {
			var activeEntityIcon:Bitmap = entityToMapIcon[activeEntity];
			activeEntityMarker.x = activeEntityIcon.x;
			activeEntityMarker.y = activeEntityIcon.y;
		}
		
		private function adjustEnemyIconsForVisibility():void {
			for each (var entity:ComplexEntity in combat.fighters) {
				if (!entity.isPlayerControlled) {
					var icon:Bitmap = entityToMapIcon[entity];
					if (entity.visible) {
						icon.bitmapData = enemyBitmapData;
						setIconPositionFromEntityLocation(icon, entity);
					} else {
						icon.bitmapData = enemyLastSeenBitmapData;
					}
				}
			}
			
		}
		
		public function someoneMoved(event:EntityEvent):void {
			var icon:Bitmap = entityToMapIcon[event.entity];
			if (ComplexEntity(event.entity).isPlayerControlled) {
				setIconPositionFromEntityLocation(icon, event.entity);
				adjustEnemyIconsForVisibility();
			} else if (event.entity.visible) {
				setIconPositionFromEntityLocation(icon, event.entity);
			} else {
				icon.bitmapData = enemyLastSeenBitmapData;
			}
			
			if (event.entity == activeEntity) {
				adjustActiveEntityMarker();
			}
		}
		
		public function someoneStartedTurn(event:EntityEvent):void {
			activeEntity = event.entity;
			adjustActiveEntityMarker();
		}
		
		public function someoneDied(event:EntityEvent):void {
			var icon:Bitmap = entityToMapIcon[event.entity];
			icon.bitmapData = (ComplexEntity(event.entity).isPlayerControlled ? deadPlayerBitmapData : deadEnemyBitmapData);
		}
		
		public function scrollRoomSpriteToMatchRealRoom(event:Event):void {
			roomSprite.x = Math.floor(combat.room.x / SCALE);
			roomSprite.y = Math.floor(combat.room.y / SCALE);
		}
		
		public function mouseDownListener(event:MouseEvent):void {
			addEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			startDrag();
		}
		
		public function mouseUpListener(event:MouseEvent):void {
			removeEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			stopDrag();
		}
		
	}

}