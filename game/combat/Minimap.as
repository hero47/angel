package angel.game.combat {
	import angel.common.Floor;
	import angel.game.ComplexEntity;
	import angel.game.event.EntityQEvent;
	import angel.game.event.QEvent;
	import angel.game.Room;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
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
	 * this works out nicely.  However, opportunity fire also happens on EntityEvent.FINISHED_ONE_TILE_OF_MOVE; this
	 * can generate EntityEvent.DEATH, which the minimap also listens for.  Need to be careful that the entity doesn't
	 * spring back to life on the minimap as a result of processing the move event if it's already processed a death
	 * event.  I've prioritized the listeners so the RoomCombat will go first on any that they're both listening for.
	 */
	 
	public class Minimap extends Sprite {
		
		private static const WIDTH:int = 250;
		private static const HEIGHT:int = 150;
		private static const SCALE:int = 10;
		
		// WARNING: All of these icons must be the same size, with the image that appears on the map centered in the bitmap
		[Embed(source='../../EmbeddedAssets/combat_minimap_enemy.png')]
		private static const enemyBitmap:Class;		
		[Embed(source = '../../EmbeddedAssets/combat_minimap_mainPCb.png')]
		private static const mainPlayerBitmap:Class;
		[Embed(source = '../../EmbeddedAssets/combat_minimap_secondaryPC.png')]
		private static const otherPlayerBitmap:Class;
		[Embed(source = '../../EmbeddedAssets/combat_minimap_active.png')]
		private static const activeBitmap:Class;
		[Embed(source = '../../EmbeddedAssets/combat_minimap_enemyDown.png')]
		private static const enemyDownBitmap:Class;
		[Embed(source = '../../EmbeddedAssets/combat_minimap_PCDown.png')]
		private static const playerDownBitmap:Class;
		[Embed(source = '../../EmbeddedAssets/combat_minimap_enemyLastSeen2.png')]
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
		
		// NOTE: The minimap doesn't do any line-of-sight calculations on its own.  It uses the
		// visibility setting on the entities themselves to determine visibility on map.
		// If an event listener changes the visibility, it needs to have higher priority
		// than the minimap's event listener.
		public function Minimap(combat:RoomCombat) {
			
			// Wm wants it mouse-transparent and non-draggable.  I disagree, so just commenting out the
			// dragging stuff for the time being.
			this.mouseEnabled = false;
			this.mouseChildren = false;
			
			this.combat = combat;
			//addEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			Settings.gameEventQueue.addListener(this, combat.room, EntityQEvent.FINISHED_ONE_TILE_OF_MOVE, someoneMoved);
			Settings.gameEventQueue.addListener(this, combat.room, EntityQEvent.LOCATION_CHANGED_DIRECTLY, someoneMoved);
			Settings.gameEventQueue.addListener(this, combat.room, EntityQEvent.START_TURN, someoneStartedTurn);
			Settings.gameEventQueue.addListener(this, combat.room, EntityQEvent.REMOVED_FROM_ROOM, someoneLeftRoom);
			Settings.gameEventQueue.addListener(this, combat.room, EntityQEvent.DEATH, someoneDied);
			Settings.gameEventQueue.addListener(this, combat.room, EntityQEvent.CHANGED_FACTION, someoneChangedFaction);
			Settings.gameEventQueue.addListener(this, combat.room, EntityQEvent.JOINED_COMBAT, someoneJoinedCombat);
			Settings.gameEventQueue.addListener(this, combat.room, Room.ROOM_ENTER_FRAME, scrollRoomSpriteToMatchRealRoom);
			
			roomSprite = new Sprite();
			addChild(roomSprite);
			
			var visibleWidthScaled:int = Settings.STAGE_WIDTH / SCALE;
			var visibleHeightScaled:int = Settings.STAGE_HEIGHT / SCALE;
			offsetX = (WIDTH - visibleWidthScaled) / 2;
			offsetY = (HEIGHT - visibleHeightScaled) / 2;
			
			graphics.lineStyle(2, 0x888888, 0.75);
			graphics.beginFill(0x0, .75);
			graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, WIDTH/10);
			graphics.endFill();
			
			var tempPoint:Point;
			roomSprite.graphics.lineStyle(1, 0xff0000, 0.5);
			tempPoint = Floor.topCornerOf(new Point(0, 0));
			roomSprite.graphics.moveTo(tempPoint.x / SCALE + offsetX, tempPoint.y / SCALE + offsetY);
			tempPoint = Floor.topCornerOf(new Point(combat.room.size.x, 0));
			roomSprite.graphics.lineTo(tempPoint.x / SCALE + offsetX, tempPoint.y / SCALE + offsetY);
			tempPoint = Floor.topCornerOf(combat.room.size);
			roomSprite.graphics.lineTo(tempPoint.x / SCALE + offsetX, tempPoint.y / SCALE + offsetY);
			tempPoint = Floor.topCornerOf(new Point(0, combat.room.size.y));
			roomSprite.graphics.lineTo(tempPoint.x / SCALE + offsetX, tempPoint.y / SCALE + offsetY);
			tempPoint = Floor.topCornerOf(new Point(0, 0));
			roomSprite.graphics.lineTo(tempPoint.x / SCALE + offsetX, tempPoint.y / SCALE + offsetY);
			
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
				addFighter(combat.fighters[i], i==0);
			}
			roomSprite.addChild(activeEntityMarker);
			activeEntity = combat.fighters[0];
			setIconPositionFromEntityLocation(activeEntityMarker, activeEntity);
		}
		
		public function cleanup():void {
			//removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			//removeEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			Settings.gameEventQueue.removeAllListenersOwnedBy(this);
			if (parent != null) {
				parent.removeChild(this);
			}
		}
		
		private function addFighter(fighter:ComplexEntity, isMainPlayer:Boolean):void {
			var bits:BitmapData;
			if (fighter.isPlayerControlled) {
				bits = (isMainPlayer ? mainPlayerBitmapData : otherPlayerBitmapData);
			} else {
				bits = (fighter.visible ? enemyBitmapData : enemyLastSeenBitmapData);
			}
			var icon:Bitmap = new Bitmap(bits);
			setIconPositionFromEntityLocation(icon, fighter);
			roomSprite.addChild(icon);
			entityToMapIcon[fighter] = icon;
		}
		
		private function setIconPositionFromLocation(icon:Bitmap, location:Point):void {
			var mapLoc:Point = Floor.centerOf(location);
			icon.x = Math.floor(mapLoc.x / SCALE) + offsetX;
			icon.y = Math.floor(mapLoc.y / SCALE) + offsetY;
		}
		
		private function setIconPositionFromEntityLocation(icon:Bitmap, entity:SimpleEntity):void {
			setIconPositionFromLocation(icon, entity.location);
		}
		
		//CONSIDER: is there a better place to put off-map icons?  Should we spread them out?  Should we show them at all?
		private function setIconPositionOffMap(icon:Bitmap):void {
			setIconPositionFromLocation(icon, new Point(5,-5));
		}
		
		private function adjustActiveEntityMarker():void {
			var activeEntityIcon:Bitmap = entityToMapIcon[activeEntity];
			activeEntityMarker.x = activeEntityIcon.x;
			activeEntityMarker.y = activeEntityIcon.y;
		}
		
		private function adjustEnemyIcon(enemy:ComplexEntity):void {
			var icon:Bitmap = entityToMapIcon[enemy];
			if (enemy.visible) {
				icon.bitmapData = (enemy.isAlive() ? enemyBitmapData : deadEnemyBitmapData);
				setIconPositionFromEntityLocation(icon, enemy);
			} else {
				icon.bitmapData = enemyLastSeenBitmapData;
			}
		}
		
		private function adjustAllEnemyIconsForVisibility():void {
			for each (var entity:ComplexEntity in combat.fighters) {
				if (!entity.isPlayerControlled) {
					adjustEnemyIcon(entity);
				}
			}
		}
		
		public function someoneMoved(event:EntityQEvent):void {
			var entity:ComplexEntity = event.complexEntity;
			if (entityToMapIcon[entity] == null) {
				// Whatever moved isn't one of our fighters
				return;
			}
			if (entity.isPlayerControlled) {
				setIconPositionFromEntityLocation(entityToMapIcon[entity], entity);
				adjustAllEnemyIconsForVisibility();
			} else {
				adjustEnemyIcon(entity);
			}
			
			if (entity == activeEntity) {
				adjustActiveEntityMarker();
			}
		}
		
		public function someoneStartedTurn(event:EntityQEvent):void {
			activeEntity = event.complexEntity;
			adjustActiveEntityMarker();
		}
		
		public function someoneDied(event:EntityQEvent):void {
			var icon:Bitmap = entityToMapIcon[event.complexEntity];
			if (icon != null) { // we don't currently (5/7/11) show map icons for non-combattants, so need to check
				icon.bitmapData = (event.complexEntity.isPlayerControlled ? deadPlayerBitmapData : deadEnemyBitmapData);
				adjustAllEnemyIconsForVisibility();
			}
		}
		
		public function someoneJoinedCombat(event:EntityQEvent):void {
			var entity:ComplexEntity = event.complexEntity;
			addFighter(entity, false);
			if (!entity.visible) {
				setIconPositionOffMap(entityToMapIcon[entity]);
			}
			adjustAllEnemyIconsForVisibility();
		}
		
		//CONSIDER: If the person who left was a currently-out-of-sight enemy, this lets the player know that they're
		//no longer in room rather than just hiding somewhere.  Is that good or bad?
		public function someoneLeftRoom(event:EntityQEvent):void {
			var icon:Bitmap = entityToMapIcon[event.complexEntity];
			if (icon != null) {
				roomSprite.removeChild(icon);
				delete entityToMapIcon[event.complexEntity];
				adjustAllEnemyIconsForVisibility();
			}
		}
		
		public function someoneChangedFaction(event:EntityQEvent):void {
			var entity:ComplexEntity = event.complexEntity;
			var icon:Bitmap = entityToMapIcon[entity];
			if (icon != null) {
				if (entity.isEnemy()) {
					adjustEnemyIcon(entity);
				} else {
					icon.bitmapData = otherPlayerBitmapData;
					setIconPositionFromEntityLocation(icon, entity);
				}
				adjustAllEnemyIconsForVisibility();
			}
		}
		
		public function scrollRoomSpriteToMatchRealRoom(event:QEvent):void {
			roomSprite.x = Math.floor(combat.room.x / SCALE);
			roomSprite.y = Math.floor(combat.room.y / SCALE);
		}
		
		/*
		public function mouseDownListener(event:MouseEvent):void {
			addEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			startDrag();
		}
		
		public function mouseUpListener(event:MouseEvent):void {
			removeEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			stopDrag();
		}
		*/
		
	}

}