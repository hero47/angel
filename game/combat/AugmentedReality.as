package angel.game.combat {
	import angel.common.Assert;
	import angel.common.Floor;
	import angel.common.Prop;
	import angel.game.ComplexEntity;
	import angel.game.event.EntityQEvent;
	import angel.game.Icon;
	import angel.game.Room;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class AugmentedReality {
		
		// Colors for movement dots/hilights
		private static const ENEMY_FOOTPRINT_COLOR:uint = 0xff0000;
		private static const PLAYER_FOOTPRINT_COLOR:uint = 0x0000ff;
		private static const FRIEND_FOOTPRINT_COLOR:uint = 0xffff00;
		private static const CIVILIAN_FOOTPRINT_COLOR:uint = 0xc0c0c0;
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
		
		private var lastActivePlayer:ComplexEntity;
		
		private var minimap:Minimap;
		public var statDisplay:CombatStatDisplay;
		
		public function AugmentedReality(combat:RoomCombat) {
			this.combat = combat;
			this.room = combat.room;
			lastActivePlayer = room.mainPlayerCharacter;
			
			drawCombatGrid(room.decorationsLayer.graphics);
			
			statDisplay = new CombatStatDisplay();
			room.stage.addChild(statDisplay);
			
			initialiseAllFighterDisplayElements();
			createMinimap(); //CAUTION: create after enemy visibilities are adjusted, or it will show everyone as visible
			
			Settings.gameEventQueue.addListener(this, room, EntityQEvent.LOCATION_CHANGED_IN_MOVE, someoneWalkedToNewSquare);
			Settings.gameEventQueue.addListener(this, room, EntityQEvent.LOCATION_CHANGED_DIRECTLY, someoneMovedToNewSquare);
			Settings.gameEventQueue.addListener(this, room, EntityQEvent.CHANGED_SOLIDNESS, someoneForcesVisibilityRecalc);
			Settings.gameEventQueue.addListener(this, room, EntityQEvent.HEALTH_CHANGE, someonesHealthChanged);
			Settings.gameEventQueue.addListener(this, room, EntityQEvent.START_TURN, someoneStartedTurn);
			Settings.gameEventQueue.addListener(this, room, EntityQEvent.CHANGED_FACTION, someoneChangedFaction);
		}
		
		public function cleanup():void {
			Settings.gameEventQueue.removeAllListenersOwnedBy(this);
			
			room.decorationsLayer.graphics.clear(); // remove grid outlines
			room.stage.removeChild(statDisplay);						
			removeAllFighterDisplayElements();
			minimap.cleanup();
			cleanupFog();
		}
		
		public function addFighter(entity:ComplexEntity):void {
			initializeDisplayElementsForFighter(entity);
			adjustVisibilityForEachTile();
		}
		
		public function removeFighter(entity:ComplexEntity):void {
			adjustVisibilityForEachTile();
			removeDisplayElementsForFighter(entity);
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
		private function someoneWalkedToNewSquare(event:EntityQEvent):void {
			Assert.assertTrue(event.complexEntity == combat.currentFighter(), "Wrong entity moving");
			combat.mover.adjustDisplayAsEntityLeavesATile(); //CONSIDER: should mover listen and do this for itself?
			adjustVisibilityForMove(event.complexEntity);
		}
		
		// Called by event listener each time an entity is moved directly (i.e. by a script action) rather than walking
		// (entity's location will have already changed)
		private function someoneMovedToNewSquare(event:EntityQEvent):void {
			adjustVisibilityForMove(event.simpleEntity);
		}
		private function someoneForcesVisibilityRecalc(event:EntityQEvent):void {
			adjustVisibilityForEachTile();
		}
		
		private function adjustVisibilityForMove(entity:SimpleEntity):void {
			//NOTE: need to adjust all even when an enemy or prop moves, since it might have been
			//blocking line of sight to another enemy!
			adjustEntityVisibility(entity, combat.visibilityForLocation(entity.location, lastActivePlayer));
			adjustVisibilityForEachTile();
		}
		
		//UNDONE: upgrade stat display to track its own entity and do its own listening
		private function someonesHealthChanged(event:EntityQEvent):void {
			var entity:ComplexEntity = event.complexEntity;
			//Current stat display is an ugly grab-bag of misc. bits with no coherence
			if (entity.isPlayerControlled && (entity == combat.currentFighter())) {
				statDisplay.adjustCombatStatDisplay(entity);
			}
		}
		
		private function someoneStartedTurn(event:EntityQEvent):void {
			var fighter:ComplexEntity = event.complexEntity;
			if (fighter.isPlayerControlled) {
				if (fighter.targetable) {
					statDisplay.adjustCombatStatDisplay(fighter);
					lastActivePlayer = fighter;
				}
				adjustVisibilityForEachTile();
			} else {
				statDisplay.adjustCombatStatDisplay(null);
				++lastSeenMarkers[fighter].age;
				updateLastSeenLocation(fighter); // so last seen marker will fade even if entity doesn't move
			}
		}
		
		private function someoneChangedFaction(event:EntityQEvent):void {
			var entity:ComplexEntity = event.complexEntity;
			var lastSeenMarker:LastSeen = lastSeenMarkers[entity];
			var lastSeenAge:int = (lastSeenMarker == null ? 0 : lastSeenMarker.age);
			removeDisplayElementsForFighter(entity);
			initializeDisplayElementsForFighter(entity);
			if (!entity.isPlayerControlled) {
				lastSeenMarkers[entity].age = lastSeenAge;
			}
		}
		
		//Note: assumes that the contents of each tile have the same visibility as the tile itself.
		//When something moves, need to call adjustEntityVisibility on it individually in addition to this.
		public function adjustVisibilityForEachTile():void {
			var roomSize:Point = room.floor.size;
			for (var x:int = 0; x < roomSize.x; ++x) {
				for (var y:int = 0; y < roomSize.y; ++y) {
					var location:Point = new Point(x, y);
					var tileVisibility:int = combat.visibilityForLocation(location, lastActivePlayer);
					var oldTileVisibility:int = room.floor.hideOrShow(x, y, tileVisibility);
					if (tileVisibility != oldTileVisibility) {
						//room.hideOrShowContents(x, y, visible);
						room.forEachEntityIn(location, function(entity:SimpleEntity):void {
							adjustEntityVisibility(entity, tileVisibility);
						});
					}
				}
			}
		}
		
		private function adjustEntityVisibility(entity:SimpleEntity, desiredVisibility:int):void {
			var char:ComplexEntity = entity as ComplexEntity;
			if ((char != null) && (char.isActive())) {
				if (char.isPlayerControlled) {
					return;
				}
				var wasVisible:Boolean = char.visible;
				char.visible = (desiredVisibility == Floor.UNSEEN ? false : true);
				trace(entity.aaId, "wasVisible", wasVisible, "desiredVisibility", desiredVisibility, "set visible to", entity.visible);
				updateLastSeenLocation(char);
				if (!wasVisible && char.visible) {
					Settings.gameEventQueue.dispatch(new EntityQEvent(char, EntityQEvent.BECAME_VISIBLE));
				}
			}
			entity.transform.colorTransform = Floor.colorTransformFor(desiredVisibility);
		}
		
		private function initialiseAllFighterDisplayElements():void {
			for each (var fighter:ComplexEntity in combat.fighters) {
				initializeDisplayElementsForFighter(fighter);
			}
			adjustVisibilityForEachTile();
		}
		
		private function factionColor(entity:ComplexEntity):uint {
			switch (entity.faction) {
				case ComplexEntity.FACTION_ENEMY:
				case ComplexEntity.FACTION_ENEMY2:
					return ENEMY_FOOTPRINT_COLOR;
				break;
				case ComplexEntity.FACTION_FRIEND:
					return (entity.isReallyPlayer ? PLAYER_FOOTPRINT_COLOR : FRIEND_FOOTPRINT_COLOR);
				break;
				default:
					return CIVILIAN_FOOTPRINT_COLOR;
				break;
			}
		}
		
		private function initializeDisplayElementsForFighter(entity:ComplexEntity):void {
			if (!entity.controllingOwnText) {
				entity.setTextOverHead(String(entity.currentHealth));
			}
			var factionColor:uint = factionColor(entity);
			createCombatFootprintForEntity(entity, factionColor);
			if (!entity.isPlayerControlled) {
				var visibleOnInit:Boolean = combat.anyPlayerCanSeeLocation(entity.location);
				createLastSeenMarker(entity, factionColor, visibleOnInit);
			}		
		}
		
		private function removeAllFighterDisplayElements():void {
			for each (var fighter:ComplexEntity in combat.fighters) {
				removeDisplayElementsForFighter(fighter);
			}			
		}
		
		private function removeDisplayElementsForFighter(entity:ComplexEntity):void {
			if (!entity.controllingOwnText) {
				entity.setTextOverHead(null);
			}
			entity.visible = true;
			entity.removeFootprint();
			deleteLastSeenLocation(entity);
		}
		
		private function createLastSeenMarker(entity:ComplexEntity, color:uint, visibleOnInit:Boolean):void {
			// I think this should be visible for out-of-sight enemies when first entering combat from explore,
			// but Wm disagrees.  To change that, just remove the line setting age to LAST_SEEN_MARKER_TURNS.
			var lastSeen:LastSeen = new LastSeen(color);
			room.decorationsLayer.addChild(lastSeen);
			lastSeenMarkers[entity] = lastSeen;
			updateLastSeenLocation(entity);
			if (!visibleOnInit) {
				lastSeen.age = LAST_SEEN_MARKER_TURNS;
			}
		}
		
		private function updateLastSeenLocation(entity:ComplexEntity):void {
			var lastSeen:LastSeen = lastSeenMarkers[entity];
			if (lastSeen == null) {
				return;
			}
			var loc:Point = Floor.tileBoxCornerOf(entity.location);
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
		
		private function createCombatFootprintForEntity(entity:ComplexEntity, color:uint):void {
			var footprint:Shape = new Shape();
			footprint.graphics.lineStyle(4, color, 0.7);
			footprint.graphics.drawCircle(0, 0, 15);
			footprint.graphics.drawCircle(0, 0, 30);
			footprint.graphics.drawCircle(0, 0, 45);
			// TAG tile-width-is-twice-height: aspect will be off if tiles no longer follow this rule!
			footprint.scaleY = 0.5;
			
			entity.attachFootprint(footprint);
		}
		
		private function cleanupFog():void {
			var roomSize:Point = room.floor.size;
			for (var x:int = 0; x < roomSize.x; ++x) {
				for (var y:int = 0; y < roomSize.y; ++y) {
					room.floor.hideOrShow(x, y, Floor.SEEN);
					room.forEachEntityIn(new Point(x,y), function(entity:SimpleEntity):void {
						adjustEntityVisibility(entity, Floor.SEEN);
					});
				}
			}
		}
		
		public function tileIsVisible(location:Point):Boolean {
			return (room.floor.visibility(location.x, location.y) != Floor.UNSEEN);
		}

	} // end class AugmentedReality

}

import angel.common.Tileset;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.Shape;

internal class LastSeen extends Shape {
	public var age:int;
	public function LastSeen(color:uint, age:int = 0) {
		this.age = age;
		
		var w:int = Tileset.TILE_WIDTH / 3;
		var h:int = Tileset.TILE_HEIGHT / 3;
		graphics.lineStyle(6, 0x0, 1);
		drawIt(graphics, w, h);
		graphics.lineStyle(3, color, 1);
		drawIt(graphics, w, h);
	}
	private function drawIt(graphics:Graphics, w:int, h:int):void {
		graphics.moveTo(w, h);
		graphics.lineTo(Tileset.TILE_WIDTH - w, Tileset.TILE_HEIGHT - h);
		graphics.moveTo(w, Tileset.TILE_HEIGHT - h);
		graphics.lineTo(Tileset.TILE_WIDTH - w, h);
	}
}
