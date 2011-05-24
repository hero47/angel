package angel.game.combat {
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.game.ComplexEntity;
	import angel.game.EntityEvent;
	import angel.game.Room;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class AugmentedReality {
		
		// Colors for movement dots/hilights
		private static const ENEMY_MARKER_COLOR:uint = 0xff0000;
		private static const PLAYER_MARKER_COLOR:uint = 0x0000ff;
		private static const GRID_COLOR:uint = 0xff0000;
		
		private var combat:RoomCombat;
		// Meowse query: Extricated from combat for convenient referencing, but isn't every use
		// just as much a violation of the Law of Demeter as if I said combat.room.foo ?
		private var room:Room;
		
		// We will keep one of these markers for every enemy at all times, and make it visible when the enemy
		// goes out of sight.  That seems cleaner than tracking 'previous position' of the moving enemy and creating
		// and deleting markers, though probably a bit less efficient.
		private var lastSeenMarkers:Dictionary = new Dictionary(); // map from entity to LastSeen
		private static const LAST_SEEN_MARKER_TURNS:int = 4; // markers remain visible this long after sighting
		
		private var minimap:Minimap;
		public var statDisplay:CombatStatDisplay;
		
		public function AugmentedReality(combat:RoomCombat) {
			this.combat = combat;
			this.room = combat.room;
			
			drawCombatGrid(room.decorationsLayer.graphics);
			
			statDisplay = new CombatStatDisplay();
			room.stage.addChild(statDisplay);
			
			initialiseAllFighterDisplayElements();
			createMinimap(); //CAUTION: create after enemy visibilities are adjusted, or it will show everyone as visible
			
			room.addEventListener(EntityEvent.MOVED, someoneMovedToNewSquare, false, 100);
			room.addEventListener(EntityEvent.HEALTH_CHANGE, someonesHealthChanged);
			room.addEventListener(EntityEvent.START_TURN, someoneStartedTurn);
			
		}
		
		public function cleanup():void {
			room.removeEventListener(EntityEvent.MOVED, someoneMovedToNewSquare);
			room.removeEventListener(EntityEvent.HEALTH_CHANGE, someonesHealthChanged);
			room.removeEventListener(EntityEvent.START_TURN, someoneStartedTurn);
			
			room.decorationsLayer.graphics.clear(); // remove grid outlines
			room.stage.removeChild(statDisplay);						
			removeAllFighterDisplayElements();
			minimap.cleanup();
		}
		
		public function addFighter(entity:ComplexEntity):void {
			initializeDisplayElementsForFighter(entity);
			if (entity.isPlayerControlled) {
				adjustAllEnemyVisibility();
			}
		}
		
		public function removeFighter(entity:ComplexEntity):void {
			removeDisplayElementsForFighter(entity);
			if (entity.isPlayerControlled) {
				adjustAllEnemyVisibility();
			}
		}
		
		public function toggleMinimap():void {
			minimap.visible = !minimap.visible;
		}
		
		
		//NOTE: grid lines are tweaked up by one pixel because the tile image bitmaps actually extend one pixel outside the
		//tile boundaries, overlapping the previous row.
		private function drawCombatGrid(graphics:Graphics):void {
			graphics.lineStyle(0, GRID_COLOR, 1);
			var startPoint:Point = Floor.topCornerOf(new Point(0, 0));
			var endPoint:Point = Floor.topCornerOf(new Point(0, room.size.y));
			for (var i:int = 0; i <= room.size.x; i++) {
				graphics.moveTo(startPoint.x + (i * Floor.FLOOR_TILE_X), startPoint.y + (i * Floor.FLOOR_TILE_Y) - 1);
				graphics.lineTo(endPoint.x + (i * Floor.FLOOR_TILE_X), endPoint.y + (i * Floor.FLOOR_TILE_Y) - 1);
			}
			endPoint = Floor.topCornerOf(new Point(room.size.x, 0));
			for (i = 0; i <= room.size.y; i++) {
				graphics.moveTo(startPoint.x - (i * Floor.FLOOR_TILE_X), startPoint.y + (i * Floor.FLOOR_TILE_Y) - 1);
				graphics.lineTo(endPoint.x - (i * Floor.FLOOR_TILE_X), endPoint.y + (i * Floor.FLOOR_TILE_Y) - 1);
			}
		}
		
		private function createMinimap():void {
			//CAUTION: create after enemy visibilities are adjusted, or it will show everyone as visible
			minimap = new Minimap(combat); 
			minimap.x = room.stage.stageWidth - minimap.width - 5;
			minimap.y = room.stage.stageHeight - minimap.height - 5;
			room.stage.addChild(minimap);
		}
		
		// Called by event listener each time an entity begins moving to a new square during combat.
		// (entity's location will have already changed)
		private function someoneMovedToNewSquare(event:EntityEvent):void {
			Assert.assertTrue(event.entity == combat.currentFighter(), "Wrong entity moving");
			
			var entity:ComplexEntity = (event.entity as ComplexEntity);
			combat.mover.adjustDisplayAsEntityLeavesATile(); //CONSIDER: should mover listen and do this for itself?
			if (entity.isPlayerControlled) {
				adjustAllEnemyVisibility();
			} else {
				adjustVisibilityOfEnemy(entity);
			}
		}
		
		//UNDONE: upgrade stat display to track its own entity and do its own listening
		private function someonesHealthChanged(event:EntityEvent):void {
			var entity:ComplexEntity = ComplexEntity(event.entity);
			//Current stat display is an ugly grab-bag of misc. bits with no coherence
			if (entity.isPlayerControlled && (entity == combat.currentFighter())) {
				statDisplay.adjustCombatStatDisplay(entity);
			}
		}
		
		public function someoneStartedTurn(event:EntityEvent):void {
			var fighter:ComplexEntity = ComplexEntity(event.entity);
			if (fighter.isPlayerControlled) {
				statDisplay.adjustCombatStatDisplay(fighter);
				
			} else {
				statDisplay.adjustCombatStatDisplay(null);
				++lastSeenMarkers[fighter].age;
			}
		}
		
		public function adjustAllEnemyVisibility():void {
			for each (var fighter:ComplexEntity in combat.fighters) {
				if (!fighter.isPlayerControlled) {
					adjustVisibilityOfEnemy(fighter);
				}
			}
		}
		
		private function adjustVisibilityOfEnemy(enemy:ComplexEntity):void {
			var wasVisible:Boolean = enemy.visible;
			enemy.visible = enemy.marker.visible = combat.anyPlayerCanSeeLocation(enemy.location);
			updateLastSeenLocation(enemy);
			if (!wasVisible && enemy.visible) {
				enemy.dispatchEvent(new EntityEvent(EntityEvent.BECAME_VISIBLE, true, false, enemy));
			}
		}
		
		private function initialiseAllFighterDisplayElements():void {
			for each (var fighter:ComplexEntity in combat.fighters) {
				initializeDisplayElementsForFighter(fighter);
			}			
		}
		
		private function initializeDisplayElementsForFighter(entity:ComplexEntity):void {
			entity.setTextOverHead(String(entity.currentHealth));
			if (entity.isPlayerControlled) {
				createCombatMarkerForEntity(entity, PLAYER_MARKER_COLOR);
			} else {
				createCombatMarkerForEntity(entity, ENEMY_MARKER_COLOR);
				createLastSeenMarker(entity);
				adjustVisibilityOfEnemy(entity);
			}			
		}
		
		private function removeAllFighterDisplayElements():void {
			for each (var fighter:ComplexEntity in combat.fighters) {
				removeDisplayElementsForFighter(fighter);
			}			
		}
		
		private function removeDisplayElementsForFighter(entity:ComplexEntity):void {
			entity.setTextOverHead(null);
			entity.visible = true;
			entity.removeMarker();
			deleteLastSeenLocation(entity);
		}
		
		private function createLastSeenMarker(entity:ComplexEntity):void {
			// I think this should be visible for out-of-sight enemies when first entering combat from explore,
			// but Wm disagrees.  To change that, just remove the line setting age to LAST_SEEN_MARKER_TURNS.
			var lastSeen:LastSeen = new LastSeen();
			room.decorationsLayer.addChild(lastSeen);
			lastSeenMarkers[entity] = lastSeen;
			updateLastSeenLocation(entity);
			lastSeen.age = LAST_SEEN_MARKER_TURNS;
		}
		
		private function updateLastSeenLocation(entity:ComplexEntity):void {
			var loc:Point = Floor.tileBoxCornerOf(entity.location);
			var lastSeen:LastSeen = lastSeenMarkers[entity];
			if (entity.visible) {
				lastSeen.visible = false;
				lastSeen.age = 0;
				lastSeen.x = loc.x;
				lastSeen.y = loc.y;
			} else {
				lastSeen.visible = (lastSeen.age < LAST_SEEN_MARKER_TURNS);
				if (lastSeen.visible) {
					lastSeen.alpha = 1 - (lastSeen.age / LAST_SEEN_MARKER_TURNS);
				}
			}
		}
		
		// Rather than just making it invisible, remove the marker entirely (for an entity who leaves combat)
		private function deleteLastSeenLocation(entity:ComplexEntity):void {
			var lastSeen:LastSeen = lastSeenMarkers[entity];
			if (lastSeen != null) {
				delete lastSeenMarkers[entity];
				room.decorationsLayer.removeChild(lastSeen);
			}
		}
		
		private function createCombatMarkerForEntity(entity:ComplexEntity, color:uint):void {
			var combatMarker:Shape = new Shape();
			combatMarker.graphics.lineStyle(4, color, 0.7);
			combatMarker.graphics.drawCircle(0, 0, 15);
			combatMarker.graphics.drawCircle(0, 0, 30);
			combatMarker.graphics.drawCircle(0, 0, 45);
			// TAG tile-width-is-twice-height: aspect will be off if tiles no longer follow this rule!
			combatMarker.scaleY = 0.5;
			
			entity.attachMarker(combatMarker);
		}

	} // end class AugmentedReality

}

import angel.common.Tileset;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Shape;

class LastSeen extends Shape {
	public var age:int;
	public function LastSeen(age:int = 0) {
		this.age = age;
		
		var w:int = Tileset.TILE_WIDTH / 3;
		var h:int = Tileset.TILE_HEIGHT / 3;
		graphics.lineStyle(6, 0x0, 1);
		drawIt(graphics, w, h);
		graphics.lineStyle(3, 0xffffff, 1);
		drawIt(graphics, w, h);
	}
	private function drawIt(graphics:Graphics, w:int, h:int):void {
		graphics.moveTo(w, h);
		graphics.lineTo(Tileset.TILE_WIDTH - w, Tileset.TILE_HEIGHT - h);
		graphics.moveTo(w, Tileset.TILE_HEIGHT - h);
		graphics.lineTo(Tileset.TILE_WIDTH - w, h);
	}
}
