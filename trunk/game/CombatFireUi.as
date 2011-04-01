package angel.game {
	import angel.common.Util;
	import angel.game.PieSlice;
	import angel.common.FloorTile;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CombatFireUi implements IRoomUi {
		private var room:Room;
		private var combat:RoomCombat;
		private var player:Entity;
		private var oldMarkerColorTransform:ColorTransform;
		private var aimCursor:Sprite;
		private var aimCursorBitmap:Bitmap;
		
		private var targetEnemy:Entity;
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
		}
		
		/* INTERFACE angel.game.IUi */
		
		public function enable(player:Entity):void {
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
		
		public function keyDown(keyCode:uint):void {
			switch (keyCode) {
				case Util.KEYBOARD_C:
					room.changeModeTo(RoomExplore);
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
						room.scrollToCenter(targetEnemy.location, true);
						spaceLastCenteredOnPlayer = false;
					} else {
						room.scrollToCenter(player.location, true);
						spaceLastCenteredOnPlayer = true;
					}
				break;
			}
		}
		
		public function mouseMove(tile:FloorTile):void {
			if (tile != null) {
				var lineOfSight:Boolean = combat.lineOfSight(player, tile.location);
				if (!lineOfSight) {
					room.moveHilight(tile, LOS_BLOCKED_TILE_HILIGHT_COLOR);
					if (!targetLocked) {
						moveTargetHilight(null);
					}
				} else if (targetLocked) {
					//NOTE: we'll probably add some behavior here once Wm tries this
					room.moveHilight(tile, NO_TARGET_TILE_HILIGHT_COLOR);
				} else {
					var enemy:Entity = room.firstEntityIn(tile.location, filterIsEnemy);
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
				slices.push(new PieSlice(Icon.bitmapData(Icon.CombatCancelTarget), doCancelTarget));
			} else {
				slices.push(new PieSlice(Icon.bitmapData(Icon.CombatNoTarget), null));
			}
			slices.push(new PieSlice(Icon.bitmapData(Icon.CombatReserveFire), doReserveFire));
			return slices;
		}
	
		
		/************ Private ****************/
		
		private function adjustAimCursorImage():void {
			aimCursorBitmap.bitmapData = Icon.bitmapData(targetLocked ? Icon.CombatCursorInactive : Icon.CombatCursorActive);
		}
		
		private function constructPieMenu():Vector.<PieSlice> {
			var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
			return slices;
		}
		
		private function doPlayerFire():void {
			var target:Entity = targetEnemy;
			var playerFiring:Entity = player;
			room.disableUi();
			combat.fireAndAdvanceToNextPhase(playerFiring, target);
		}
		
		private function doReserveFire():void {
			var playerFiring:Entity = player;
			room.disableUi();
			combat.fireAndAdvanceToNextPhase(playerFiring, null);
		}
		
		private function doCancelTarget():void {
			targetLocked = false;
			moveTargetHilight(null);
			adjustAimCursorImage();
		}
		
		private function filterIsEnemy(entity:Entity):Boolean {
			return entity.isEnemy();
		}
		
		private function moveTargetHilight(target:Entity):void {
			if (targetEnemy != null) {
				targetEnemy.filters = [];
			}
			targetEnemy = target;
			if (targetEnemy != null) {
				var glow:GlowFilter = new GlowFilter(TARGET_HILIGHT_COLOR, 1, 20, 20, 2, 1, false, false);
				targetEnemy.filters = [ glow ];
			}
			combat.adjustEnemyHealthDisplay(targetEnemy == null ? -1 : targetEnemy.currentHealth);
		}
	
	} // end class CombatFireUi

}