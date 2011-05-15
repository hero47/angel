package angel.game.combat {
	import angel.common.Prop;
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.Icon;
	import angel.game.IRoomUi;
	import angel.game.PieSlice;
	import angel.common.FloorTile;
	import angel.game.Room;
	import angel.game.RoomExplore;
	import angel.game.Settings;
	import angel.game.SimpleEntity;
	import angel.game.Walker;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatFireUi implements IRoomUi {
		private var room:Room;
		private var combat:RoomCombat;
		private var player:ComplexEntity;
		private var oldMarkerColorTransform:ColorTransform;
		private var aimCursor:Sprite;
		private var aimCursorBitmap:Bitmap;
		
		private var enemyHealthDisplay:TextField;
		private static const ENEMY_HEALTH_PREFIX:String = "Enemy: ";
		
		private var targetEnemy:ComplexEntity;
		private var targetLocked:Boolean = false;
		
		// Wm wants pressing space to alternate between centering on player and centering on target enemy
		private var spaceLastCenteredOnPlayer:Boolean = false;
		
		private static const LOS_BLOCKED_TILE_HILIGHT_COLOR:uint = 0x000000;
		private static const NO_TARGET_TILE_HILIGHT_COLOR:uint = 0xffffff;
		private static const TARGET_TILE_HILIGHT_COLOR:uint = 0xff0000;
		private static const TARGET_HILIGHT_COLOR:uint = 0xff0000;
		
		public function CombatFireUi(room:Room, combat:RoomCombat) {
			this.combat = combat;
			this.room = room;
			aimCursorBitmap = new Bitmap(Icon.bitmapData(Icon.CombatCursorActive));
			aimCursorBitmap.x = -aimCursorBitmap.width / 2;
			aimCursorBitmap.y = -aimCursorBitmap.height / 2;
			aimCursor = new Sprite();
			aimCursor.mouseEnabled = false;
			aimCursor.addChild(aimCursorBitmap);
			createEnemyHealthDisplay();
		}
		
		/* INTERFACE angel.game.IRoomUi */
		
		public function enable(player:ComplexEntity):void {
			trace("entering player fire phase for", player.aaId);
			this.player = player;
			oldMarkerColorTransform = player.marker.transform.colorTransform;
			player.marker.transform.colorTransform = new ColorTransform(0, 0, 0, 1, 0, 255, 0, 0);
			targetEnemy = null;
			targetLocked = false;
			adjustAimCursorImage();
			Mouse.hide();
			room.addChild(aimCursor);
			aimCursor.x = room.mouseX;
			aimCursor.y = room.mouseY;
		}
		
		public function disable():void {
			trace("ending player fire phase for", player.aaId);
			player.marker.transform.colorTransform = oldMarkerColorTransform;
			this.player = null;
			room.moveHilight(null, 0);
			moveTargetHilight(null);
			if (aimCursor.parent != null) {
				room.removeChild(aimCursor);
			}
			Mouse.show();
		}
		
		public function get currentPlayer():ComplexEntity {
			return player;
		}
		
		public function keyDown(keyCode:uint):void {
			switch (keyCode) {
				case Util.KEYBOARD_C:
					room.changeModeTo(RoomExplore);
				break;
				
				case Util.KEYBOARD_M:
					combat.augmentedReality.toggleMinimap();
				break;
				
				case Keyboard.BACKSPACE:
					doCancelTarget();
				break;
				
				case Keyboard.ENTER:
					if (targetLocked) {
						doPlayerFire();
					} else {
						doReserveFire();
					}
				break;
				
				case Keyboard.SPACE:
					if (spaceLastCenteredOnPlayer && targetEnemy != null) {
						room.snapToCenter(targetEnemy.location);
						spaceLastCenteredOnPlayer = false;
					} else {
						room.snapToCenter(player.location);
						spaceLastCenteredOnPlayer = true;
					}
				break;
			}
		}
		
		public function mouseMove(tile:FloorTile):void {
			if (tile != null) {
				var lineOfSight:Boolean = Util.entityHasLineOfSight(player, tile.location);
				if (!lineOfSight) {
					room.moveHilight(tile, LOS_BLOCKED_TILE_HILIGHT_COLOR);
					if (!targetLocked) {
						moveTargetHilight(null);
					}
				} else if (targetLocked) {
					//NOTE: we'll probably add some behavior here once Wm tries this
					room.moveHilight(tile, NO_TARGET_TILE_HILIGHT_COLOR);
				} else {
					var enemy:ComplexEntity = room.firstComplexEntityIn(tile.location, filterIsEnemy);
					room.moveHilight(tile, (enemy == null ? NO_TARGET_TILE_HILIGHT_COLOR : TARGET_TILE_HILIGHT_COLOR));
					moveTargetHilight(enemy);
				}
			}
			aimCursor.x = room.mouseX;
			aimCursor.y = room.mouseY;
		}
		
		public function mouseClick(tile:FloorTile):void {
			if (!targetLocked) {
				if (targetEnemy != null) {
					targetLocked = true;
					adjustAimCursorImage();
				}
			} else {
				if (tile != null && tile.location.equals(targetEnemy.location)) {
					doPlayerFire();
				}
			}
		}
		
		public function pieMenuForTile(tile:FloorTile):Vector.<PieSlice> {
			var slices:Vector.<PieSlice> = new Vector.<PieSlice>()
			if (targetLocked) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.CombatFire), doPlayerFire));
				addGrenadePieSliceIfLegal(slices, tile.location);
				slices.push(new PieSlice(Icon.bitmapData(Icon.CombatCancelTarget), doCancelTarget));
			} else {
				slices.push(new PieSlice(Icon.bitmapData(Icon.CombatNoTarget), null));
				addGrenadePieSliceIfLegal(slices, tile.location);
			}
			slices.push(new PieSlice(Icon.bitmapData(Icon.CombatReserveFire), doReserveFire));
			return slices;
		}
	
		
		/************ Private ****************/
		
		private function addGrenadePieSliceIfLegal(slices:Vector.<PieSlice>, targetLocation:Point):void {
			if (!room.blocksGrenade(targetLocation.x, targetLocation.y) &&
						player.inventory.findA(Grenade) != null &&
						Util.entityHasLineOfSight(player, targetLocation)) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.CombatGrenade), function():void {
					doPlayerThrowGrenadeAt(targetLocation);
				}));
			}
		}
		
		private function adjustAimCursorImage():void {
			aimCursorBitmap.bitmapData = Icon.bitmapData(targetLocked ? Icon.CombatCursorInactive : Icon.CombatCursorActive);
		}
		
		private function constructPieMenu():Vector.<PieSlice> {
			var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
			return slices;
		}
		
		private function doPlayerFire():void {
			var target:ComplexEntity = targetEnemy;
			var playerFiring:ComplexEntity = player;
			room.disableUi();
			combat.fireAndAdvanceToNextPhase(playerFiring, target);
		}
		
		private function doPlayerThrowGrenadeAt(loc:Point):void {
			var playerFiring:ComplexEntity = player;
			room.disableUi();
			combat.throwGrenadeAndAdvanceToNextPhase(playerFiring, loc);
		}
		
		private function doReserveFire():void {
			var playerFiring:ComplexEntity = player;
			room.disableUi();
			combat.fireAndAdvanceToNextPhase(playerFiring, null);
		}
		
		private function doCancelTarget():void {
			targetLocked = false;
			moveTargetHilight(null);
			adjustAimCursorImage();
		}
		
		private function filterIsEnemy(entity:ComplexEntity):Boolean {
			return (entity.isEnemy() || Settings.controlEnemies);
		}
		
		private function moveTargetHilight(target:ComplexEntity):void {
			if (targetEnemy != null) {
				targetEnemy.filters = [];
			}
			targetEnemy = target;
			if (targetEnemy != null) {
				var glow:GlowFilter = new GlowFilter(TARGET_HILIGHT_COLOR, 1, 20, 20, 2, 1, false, false);
				targetEnemy.filters = [ glow ];
			}
			displayEnemyHealthFor(targetEnemy);
		}
		
		private function createEnemyHealthDisplay():void {
			enemyHealthDisplay = CombatStatDisplay.createHealthTextField();
			enemyHealthDisplay.x = room.stage.stageWidth - enemyHealthDisplay.width - 10;
			enemyHealthDisplay.y = 10;
			displayEnemyHealthFor(null);
			room.stage.addChild(enemyHealthDisplay);
		}
		
		private function displayEnemyHealthFor(enemy:ComplexEntity):void {
			if (enemy == null) {
				enemyHealthDisplay.visible = false;
			} else {
				enemyHealthDisplay.text = ENEMY_HEALTH_PREFIX + String(enemy.currentHealth);
				enemyHealthDisplay.visible = true;
			}	
		}
	
	} // end class CombatFireUi

}