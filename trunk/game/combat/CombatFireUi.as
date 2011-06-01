package angel.game.combat {
	import angel.common.FloorTile;
	import angel.common.Util;
	import angel.game.brain.CombatBrainUiMeldPlayer;
	import angel.game.ComplexEntity;
	import angel.game.Icon;
	import angel.game.IRoomUi;
	import angel.game.PieSlice;
	import angel.game.Room;
	import angel.game.RoomExplore;
	import angel.game.Settings;
	import angel.game.ToolTip;
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
		private var haveGun:Boolean;
		private var oldMarkerColorTransform:ColorTransform;
		private var aimCursor:Sprite;
		private var aimCursorBitmap:Bitmap;
		
		private var hilightedEnemy:ComplexEntity;
		
		private var clickThisEnemyAgainForQuickFire:ComplexEntity;
		
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
		
		/* INTERFACE angel.game.IRoomUi */
		
		public function enable(player:ComplexEntity):void {
			trace("entering player fire phase for", player.aaId);
			this.player = player;
			haveGun = (player.currentGun() != null);
			oldMarkerColorTransform = player.marker.transform.colorTransform;
			player.marker.transform.colorTransform = new ColorTransform(0, 0, 0, 1, 0, 255, 0, 0);
			clickThisEnemyAgainForQuickFire = null;
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
				
				case Keyboard.ENTER:
					if (clickThisEnemyAgainForQuickFire != null) {
						doPlayerFireGunAt(clickThisEnemyAgainForQuickFire);
					} else {
						doReserveFire();
					}
				break;
				
				case Keyboard.SPACE:
					room.snapToCenter(player.location);
				break;
			}
		}
		
		public function mouseMove(tile:FloorTile):void {
			if (tile != null) {
				var lineOfSight:Boolean = Util.entityHasLineOfSight(player, tile.location);
				if (!lineOfSight) {
					room.moveHilight(tile, LOS_BLOCKED_TILE_HILIGHT_COLOR);
					moveTargetHilight(null);
					ToolTip.removeToolTip();
				} else {
					var enemy:ComplexEntity = room.firstComplexEntityIn(tile.location, filterIsEnemy);
					room.moveHilight(tile, (enemy == null ? NO_TARGET_TILE_HILIGHT_COLOR : TARGET_TILE_HILIGHT_COLOR));
					moveTargetHilight(enemy);
					room.updateToolTip(tile.location);
				}
			}
			aimCursor.x = room.mouseX;
			aimCursor.y = room.mouseY;
		}
		
		public function mouseClick(tile:FloorTile):void {
			if ((clickThisEnemyAgainForQuickFire != null) && (tile.location.equals(clickThisEnemyAgainForQuickFire.location))) {
				doPlayerFireGunAt(clickThisEnemyAgainForQuickFire);
			} else if (haveGun && Util.entityHasLineOfSight(player, tile.location)) {
				clickThisEnemyAgainForQuickFire = room.firstComplexEntityIn(tile.location, filterIsEnemy);
			} else {
				clickThisEnemyAgainForQuickFire = null;
			}
		}
		
		public function pieMenuForTile(tile:FloorTile):Vector.<PieSlice> {
			var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
			var lineOfSight:Boolean = Util.entityHasLineOfSight(player, tile.location);
			
			slices.push(new PieSlice(Icon.bitmapData(Icon.CombatPass), "Pass/Reserve Fire", doReserveFire));
			addGrenadePieSliceIfLegal(slices, tile.location);
			if (haveGun && (hilightedEnemy != null)) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.CombatFireFirstGun), "Fire", function():void {
					doPlayerFireGunAt(hilightedEnemy);
				} ));
			}
			
			return slices;
		}
	
		
		/************ Private ****************/
		
		private function addGrenadePieSliceIfLegal(slices:Vector.<PieSlice>, targetLocation:Point):void {
			var grenades:int = player.inventory.count(Grenade);
			if ( (grenades > 0) &&
						!room.blocksGrenade(targetLocation.x, targetLocation.y) &&
						Util.entityHasLineOfSight(player, targetLocation)) {
				slices.push(new PieSlice(Icon.bitmapData(Icon.CombatGrenade),
					"Throw grenade (" + grenades + " in inventory) at this square",
					function():void { doPlayerThrowGrenadeAt(targetLocation); }
				));
			}
		}
		
		private function constructPieMenu():Vector.<PieSlice> {
			var slices:Vector.<PieSlice> = new Vector.<PieSlice>();
			return slices;
		}
		
		private function doPlayerFireGunAt(target:ComplexEntity):void {
			var playerFiring:ComplexEntity = player;
			room.disableUi();
			CombatBrainUiMeldPlayer(playerFiring.brain).beginFireGunOrReserve(playerFiring, target);
		}
		
		private function doPlayerThrowGrenadeAt(loc:Point):void {
			var playerFiring:ComplexEntity = player;
			room.disableUi();
			CombatBrainUiMeldPlayer(playerFiring.brain).beginThrowGrenade(playerFiring, loc);
		}
		
		private function doReserveFire():void {
			var playerFiring:ComplexEntity = player;
			room.disableUi();
			CombatBrainUiMeldPlayer(playerFiring.brain).beginFireGunOrReserve(playerFiring, null);
		}
		
		private function filterIsEnemy(entity:ComplexEntity):Boolean {
			return (entity.isEnemy() || Settings.controlEnemies);
		}
		
		private function moveTargetHilight(target:ComplexEntity):void {
			if (hilightedEnemy != null) {
				hilightedEnemy.filters = [];
			}
			hilightedEnemy = target;
			if (hilightedEnemy != null) {
				var glow:GlowFilter = new GlowFilter(TARGET_HILIGHT_COLOR, 1, 20, 20, 2, 1, false, false);
				hilightedEnemy.filters = [ glow ];
			}
		}
	
	} // end class CombatFireUi

}